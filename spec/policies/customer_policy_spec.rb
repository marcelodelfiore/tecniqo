require "rails_helper"

RSpec.describe CustomerPolicy do
  after { Current.reset }

  def membership_with_role(role, organization: create(:organization), active: true)
    membership = create(:membership, organization: organization, active: active)
    create(:membership_role, membership: membership, role: role)
    membership
  end

  it "allows Founder, Administrator, and Supervisor to manage in the selected organization" do
    customer = create(:customer)
    Current.organization = customer.organization

    founder = create(:user, founder: true)
    administrator = membership_with_role("administrator", organization: customer.organization)
    supervisor = membership_with_role("supervisor", organization: customer.organization)

    [ founder, administrator.user, supervisor.user ].each do |user|
      expect(described_class.new(user, customer)).to be_show
      expect(described_class.new(user, customer)).to be_update
    end
  end

  it "allows Engineer read access but denies management" do
    customer = create(:customer)
    engineer = membership_with_role("engineer", organization: customer.organization)
    Current.organization = customer.organization

    expect(described_class.new(engineer.user, customer)).to be_show
    expect(described_class.new(engineer.user, customer)).not_to be_update
  end

  it "denies Technician, inactive membership, and cross-organization access" do
    customer = create(:customer)
    technician = membership_with_role("technician", organization: customer.organization)
    inactive = membership_with_role("administrator", organization: customer.organization, active: false)
    administrator = membership_with_role("administrator")
    Current.organization = customer.organization

    expect(described_class.new(technician.user, customer)).not_to be_show
    expect(described_class.new(inactive.user, customer)).not_to be_show
    expect(described_class.new(administrator.user, customer)).not_to be_show
  end

  describe described_class::Scope do
    it "returns only selected-organization customers for permitted roles and Founder" do
      customer = create(:customer)
      other_customer = create(:customer)
      engineer = membership_with_role("engineer", organization: customer.organization)
      Current.organization = customer.organization

      expect(described_class.new(engineer.user, Customer.all).resolve).to contain_exactly(customer)
      expect(described_class.new(create(:user, founder: true), Customer.all).resolve).to contain_exactly(customer)
      expect(described_class.new(membership_with_role("technician", organization: customer.organization).user, Customer.all).resolve).to be_empty
      expect(other_customer).to be_persisted
    end
  end
end
