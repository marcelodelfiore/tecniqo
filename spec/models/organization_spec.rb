require "rails_helper"

RSpec.describe Organization, type: :model do
  it "requires a name" do
    organization = build(:organization, name: nil)

    expect(organization).not_to be_valid
    expect(organization.errors[:name]).to include("can't be blank")
  end

  it "does not allow deletion while memberships exist" do
    organization = create(:organization)
    create(:membership, organization: organization)

    expect { organization.destroy! }.to raise_error(ActiveRecord::DeleteRestrictionError)
  end
end
