require "rails_helper"

RSpec.describe InvitationPolicy do
  after { Current.reset }

  describe "management actions" do
    it "allows an active Administrator in the current organization" do
      membership = create(:membership)
      create(:membership_role, membership: membership, role: "administrator")
      Current.organization = membership.organization
      invitation = create(:invitation, organization: membership.organization)
      policy = described_class.new(membership.user, invitation)

      expect(policy).to be_resend
      expect(policy).to be_destroy
    end

    it "allows a multi-role Administrator" do
      membership = create(:membership)
      create(:membership_role, membership: membership, role: "administrator")
      create(:membership_role, membership: membership, role: "technician")
      Current.organization = membership.organization

      expect(described_class.new(membership.user, Invitation)).to be_create
    end

    it "denies a non-Administrator" do
      membership = create(:membership)
      create(:membership_role, membership: membership, role: "supervisor")
      Current.organization = membership.organization

      expect(described_class.new(membership.user, Invitation)).not_to be_create
    end

    it "denies an inactive Administrator" do
      membership = create(:membership, active: false)
      create(:membership_role, membership: membership, role: "administrator")
      Current.organization = membership.organization

      expect(described_class.new(membership.user, Invitation)).not_to be_create
    end

    it "denies an invitation from another organization" do
      membership = create(:membership)
      create(:membership_role, membership: membership, role: "administrator")
      Current.organization = membership.organization
      invitation = create(:invitation)

      expect(described_class.new(membership.user, invitation)).not_to be_destroy
    end

    it "allows a Founder only with an explicitly selected organization" do
      founder = create(:user, founder: true)

      expect(described_class.new(founder, Invitation)).not_to be_create

      Current.organization = create(:organization)
      expect(described_class.new(founder, Invitation)).to be_create
    end
  end

  describe described_class::Scope do
    it "returns only current-organization invitations to an Administrator" do
      membership = create(:membership)
      create(:membership_role, membership: membership, role: "administrator")
      Current.organization = membership.organization
      visible = create(:invitation, organization: membership.organization)
      create(:invitation)

      expect(described_class.new(membership.user, Invitation.all).resolve).to contain_exactly(visible)
    end

    it "returns no invitations to a non-Administrator" do
      membership = create(:membership)
      create(:membership_role, membership: membership, role: "engineer")
      Current.organization = membership.organization
      create(:invitation, organization: membership.organization)

      expect(described_class.new(membership.user, Invitation.all).resolve).to be_empty
    end
  end
end
