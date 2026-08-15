require "rails_helper"

RSpec.describe WorkOrder, type: :model do
  self.use_transactional_tests = false

  def issuance_thread(records, ready, start)
    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        ready << true
        start.pop
        organization, customer, site, service_type, creator = records.map { |record| record.class.find(record.id) }
        described_class.issue!(
          organization: organization,
          attributes: { customer: customer, site: site, service_type: service_type,
                        requested_work: "Concurrent work" },
          created_by: creator
        ).sequence_number
      end
    end
  end

  after do
    Assignment.delete_all
    described_class.delete_all
    ServiceType.delete_all
    Asset.delete_all
    Site.delete_all
    Customer.delete_all
    MembershipRole.delete_all
    Membership.delete_all
    Invitation.delete_all
    LoginToken.delete_all
    Organization.delete_all
    User.delete_all
  end

  it "serializes identifier allocation within an Organization" do
    organization = create(:organization)
    customer = create(:customer, organization: organization)
    site = create(:site, customer: customer)
    service_type = create(:service_type, organization: organization)
    creator = create(:user)
    ready = Queue.new
    start = Queue.new

    records = [ organization, customer, site, service_type, creator ]
    threads = 2.times.map { issuance_thread(records, ready, start) }
    2.times { ready.pop }
    2.times { start << true }

    expect(threads.map(&:value)).to contain_exactly(1, 2)
    expect(organization.reload.work_order_sequence).to eq(2)
  end
end
