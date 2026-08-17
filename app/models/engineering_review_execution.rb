class EngineeringReviewExecution < ApplicationRecord
  belongs_to :organization
  belongs_to :engineering_review
  belongs_to :execution

  validates :execution_id, uniqueness: { scope: :engineering_review_id }
  validate :context_is_consistent

  private

  def context_is_consistent
    return unless organization && engineering_review && execution

    errors.add(:engineering_review, :invalid) if engineering_review.organization_id != organization_id
    errors.add(:execution, :invalid) if execution.organization_id != organization_id ||
                                        execution.work_order_id != engineering_review.work_order_id ||
                                        !execution.submitted?
  end
end
