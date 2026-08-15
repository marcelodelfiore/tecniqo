require "rails_helper"

RSpec.describe ServiceTypePolicy do
  after { Current.reset }

  def member(role, organization:)
    membership = create(:membership, organization: organization)
    create(:membership_role, membership: membership, role: role)
    membership
  end

  it "allows Founder, Administrator, and Supervisor to manage while Engineer reads" do
    service_type = create(:service_type)
    Current.organization = service_type.organization
    administrator = member("administrator", organization: service_type.organization)
    supervisor = member("supervisor", organization: service_type.organization)
    engineer = member("engineer", organization: service_type.organization)

    [ create(:user, founder: true), administrator.user, supervisor.user ].each do |user|
      expect(described_class.new(user, service_type)).to be_update
    end
    expect(described_class.new(engineer.user, service_type)).to be_show
    expect(described_class.new(engineer.user, service_type)).not_to be_update
  end

  it "denies Technician and cross-organization access" do
    service_type = create(:service_type)
    Current.organization = service_type.organization
    technician = member("technician", organization: service_type.organization)
    administrator = member("administrator", organization: create(:organization))

    expect(described_class.new(technician.user, service_type)).not_to be_show
    expect(described_class.new(administrator.user, service_type)).not_to be_show
  end
end
