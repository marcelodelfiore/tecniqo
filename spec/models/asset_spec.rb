require "rails_helper"

RSpec.describe Asset do
  it "requires a name, type, site, and organization" do
    asset = described_class.new(asset_type: nil)

    expect(asset).not_to be_valid
    expect(asset.errors).to be_of_kind(:name, :blank)
    expect(asset.errors).to be_of_kind(:asset_type, :blank)
    expect(asset.errors).to be_of_kind(:site, :blank)
    expect(asset.errors).to be_of_kind(:organization, :blank)
  end

  it "uses Other by default and accepts only the curated type vocabulary" do
    expect(described_class.new.asset_type).to eq("other")
    expect(build(:asset, asset_type: "motor")).to be_valid
    expect(build(:asset, asset_type: "compressor")).not_to be_valid
  end

  it "does not over-constrain names or tags within a site" do
    asset = create(:asset, name: "Motor", tag: "M-21")

    expect(build(:asset, site: asset.site, name: asset.name, tag: asset.tag)).to be_valid
  end

  it "rejects an organization that differs from its site in Rails and PostgreSQL" do
    asset = build(:asset, organization: create(:organization))
    expect(asset).not_to be_valid

    persisted_asset = create(:asset)
    expect {
      persisted_asset.update_column(:organization_id, create(:organization).id)
    }.to raise_error(ActiveRecord::InvalidForeignKey)
  end

  it "enforces the curated type vocabulary in PostgreSQL" do
    asset = create(:asset)

    expect { asset.update_column(:asset_type, "compressor") }
      .to raise_error(ActiveRecord::StatementInvalid)
  end
end
