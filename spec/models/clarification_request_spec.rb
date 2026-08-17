require "rails_helper"

RSpec.describe ClarificationRequest do
  def member(role, organization:)
    membership = create(:membership, organization: organization)
    create(:membership_role, membership: membership, role: role)
    membership
  end

  def context
    work_order = create(:work_order)
    technician = member("technician", organization: work_order.organization)
    engineer = member("engineer", organization: work_order.organization)
    execution = create(:execution, work_order: work_order, organization: work_order.organization)
    create(:execution_participant, execution: execution, organization: work_order.organization,
                                   membership: technician)
    measurement = create(:measurement, execution: execution, organization: work_order.organization,
                                       recorded_by_membership: technician)
    execution.update_columns(outcome: "completed", outcome_recorded_at: Time.current,
                             outcome_recorded_by_membership_id: technician.id)
    create(:execution_event, execution: execution, organization: work_order.organization,
                             actor_membership: technician, event_type: "submitted")
    review = EngineeringReview.create_for_ready_work_order!(work_order)
    review.start!(actor: engineer.user)
    [ review, execution, measurement, technician, engineer ]
  end

  def request_clarification(review, execution, measurement, technician, engineer)
    described_class.request!(review: review, execution: execution, target: measurement,
      recipient_membership: technician, question: "Confirm load.", actor: engineer.user)
  end

  it "preserves request, one response, Evidence, and reviewer resolution provenance" do
    review, execution, measurement, technician, engineer = context
    clarification = described_class.request!(review: review, execution: execution,
      target: measurement, recipient_membership: technician,
      question: "Was this captured under normal load?", actor: engineer.user)
    evidence = create(:evidence, execution: execution, organization: execution.organization,
                                 uploaded_by_membership: technician)

    clarification.respond!(actor_membership: technician,
                           response: "Yes, after 20 minutes under normal load.",
                           evidence_ids: [ evidence.id ])
    clarification.resolve!(actor: engineer.user)

    expect(clarification).to have_attributes(state: "resolved", requested_by: engineer.user,
                                              responded_by_membership: technician,
                                              resolved_by: engineer.user)
    expect(clarification.evidences).to contain_exactly(evidence)
    expect(review.reload.state).to eq("in_review")
  end

  it "rejects unrelated recipients, cross-visit targets, and duplicate responses" do
    review, execution, measurement, technician, engineer = context
    unrelated = member("technician", organization: execution.organization)
    invalid = build(:clarification_request, engineering_review: review, execution: execution,
                                            target: measurement, requested_by: engineer.user,
                                            recipient_membership: unrelated)
    expect(invalid).not_to be_valid

    other_execution = create(:execution)
    foreign_target = build(:clarification_request, engineering_review: review, execution: execution,
                                                   target: other_execution, requested_by: engineer.user,
                                                   recipient_membership: technician)
    expect(foreign_target).not_to be_valid

    clarification = request_clarification(review, execution, measurement, technician, engineer)
    2.times { clarification.reload.respond!(actor_membership: technician, response: "Confirmed.") }
    expect(clarification.reload).to have_attributes(state: "responded", response: "Confirmed.")
  end
end
