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
end
