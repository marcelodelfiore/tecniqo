require "rails_helper"

RSpec.describe AssetPolicy do
  after { Current.reset }

  it "uses the Phase 2 role and tenant boundary" do
    asset = create(:asset)
    Current.organization = asset.organization

    administrator = create(:membership, organization: asset.organization)
    create(:membership_role, membership: administrator, role: "administrator")
    technician = create(:membership, organization: asset.organization)
    create(:membership_role, membership: technician, role: "technician")

    expect(described_class.new(administrator.user, asset)).to be_update
    expect(described_class.new(technician.user, asset)).not_to be_show
    expect(described_class.new(create(:user, founder: true), asset)).to be_show
    expect(described_class.new(administrator.user, create(:asset))).not_to be_show
  end
end
