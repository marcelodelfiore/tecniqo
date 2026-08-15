class WorkOrderPolicy < ApplicationPolicy
  READ_ROLES = %w[administrator supervisor engineer].freeze
  MANAGE_ROLES = %w[administrator supervisor].freeze

  def index?
    current_organization.present? && (founder? || current_membership.present?)
  end

  def show?
    same_organization? && (broad_read_access? || assigned_technician?)
  end

  def create?
    manage?
  end

  def update?
    same_organization? && manage?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless Current.organization

      tenant_scope = scope.where(organization: Current.organization)
      return tenant_scope if user.founder?

      membership = user.memberships.active.find_by(organization: Current.organization)
      return scope.none unless membership
      return tenant_scope if membership.membership_roles.where(role: READ_ROLES).exists?
      return scope.none unless membership.membership_roles.exists?(role: "technician")

      tenant_scope.joins(:assignments)
                  .where(assignments: { membership_id: membership.id, ended_at: nil })
                  .distinct
    end
  end

  private

  def broad_read_access?
    founder? || current_membership&.membership_roles&.where(role: READ_ROLES)&.exists?
  end

  def assigned_technician?
    membership = current_membership
    membership&.membership_roles&.exists?(role: "technician") &&
      record.assignments.current.exists?(membership: membership)
  end

  def manage?
    current_organization.present? &&
      (founder? || current_membership&.membership_roles&.where(role: MANAGE_ROLES)&.exists?)
  end
end
