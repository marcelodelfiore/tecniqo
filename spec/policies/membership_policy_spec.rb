require "rails_helper"

RSpec.describe MembershipPolicy do
  after { Current.reset }

  it "allows an active Administrator to manage current-organization memberships" do
    administrator = create(:membership)
    create(:membership_role, membership: administrator, role: "administrator")
    Current.organization = administrator.organization
    member = create(:membership, organization: administrator.organization)

    expect(described_class.new(administrator.user, Membership)).to be_index
    expect(described_class.new(administrator.user, member)).to be_update
  end

  it "denies non-Administrators and inactive Administrators" do
    member = create(:membership)
    create(:membership_role, membership: member, role: "supervisor")
    Current.organization = member.organization
    expect(described_class.new(member.user, Membership)).not_to be_index

    member.update!(active: false)
    create(:membership_role, membership: member, role: "administrator")
    expect(described_class.new(member.user, Membership)).not_to be_index
  end

  it "denies cross-organization membership updates" do
    administrator = create(:membership)
    create(:membership_role, membership: administrator, role: "administrator")
    Current.organization = administrator.organization

    expect(described_class.new(administrator.user, create(:membership))).not_to be_update
  end

  it "allows Founder only inside the selected organization" do
    founder = create(:user, founder: true)
    expect(described_class.new(founder, Membership)).not_to be_index

    Current.organization = create(:organization)
    expect(described_class.new(founder, Membership)).to be_index
  end

  describe described_class::Scope do
    it "returns only current-organization memberships to an Administrator" do
      administrator = create(:membership)
      create(:membership_role, membership: administrator, role: "administrator")
      Current.organization = administrator.organization
      colleague = create(:membership, organization: administrator.organization)
      create(:membership)

      expect(described_class.new(administrator.user, Membership.all).resolve)
        .to contain_exactly(administrator, colleague)
    end
  end
end
