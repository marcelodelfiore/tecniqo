require "rails_helper"

RSpec.describe EngineeringReview do
  def member(role, organization:)
    membership = create(:membership, organization: organization)
    create(:membership_role, membership: membership, role: role)
    membership
  end

  def submitted_execution(work_order:, technician:, outcome: "completed", visit_number: 1)
    execution = create(:execution, work_order: work_order, organization: work_order.organization,
                                   visit_number: visit_number)
    create(:execution_participant, execution: execution, organization: work_order.organization,
                                   membership: technician)
    execution.update_columns(outcome: outcome, outcome_recorded_at: Time.current,
                             outcome_recorded_by_membership_id: technician.id,
                             outcome_reason: outcome == "return_required" ? "material_required" : nil)
    create(:execution_event, execution: execution, organization: work_order.organization,
                             actor_membership: technician, event_type: "submitted")
    execution
  end

  def request_clarification(review:, execution:, technician:, engineer:)
    ClarificationRequest.request!(review: review, execution: execution, target: execution,
      recipient_membership: technician, question: "Please confirm the load.", actor: engineer.user)
  end

  it "creates one Work Order review containing the complete submitted multi-visit story" do
    work_order = create(:work_order)
    technician = member("technician", organization: work_order.organization)
    first = submitted_execution(work_order: work_order, technician: technician,
                                outcome: "return_required", visit_number: 1)

    expect(described_class.create_for_ready_work_order!(work_order)).to be_nil

    second = submitted_execution(work_order: work_order, technician: technician, visit_number: 2)
    review = described_class.create_for_ready_work_order!(work_order)

    expect(review).to have_attributes(state: "pending", organization: work_order.organization)
    expect(review.executions).to contain_exactly(first, second)
    expect { described_class.create_for_ready_work_order!(work_order) }
      .not_to change(described_class, :count)
  end

  it "claims, blocks approval for unresolved clarification, then approves with provenance" do
    work_order = create(:work_order)
    technician = member("technician", organization: work_order.organization)
    engineer = member("engineer", organization: work_order.organization)
    execution = submitted_execution(work_order: work_order, technician: technician)
    review = described_class.create_for_ready_work_order!(work_order)

    review.start!(actor: engineer.user)
    clarification = request_clarification(review: review, execution: execution,
                                          technician: technician, engineer: engineer)

    expect { review.reload.approve!(actor: engineer.user) }.to raise_error(ActiveRecord::RecordInvalid)
    clarification.respond!(actor_membership: technician, response: "Normal process load for 20 minutes.")
    clarification.resolve!(actor: engineer.user)
    review.reload.approve!(actor: engineer.user)

    expect(review).to have_attributes(state: "approved", reviewer: engineer.user, approved_by: engineer.user)
    expect(review.started_at).to be_present
    expect(review.approved_at).to be_present
  end

  it "rejects non-Engineer reviewers, inconsistent tenants, and duplicate effects" do
    work_order = create(:work_order)
    technician = member("technician", organization: work_order.organization)
    administrator = member("administrator", organization: work_order.organization)
    submitted_execution(work_order: work_order, technician: technician)
    review = described_class.create_for_ready_work_order!(work_order)

    expect { review.start!(actor: administrator.user) }.to raise_error(ActiveRecord::RecordInvalid)
    founder = create(:user, founder: true)
    2.times { review.reload.start!(actor: founder) }
    2.times { review.reload.approve!(actor: founder) }
    expect(review.reload).to have_attributes(state: "approved", approved_by: founder)
    expect { work_order.update!(requested_work: "Silent rewrite") }.to raise_error(ActiveRecord::RecordInvalid)

    foreign_work_order = create(:work_order)
    invalid = build(:engineering_review, organization: work_order.organization,
                                         work_order: foreign_work_order)
    expect(invalid).not_to be_valid
  end
end
