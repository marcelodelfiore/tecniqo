require "rails_helper"

RSpec.describe ClarificationRequestPolicy do
  after { Current.reset }

  def member(role, organization:)
    membership = create(:membership, organization: organization)
    create(:membership_role, membership: membership, role: role)
    membership
  end

  it "allows only the recipient Technician to respond and the responsible Engineer to resolve" do
    review = create(:engineering_review)
    technician = member("technician", organization: review.organization)
    unrelated = member("technician", organization: review.organization)
    engineer = member("engineer", organization: review.organization)
    execution = create(:execution, work_order: review.work_order, organization: review.organization)
    create(:execution_participant, execution: execution, organization: review.organization,
                                   membership: technician)
    review.update!(state: "in_review", reviewer: engineer.user, started_at: Time.current)
    clarification = build(:clarification_request, engineering_review: review, execution: execution,
                                                  target: execution, requested_by: engineer.user,
                                                  recipient_membership: technician)
    Current.organization = review.organization

    expect(described_class.new(technician.user, clarification)).to be_respond
    expect(described_class.new(unrelated.user, clarification)).not_to be_show
    expect(described_class.new(engineer.user, clarification)).not_to be_respond
  end
end
