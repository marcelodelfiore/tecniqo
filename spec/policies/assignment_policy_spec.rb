require "rails_helper"

RSpec.describe AssignmentPolicy do
  after { Current.reset }

  def member(role, organization:)
    membership = create(:membership, organization: organization)
    create(:membership_role, membership: membership, role: role)
    membership
  end

  it "allows Founder, Administrator, and Supervisor to assign within the tenant" do
    work_order = create(:work_order)
    assignment = build(:assignment, work_order: work_order, organization: work_order.organization)
    Current.organization = work_order.organization
    administrator = member("administrator", organization: work_order.organization)
    supervisor = member("supervisor", organization: work_order.organization)

    expect(described_class.new(create(:user, founder: true), assignment)).to be_create
    expect(described_class.new(administrator.user, assignment)).to be_create
    expect(described_class.new(supervisor.user, assignment)).to be_create
  end

  it "denies Engineer, Technician, and cross-organization assignment" do
    work_order = create(:work_order)
    assignment = build(:assignment, work_order: work_order, organization: work_order.organization)
    Current.organization = work_order.organization
    engineer = member("engineer", organization: work_order.organization)
    technician = member("technician", organization: work_order.organization)

    expect(described_class.new(engineer.user, assignment)).not_to be_create
    expect(described_class.new(technician.user, assignment)).not_to be_create
    Current.organization = create(:organization)
    expect(described_class.new(create(:user, founder: true), assignment)).not_to be_create
  end

  it "returns only active Technician memberships from the selected Organization" do
    organization = create(:organization)
    technician = member("technician", organization: organization)
    inactive = member("technician", organization: organization)
    inactive.update!(active: false)
    member("supervisor", organization: organization)
    member("technician", organization: create(:organization))
    Current.organization = organization

    scope = described_class::AssignableScope.new(create(:user, founder: true), Membership.all).resolve
    expect(scope).to contain_exactly(technician)
  end
end
