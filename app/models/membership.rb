class Membership < ApplicationRecord
  class LastAdministratorError < StandardError; end

  belongs_to :organization
  belongs_to :user

  has_many :membership_roles, dependent: :destroy
  has_many :assignments, dependent: :restrict_with_exception
  has_many :execution_participants, dependent: :restrict_with_exception
  has_many :participating_executions, through: :execution_participants, source: :execution
  has_many :execution_events, foreign_key: :actor_membership_id, dependent: :restrict_with_exception
  has_many :uploaded_evidences, class_name: "Evidence", foreign_key: :uploaded_by_membership_id,
                                dependent: :restrict_with_exception
  has_many :recorded_execution_outcomes, class_name: "Execution",
                                           foreign_key: :outcome_recorded_by_membership_id,
                                           dependent: :restrict_with_exception
  has_many :received_clarification_requests, class_name: "ClarificationRequest",
                                             foreign_key: :recipient_membership_id,
                                             dependent: :restrict_with_exception
  has_many :clarification_responses, class_name: "ClarificationRequest",
                                     foreign_key: :responded_by_membership_id,
                                     dependent: :restrict_with_exception

  validates :user_id, uniqueness: { scope: :organization_id }
  validates :active, inclusion: { in: [ true, false ] }

  scope :active, -> { where(active: true) }
  scope :technicians, -> { active.joins(:membership_roles).where(membership_roles: { role: "technician" }).distinct }

  def update_access!(active:, roles:)
    normalized_roles = Array(roles).map(&:to_s).uniq
    unless normalized_roles.present? && normalized_roles.all? { |role| MembershipRole::ROLES.include?(role) }
      errors.add(:membership_roles, :invalid)
      raise ActiveRecord::RecordInvalid, self
    end

    organization.with_lock do
      lock!
      protect_last_administrator!(active: active, roles: normalized_roles)

      update!(active: ActiveModel::Type::Boolean.new.cast(active))
      membership_roles.where.not(role: normalized_roles).destroy_all
      normalized_roles.each { |role| membership_roles.find_or_create_by!(role: role) }
    end
  end

  private

  def protect_last_administrator!(active:, roles:)
    currently_administrator = active? && membership_roles.exists?(role: "administrator")
    remains_administrator = ActiveModel::Type::Boolean.new.cast(active) && roles.include?("administrator")
    return unless currently_administrator && !remains_administrator

    active_administrators = organization.memberships.active
                                        .joins(:membership_roles)
                                        .where(membership_roles: { role: "administrator" })
                                        .distinct
                                        .count
    raise LastAdministratorError if active_administrators <= 1
  end
end
