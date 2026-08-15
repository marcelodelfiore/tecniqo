require "rails_helper"

RSpec.describe ServiceType do
  it "requires an organization-scoped, case-insensitively unique name" do
    service_type = create(:service_type, name: "Corrective Electrical Maintenance")

    expect(build(:service_type, organization: service_type.organization,
                                name: "corrective electrical maintenance")).not_to be_valid
    expect(build(:service_type, name: service_type.name)).to be_valid
  end

  it "can be deactivated and reactivated without losing history" do
    service_type = create(:service_type)

    service_type.deactivate!
    expect(service_type).not_to be_active

    service_type.activate!
    expect(service_type).to be_active
  end
end
