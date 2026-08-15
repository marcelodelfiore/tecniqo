require "rails_helper"

RSpec.describe TechnicalRecordPolicy do
  def member(role, organization:)
    membership = create(:membership, organization: organization)
    create(:membership_role, membership: membership, role: role)
    membership
  end

  it "allows participating Technicians to capture and edit before submission" do
    finding = create(:finding)
    Current.organization = finding.organization
    policy = FindingPolicy.new(finding.recorded_by_membership.user, finding)

    expect(policy).to be_show
    expect(policy).to be_create
    expect(policy).to be_update
    expect(policy).to be_destroy
  end

  it "lets broad roles and Founder read without claiming field authorship" do
    finding = create(:finding)
    %w[administrator supervisor engineer].each do |role|
      membership = member(role, organization: finding.organization)
      Current.organization = finding.organization
      policy = FindingPolicy.new(membership.user, finding)
      expect(policy).to be_show
      expect(policy).not_to be_update
    end

    founder = create(:user, founder: true)
    Current.organization = finding.organization
    expect(FindingPolicy.new(founder, finding)).to be_show
    expect(FindingPolicy.new(founder, finding)).not_to be_update
  end

  it "denies unrelated Technicians, cross-tenant users, and submitted mutations" do
    finding = create(:finding)
    unrelated = member("technician", organization: finding.organization)
    foreign = member("engineer", organization: create(:organization))
    Current.organization = finding.organization

    expect(FindingPolicy.new(unrelated.user, finding)).not_to be_show
    expect(FindingPolicy.new(foreign.user, finding)).not_to be_show

    create(:execution_event, execution: finding.execution, organization: finding.organization,
                             actor_membership: finding.recorded_by_membership, event_type: "submitted")
    expect(FindingPolicy.new(finding.recorded_by_membership.user, finding)).not_to be_update
  end
end
