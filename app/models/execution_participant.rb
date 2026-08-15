class ExecutionParticipant < ApplicationRecord
  belongs_to :organization
  belongs_to :execution
  belongs_to :membership
  belongs_to :added_by, class_name: "User"

  has_one :user, through: :membership

  validates :membership_id, uniqueness: { scope: :execution_id }
  validate :relationships_belong_to_organization
  validate :membership_is_eligible_technician
  before_destroy :prevent_submitted_change
  before_destroy :preserve_event_actor
  before_destroy :preserve_one_participant

  private

  def relationships_belong_to_organization
    return if organization.nil?

    errors.add(:execution, :invalid) if execution && execution.organization_id != organization_id
    errors.add(:membership, :invalid) if membership && membership.organization_id != organization_id
  end

  def membership_is_eligible_technician
    return if membership&.active? && membership.membership_roles.exists?(role: "technician")

    errors.add(:membership, :invalid_participant)
  end

  def prevent_submitted_change
    return unless execution.submitted?

    errors.add(:base, :execution_submitted)
    throw :abort
  end

  def preserve_one_participant
    return unless execution.execution_participants.count <= 1

    errors.add(:base, :last_execution_participant)
    throw :abort
  end

  def preserve_event_actor
    return unless execution.execution_events.exists?(actor_membership: membership)

    errors.add(:base, :participant_has_events)
    throw :abort
  end
end
