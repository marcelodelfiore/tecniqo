require "rails_helper"

RSpec.describe WorkOrderPolicy do
  after { Current.reset }

  def member(role, organization:)
    membership = create(:membership, organization: organization)
    create(:membership_role, membership: membership, role: role)
    membership
  end

  it "allows Founder, Administrator, and Supervisor to manage while Engineer reads" do
    work_order = create(:work_order)
    Current.organization = work_order.organization
    administrator = member("administrator", organization: work_order.organization)
    supervisor = member("supervisor", organization: work_order.organization)
    engineer = member("engineer", organization: work_order.organization)

    [ create(:user, founder: true), administrator.user, supervisor.user ].each do |user|
      expect(described_class.new(user, work_order)).to be_update
    end
    expect(described_class.new(engineer.user, work_order)).to be_show
    expect(described_class.new(engineer.user, work_order)).not_to be_update
  end

  it "allows a Technician to read only their current assignment" do
    work_order = create(:work_order)
    technician = member("technician", organization: work_order.organization)
    Current.organization = work_order.organization
    work_order.assign_to!(technician, assigned_by: create(:user))
    other_work_order = create(:work_order, organization: work_order.organization,
                                           customer: work_order.customer, site: work_order.site,
                                           service_type: work_order.service_type)

    expect(described_class.new(technician.user, work_order)).to be_show
    expect(described_class.new(technician.user, other_work_order)).not_to be_show
    expect(described_class::Scope.new(technician.user, WorkOrder.all).resolve).to contain_exactly(work_order)
  end

  it "denies cross-organization records" do
    work_order = create(:work_order)
    administrator = member("administrator", organization: create(:organization))
    Current.organization = administrator.organization

    expect(described_class.new(administrator.user, work_order)).not_to be_show
    expect(described_class::Scope.new(administrator.user, WorkOrder.all).resolve).to be_empty
  end
end
