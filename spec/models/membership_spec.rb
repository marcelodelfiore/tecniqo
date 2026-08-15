require "rails_helper"

RSpec.describe Membership, type: :model do
  it "belongs to one user in one organization" do
    membership = create(:membership)

    expect(membership.user).to be_present
    expect(membership.organization).to be_present
  end

  it "rejects a duplicate user and organization pair" do
    membership = create(:membership)
    duplicate = build(:membership, user: membership.user, organization: membership.organization)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:user_id]).to include("has already been taken")
  end

  it "enforces membership uniqueness in the database" do
    membership = create(:membership)

    expect do
      described_class.insert_all!([ {
        user_id: membership.user_id,
        organization_id: membership.organization_id,
        active: true,
        created_at: Time.current,
        updated_at: Time.current
      } ])
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "distinguishes active from inactive memberships" do
    active_membership = create(:membership, active: true)
    inactive_membership = create(:membership, active: false)

    expect(described_class.active).to include(active_membership)
    expect(described_class.active).not_to include(inactive_membership)
  end

  it "requires an explicit lifecycle state" do
    membership = build(:membership, active: nil)

    expect(membership).not_to be_valid
  end

  describe "#update_access!" do
    it "updates lifecycle and synchronizes fixed roles" do
      membership = create(:membership)
      create(:membership_role, membership: membership, role: "technician")

      membership.update_access!(active: "0", roles: %w[supervisor engineer])

      expect(membership.reload).not_to be_active
      expect(membership.membership_roles.pluck(:role)).to match_array(%w[supervisor engineer])
    end

    it "rejects empty or unknown roles" do
      membership = create(:membership)

      expect { membership.update_access!(active: true, roles: []) }
        .to raise_error(ActiveRecord::RecordInvalid)
      expect { membership.update_access!(active: true, roles: [ "founder" ]) }
        .to raise_error(ActiveRecord::RecordInvalid)
    end

    it "prevents deactivating the last active Administrator" do
      membership = create(:membership)
      create(:membership_role, membership: membership, role: "administrator")

      expect do
        membership.update_access!(active: false, roles: [ "administrator" ])
      end.to raise_error(described_class::LastAdministratorError)

      expect(membership.reload).to be_active
    end

    it "prevents removing the last active Administrator role" do
      membership = create(:membership)
      create(:membership_role, membership: membership, role: "administrator")

      expect do
        membership.update_access!(active: true, roles: [ "technician" ])
      end.to raise_error(described_class::LastAdministratorError)

      expect(membership.reload.membership_roles.pluck(:role)).to eq([ "administrator" ])
    end

    it "allows demotion when another active Administrator remains" do
      membership = create(:membership)
      create(:membership_role, membership: membership, role: "administrator")
      other = create(:membership, organization: membership.organization)
      create(:membership_role, membership: other, role: "administrator")

      membership.update_access!(active: true, roles: [ "technician" ])

      expect(membership.reload.membership_roles.pluck(:role)).to eq([ "technician" ])
    end
  end
end
