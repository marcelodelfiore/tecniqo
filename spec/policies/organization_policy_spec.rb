require "rails_helper"

RSpec.describe OrganizationPolicy do
  describe "#select?" do
    it "allows an active member" do
      membership = create(:membership)

      expect(described_class.new(membership.user, membership.organization)).to be_select
    end

    it "denies an inactive member" do
      membership = create(:membership, active: false)

      expect(described_class.new(membership.user, membership.organization)).not_to be_select
    end

    it "denies a non-member" do
      expect(described_class.new(create(:user), create(:organization))).not_to be_select
    end

    it "allows a Founder" do
      expect(described_class.new(create(:user, founder: true), create(:organization))).to be_select
    end
  end

  describe described_class::Scope do
    it "returns only organizations from active memberships" do
      user = create(:user)
      active_membership = create(:membership, user: user)
      create(:membership, user: user, active: false)
      create(:organization)

      result = described_class.new(user, Organization.all).resolve

      expect(result).to contain_exactly(active_membership.organization)
    end

    it "returns all organizations for a Founder" do
      founder = create(:user, founder: true)
      organizations = create_list(:organization, 2)

      expect(described_class.new(founder, Organization.all).resolve).to match_array(organizations)
    end
  end
end
