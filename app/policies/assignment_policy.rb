class AssignmentPolicy < ApplicationPolicy
  MANAGE_ROLES = WorkOrderPolicy::MANAGE_ROLES

  def create?
    same_organization? && manage?
  end

  class AssignableScope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless Current.organization
      return eligible_memberships if user.founder?

      membership = user.memberships.active.find_by(organization: Current.organization)
      return scope.none unless membership&.membership_roles&.where(role: MANAGE_ROLES)&.exists?

      eligible_memberships
    end

    private

    def eligible_memberships
      scope.technicians.where(organization: Current.organization).includes(:user).order("users.email")
    end
  end

  private

  def same_organization?
    current_organization && record.work_order.organization_id == current_organization.id
  end

  def manage?
    founder? || current_membership&.membership_roles&.where(role: MANAGE_ROLES)&.exists?
  end
end
