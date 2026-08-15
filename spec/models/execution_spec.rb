require "rails_helper"

RSpec.describe Execution do
  include ActiveSupport::Testing::TimeHelpers

  def technician(organization)
    membership = create(:membership, organization: organization)
    create(:membership_role, membership: membership, role: "technician")
    membership
  end

  def prepared_execution
    work_order = create(:work_order)
    participant = technician(work_order.organization)
    work_order.assign_to!(participant, assigned_by: create(:user))
    execution = described_class.create_for!(work_order: work_order, created_by: work_order.created_by)
    [ execution, participant ]
  end

  def submit_return_visit(execution, participant)
    execution.record_event!("arrived_at_site", actor_membership: participant)
    execution.record_event!("started_asset_work", actor_membership: participant)
    execution.finish_work!(actor_membership: participant, outcome: "return_required",
                           outcome_reason: "material_required")
    execution.record_event!("left_site", actor_membership: participant)
    execution.record_event!("submitted", actor_membership: participant)
  end

  def record_canonical_timeline(execution, participant)
    events = { arrived_at_site: [ 7, 58 ], started_asset_work: [ 9, 47 ],
               paused_asset_work: [ 10, 31 ], resumed_asset_work: [ 11, 16 ] }
    events.each do |event_type, (hour, minute)|
      execution.record_event!(event_type.to_s, actor_membership: participant,
                                             occurred_at: Time.zone.local(2026, 8, 18, hour, minute))
    end
    execution.finish_work!(actor_membership: participant, outcome: "return_required",
                           outcome_reason: "material_required", outcome_note: "CWM65 required",
                           occurred_at: Time.zone.local(2026, 8, 18, 12, 2))
    execution.record_event!("left_site", actor_membership: participant,
                                         occurred_at: Time.zone.local(2026, 8, 18, 12, 17))
    execution.record_event!("submitted", actor_membership: participant,
                                        occurred_at: Time.zone.local(2026, 8, 18, 12, 20))
  end

  it "creates sequential visits under one Work Order and seeds the current assignee" do
    execution, participant = prepared_execution

    expect(execution).to have_attributes(visit_number: 1,
                                         scheduled_start: execution.work_order.scheduled_start)
    expect(execution.participant_memberships).to contain_exactly(participant)
    expect { described_class.create_for!(work_order: execution.work_order, created_by: create(:user)) }
      .to raise_error(ActiveRecord::RecordInvalid)

    travel_to(Time.zone.local(2026, 8, 18, 8)) { submit_return_visit(execution, participant) }

    second = described_class.create_for!(work_order: execution.work_order, created_by: create(:user),
                                         scheduled_start: 2.days.from_now)
    expect(second.visit_number).to eq(2)
  end

  it "derives the canonical timeline durations across pause and resume" do
    execution, participant = prepared_execution
    record_canonical_timeline(execution, participant)

    expect(execution.site_presence_duration).to eq(4.hours + 19.minutes)
    expect(execution.pre_work_wait_duration).to eq(1.hour + 49.minutes)
    expect(execution.paused_duration).to eq(45.minutes)
    expect(execution.effective_work_duration).to eq(1.hour + 30.minutes)
    expect(execution.post_work_onsite_duration).to eq(15.minutes)
    expect(execution.current_state).to eq("submitted")
  end

  it "sums repeated pause cycles and ignores incomplete intervals" do
    execution, participant = prepared_execution
    base = Time.zone.local(2026, 8, 18, 8)
    %w[arrived_at_site started_asset_work paused_asset_work resumed_asset_work paused_asset_work resumed_asset_work]
      .each_with_index do |event_type, index|
        execution.record_event!(event_type, actor_membership: participant,
                                            occurred_at: base + (index * 10).minutes)
      end

    expect(execution.paused_duration).to eq(20.minutes)
    expect(execution.effective_work_duration).to eq(20.minutes)
    expect(execution.site_presence_duration).to be_nil
  end

  it "rejects impossible and duplicate transitions" do
    execution, participant = prepared_execution

    expect { execution.record_event!("resumed_asset_work", actor_membership: participant) }
      .to raise_error(ExecutionEvent::InvalidTransition)
    execution.record_event!("arrived_at_site", actor_membership: participant)
    expect { execution.record_event!("arrived_at_site", actor_membership: participant) }
      .to raise_error(ExecutionEvent::InvalidTransition)
    expect(execution.execution_events.where(event_type: "arrived_at_site").count).to eq(1)
  end

  it "supports unable-to-execute without fabricating asset work" do
    execution, participant = prepared_execution
    execution.record_event!("arrived_at_site", actor_membership: participant)
    execution.mark_unable!(actor_membership: participant, outcome_reason: "access_denied")
    execution.record_event!("left_site", actor_membership: participant)
    execution.record_event!("submitted", actor_membership: participant)

    expect(execution.reload.outcome).to eq("unable_to_execute")
    expect(execution.execution_events.pluck(:event_type))
      .to eq(%w[arrived_at_site left_site submitted])
  end

  it "requires an active participating Technician for field actions" do
    execution, = prepared_execution
    unrelated = technician(execution.organization)
    founder = create(:user, founder: true)

    expect { execution.record_event!("arrived_at_site", actor_membership: unrelated) }
      .to raise_error(ExecutionEvent::IneligibleActor)
    expect(founder.founder?).to be(true)
  end

  it "locks visit data after submission" do
    execution, participant = prepared_execution
    submit_return_visit(execution, participant)

    expect(execution.update(scheduled_start: 1.week.from_now)).to be(false)
    expect { execution.add_participant!(technician(execution.organization), added_by: create(:user)) }
      .to raise_error(ActiveRecord::RecordInvalid)
  end

  it "rejects non-Technician participants and preserves participants who recorded events" do
    execution, participant = prepared_execution
    supervisor = create(:membership, organization: execution.organization)
    create(:membership_role, membership: supervisor, role: "supervisor")
    execution.record_event!("arrived_at_site", actor_membership: participant)

    expect { execution.add_participant!(supervisor, added_by: create(:user)) }
      .to raise_error(ActiveRecord::RecordInvalid)
    expect(execution.execution_participants.find_by(membership: participant).destroy).to be(false)
  end

  it "enforces tenant consistency in PostgreSQL" do
    execution, participant = prepared_execution
    foreign_membership = technician(create(:organization))

    expect {
      ExecutionParticipant.insert!({ organization_id: execution.organization_id,
                                     execution_id: execution.id, membership_id: foreign_membership.id,
                                     added_by_id: create(:user).id, created_at: Time.current, updated_at: Time.current })
    }.to raise_error(ActiveRecord::InvalidForeignKey)
    expect(participant.organization).to eq(execution.organization)
  end
end
