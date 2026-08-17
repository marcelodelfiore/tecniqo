class ClarificationEvidence < ApplicationRecord
  belongs_to :organization
  belongs_to :clarification_request, touch: true
  belongs_to :evidence

  validates :evidence_id, uniqueness: { scope: :clarification_request_id }
  validate :context_is_consistent

  private

  def context_is_consistent
    return unless organization && clarification_request && evidence

    errors.add(:clarification_request, :invalid) if clarification_request.organization_id != organization_id
    if evidence.organization_id != organization_id || evidence.execution_id != clarification_request.execution_id
      errors.add(:evidence, :invalid)
    end
  end
end
