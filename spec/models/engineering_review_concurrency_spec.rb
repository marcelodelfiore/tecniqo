require "rails_helper"

RSpec.describe EngineeringReview, type: :model do
  self.use_transactional_tests = false

  after do
    ClarificationEvidence.delete_all
    ClarificationRequest.delete_all
    EngineeringReviewExecution.delete_all
    described_class.delete_all
    ExecutionEvent.delete_all
    ExecutionParticipant.delete_all
    Execution.delete_all
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

  def engineer(organization)
    membership = create(:membership, organization: organization)
    create(:membership_role, membership: membership, role: "engineer")
    membership.user
  end

  def concurrent_claims(review, engineers)
    ready = Queue.new
    start = Queue.new
    threads = engineers.map do |engineer|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ready << true
          start.pop
          described_class.find(review.id).start!(actor: User.find(engineer.id))
          :claimed
        rescue ActiveRecord::RecordInvalid
          :rejected
        end
      end
    end
    engineers.size.times { ready.pop }
    engineers.size.times { start << true }
    threads.map(&:value)
  end

  it "serializes competing Engineer claims" do
    review = create(:engineering_review)
    engineers = 2.times.map { engineer(review.organization) }

    expect(concurrent_claims(review, engineers)).to contain_exactly(:claimed, :rejected)
    expect(review.reload.reviewer).to be_in(engineers)
  end
end
