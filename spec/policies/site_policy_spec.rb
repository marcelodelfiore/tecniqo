require "rails_helper"

RSpec.describe SitePolicy do
  after { Current.reset }

  it "uses the Phase 2 role and tenant boundary" do
    site = create(:site)
    Current.organization = site.organization

    supervisor = create(:membership, organization: site.organization)
    create(:membership_role, membership: supervisor, role: "supervisor")
    engineer = create(:membership, organization: site.organization)
    create(:membership_role, membership: engineer, role: "engineer")

    expect(described_class.new(supervisor.user, site)).to be_update
    expect(described_class.new(engineer.user, site)).to be_show
    expect(described_class.new(engineer.user, site)).not_to be_update
    expect(described_class.new(supervisor.user, create(:site))).not_to be_show
  end
end
