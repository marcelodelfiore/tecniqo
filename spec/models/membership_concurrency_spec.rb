require "rails_helper"

RSpec.describe Membership, type: :model do
  self.use_transactional_tests = false

  def concurrently_demote(memberships)
    ready = Queue.new
    start = Queue.new
    threads = memberships.map { |membership| demotion_thread(membership, ready, start) }

    memberships.size.times { ready.pop }
    memberships.size.times { start << true }
    threads.map(&:value)
  end

  def demotion_thread(membership, ready, start)
    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        ready << true
        start.pop
        described_class.find(membership.id).update_access!(active: true, roles: [ "technician" ])
        :updated
      rescue described_class::LastAdministratorError
        :protected
      end
    end
  end

  after do
    MembershipRole.delete_all
    described_class.delete_all
    Invitation.delete_all
    LoginToken.delete_all
    Organization.delete_all
    User.delete_all
  end

  it "serializes demotions and preserves one active Administrator" do
    organization = create(:organization)
    memberships = create_list(:membership, 2, organization: organization)
    memberships.each { |membership| create(:membership_role, membership: membership, role: "administrator") }

    expect(concurrently_demote(memberships)).to match_array(%i[updated protected])
    expect(organization.memberships.active.joins(:membership_roles)
                       .where(membership_roles: { role: "administrator" }).count).to eq(1)
  end
end
