require "rails_helper"

RSpec.describe WorkOrder do
  def technician_membership(organization)
    membership = create(:membership, organization: organization)
    create(:membership_role, membership: membership, role: "technician")
    membership
  end

  it "issues stable sequential identifiers within an organization" do
    organization = create(:organization)
    customer = create(:customer, organization: organization)
    site = create(:site, customer: customer)
    service_type = create(:service_type, organization: organization)
    creator = create(:user)
    attributes = { customer: customer, site: site, service_type: service_type,
                   requested_work: "Motor trips after several minutes." }

    first = described_class.issue!(organization: organization, attributes: attributes, created_by: creator)
    second = described_class.issue!(organization: organization, attributes: attributes, created_by: creator)

    expect(first.public_identifier).to eq("OS-#{Time.current.year}-000001")
    expect(second.public_identifier).to eq("OS-#{Time.current.year}-000002")
  end

  it "requires its core context and accepts an optional asset" do
    work_order = described_class.new

    expect(work_order).not_to be_valid
    expect(work_order.errors).to be_of_kind(:customer, :blank)
    expect(work_order.errors).to be_of_kind(:site, :blank)
    expect(work_order.errors).to be_of_kind(:service_type, :blank)
    expect(work_order.errors).to be_of_kind(:requested_work, :blank)
    expect(build(:work_order, asset: nil)).to be_valid
  end

  it "rejects inconsistent organization, customer, site, asset, and Service Type context" do
    work_order = build(:work_order)
    work_order.site = create(:site, customer: create(:customer, organization: work_order.organization))
    work_order.asset = create(:asset)
    work_order.service_type = create(:service_type)

    expect(work_order).not_to be_valid
    expect(work_order.errors[:site]).to be_present
    expect(work_order.errors[:asset]).to be_present
    expect(work_order.errors[:service_type]).to be_present
  end

  it "enforces context consistency in PostgreSQL" do
    work_order = create(:work_order)

    other_site = create(:site, customer: create(:customer, organization: work_order.organization))
    expect { work_order.update_column(:site_id, other_site.id) }
      .to raise_error(ActiveRecord::InvalidForeignKey)
  end

  it "enforces Service Type tenant consistency in PostgreSQL" do
    work_order = create(:work_order)

    expect { work_order.update_column(:service_type_id, create(:service_type).id) }
      .to raise_error(ActiveRecord::InvalidForeignKey)
  end

  it "uses the small priority vocabulary in Rails and PostgreSQL" do
    expect(build(:work_order, priority: "urgent")).to be_valid
    expect(build(:work_order, priority: "low")).not_to be_valid

    work_order = create(:work_order)
    expect { work_order.update_column(:priority, "low") }
      .to raise_error(ActiveRecord::StatementInvalid)
  end

  it "creates an initial assignment atomically when issued" do
    organization = create(:organization)
    customer = create(:customer, organization: organization)
    site = create(:site, customer: customer)
    service_type = create(:service_type, organization: organization)
    technician = technician_membership(organization)
    creator = create(:user)

    work_order = described_class.issue!(
      organization: organization,
      attributes: { customer: customer, site: site, service_type: service_type, requested_work: "Inspect motor" },
      created_by: creator,
      assignee_membership: technician
    )

    expect(work_order.current_assignment).to have_attributes(membership: technician, assigned_by: creator)
  end
end
