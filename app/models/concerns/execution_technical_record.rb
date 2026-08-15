module ExecutionTechnicalRecord
  extend ActiveSupport::Concern

  included do
    belongs_to :organization
    belongs_to :execution
    belongs_to :recorded_by_membership, class_name: "Membership"

    has_many :evidence_references, as: :technical_record, dependent: :delete_all,
                                   inverse_of: :technical_record
    has_many :evidences, through: :evidence_references

    attr_readonly :organization_id, :execution_id, :recorded_by_membership_id, :recorded_at

    validates :recorded_at, presence: true
    validate :tenant_relationships_are_consistent
    validate :recorder_is_participating_technician
    validate :execution_is_editable
    before_destroy :prevent_submitted_destruction

    scope :chronological, -> { order(:recorded_at, :id) }
  end

  def sync_evidence_ids!(ids)
    requested_ids = Array(ids).compact_blank.map(&:to_i).uniq
    transaction do
      lock!
      raise_locked! if execution.submitted?

      available = execution.evidences.where(id: requested_ids).index_by(&:id)
      raise ActiveRecord::RecordNotFound unless available.size == requested_ids.size

      evidence_references.where.not(evidence_id: requested_ids).destroy_all
      requested_ids.each do |id|
        evidence_references.find_or_create_by!(evidence: available.fetch(id), role: "supporting") do |reference|
          reference.organization = organization
          reference.execution = execution
        end
      end
    end
  end

  private

  def tenant_relationships_are_consistent
    return if organization.nil?

    errors.add(:execution, :invalid) if execution && execution.organization_id != organization_id
    if recorded_by_membership && recorded_by_membership.organization_id != organization_id
      errors.add(:recorded_by_membership, :invalid)
    end
  end

  def recorder_is_participating_technician
    return unless execution && recorded_by_membership
    return if recorded_by_membership.active? &&
              recorded_by_membership.membership_roles.exists?(role: "technician") &&
              execution.participant?(recorded_by_membership)

    errors.add(:recorded_by_membership, :invalid)
  end

  def execution_is_editable
    errors.add(:base, :execution_submitted) if execution&.submitted?
  end

  def prevent_submitted_destruction
    return unless execution.submitted?

    errors.add(:base, :execution_submitted)
    throw :abort
  end

  def raise_locked!
    errors.add(:base, :execution_submitted)
    raise ActiveRecord::RecordInvalid, self
  end
end
