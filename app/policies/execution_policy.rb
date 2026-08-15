class ExecutionPolicy < ApplicationPolicy
  READ_ROLES = WorkOrderPolicy::READ_ROLES
  MANAGE_ROLES = WorkOrderPolicy::MANAGE_ROLES

  def show?
    same_organization? && (broad_read_access? || participating_technician?)
  end

  def create?
    same_organization? && manage?
  end

  def add_participant?
    same_organization? && manage? && !record.submitted?
  end

  def remove_participant?
    add_participant?
  end

  def perform_event?
    same_organization? && participating_technician?
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

      tenant_scope.joins(:execution_participants)
                  .where(execution_participants: { membership_id: membership.id })
                  .distinct
    end
  end

  private

  def broad_read_access?
    founder? || current_membership&.membership_roles&.where(role: READ_ROLES)&.exists?
  end

  def participating_technician?
    membership = current_membership
    membership&.membership_roles&.exists?(role: "technician") && record.participant?(membership)
  end

  def manage?
    founder? || current_membership&.membership_roles&.where(role: MANAGE_ROLES)&.exists?
  end
end
