class EvidenceReference < ApplicationRecord
  ROLES = %w[supporting before after].freeze
  RECORD_TYPES = %w[Finding Measurement ActionPerformed MaterialUsed Recommendation].freeze

  belongs_to :organization
  belongs_to :execution
  belongs_to :evidence
  belongs_to :technical_record, polymorphic: true

  attr_readonly :organization_id, :execution_id, :evidence_id, :technical_record_type,
                :technical_record_id, :role

  validates :role, inclusion: { in: ROLES }
  validates :technical_record_type, inclusion: { in: RECORD_TYPES }
  validates :evidence_id, uniqueness: {
    scope: %i[technical_record_type technical_record_id role]
  }
  validate :relationships_share_execution
  validate :execution_is_editable
  before_destroy :prevent_submitted_destruction

  private

  def relationships_share_execution
    return unless execution

    errors.add(:organization, :invalid) if organization_id != execution.organization_id
    errors.add(:evidence, :invalid) if evidence && evidence.execution_id != execution_id
    return unless technical_record

    errors.add(:technical_record, :invalid) if technical_record.execution_id != execution_id ||
                                               technical_record.organization_id != organization_id
  end

  def execution_is_editable
    errors.add(:base, :execution_submitted) if execution&.submitted?
  end

  def prevent_submitted_destruction
    return unless execution.submitted?

    errors.add(:base, :execution_submitted)
    throw :abort
  end
end
