require "rails_helper"

RSpec.describe Site do
  it "requires a name, customer, and organization" do
    site = described_class.new

    expect(site).not_to be_valid
    expect(site.errors).to be_of_kind(:name, :blank)
    expect(site.errors).to be_of_kind(:customer, :blank)
    expect(site.errors).to be_of_kind(:organization, :blank)
  end

  it "keeps site names unique within a customer, ignoring case" do
    site = create(:site, name: "Betim Plant")

    expect(build(:site, customer: site.customer, name: "betim plant")).not_to be_valid
    expect(build(:site, name: "Betim Plant")).to be_valid
  end

  it "rejects an organization that differs from its customer in Rails and PostgreSQL" do
    site = build(:site, organization: create(:organization))
    expect(site).not_to be_valid

    persisted_site = create(:site)
    expect {
      persisted_site.update_column(:organization_id, create(:organization).id)
    }.to raise_error(ActiveRecord::InvalidForeignKey)
  end
end
