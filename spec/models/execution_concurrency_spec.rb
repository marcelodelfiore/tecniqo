require "rails_helper"

RSpec.describe Execution, type: :model do
  self.use_transactional_tests = false

  after do
    ExecutionEvent.delete_all
    ExecutionParticipant.delete_all
    described_class.delete_all
    Assignment.delete_all
    WorkOrder.delete_all
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

  def concurrent_arrivals(execution, participant)
    ready = Queue.new
    start = Queue.new
    threads = 2.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ready << true
          start.pop
          described_class.find(execution.id).record_event!("arrived_at_site",
                                                           actor_membership: Membership.find(participant.id))
          :created
        rescue ExecutionEvent::InvalidTransition
          :rejected
        end
      end
    end
    2.times { ready.pop }
    2.times { start << true }
    threads.map(&:value)
  end

  it "serializes duplicate field actions" do
    execution = create(:execution)
    participant = create(:membership, organization: execution.organization)
    create(:membership_role, membership: participant, role: "technician")
    create(:execution_participant, execution: execution, membership: participant)

    expect(concurrent_arrivals(execution, participant)).to contain_exactly(:created, :rejected)
    expect(ExecutionEvent.where(execution: execution, event_type: "arrived_at_site").count).to eq(1)
  end
end
