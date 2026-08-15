require "rails_helper"

RSpec.describe MembershipRole, type: :model do
  it "accepts every fixed role" do
    described_class::ROLES.each do |role|
      expect(build(:membership_role, role: role)).to be_valid
    end
  end

  it "rejects a role outside the fixed vocabulary" do
    membership_role = build(:membership_role, role: "founder")

    expect(membership_role).not_to be_valid
    expect(membership_role.errors[:role]).to include("is not included in the list")
  end

  it "rejects a duplicate role on one membership" do
    membership_role = create(:membership_role)
    duplicate = build(:membership_role, membership: membership_role.membership, role: membership_role.role)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:role]).to include("has already been taken")
  end

  it "enforces role uniqueness in the database" do
    membership_role = create(:membership_role)

    expect do
      described_class.insert_all!([ {
        membership_id: membership_role.membership_id,
        role: membership_role.role,
        created_at: Time.current,
        updated_at: Time.current
      } ])
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "enforces the fixed vocabulary in the database" do
    membership = create(:membership)

    expect do
      described_class.insert_all!([ {
        membership_id: membership.id,
        role: "founder",
        created_at: Time.current,
        updated_at: Time.current
      } ])
    end.to raise_error(ActiveRecord::StatementInvalid, /membership_roles_role_check/)
  end
end
