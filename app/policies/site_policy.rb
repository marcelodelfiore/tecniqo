class SitePolicy < ApplicationPolicy
  READ_ROLES = CustomerPolicy::READ_ROLES
  MANAGE_ROLES = CustomerPolicy::MANAGE_ROLES

  def show?
    read_current_organization? && same_organization?
  end

  def create?
    manage_current_organization? && same_organization?
  end

  def update?
    manage_current_organization? && same_organization?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless Current.organization
      return scope.where(organization: Current.organization) if user.founder?

      membership = user.memberships.active.find_by(organization: Current.organization)
      return scope.none unless membership&.membership_roles&.where(role: READ_ROLES)&.exists?

      scope.where(organization: Current.organization)
    end
  end

  private

  def read_current_organization?
    current_organization.present? && (founder? || current_membership_has_any_role?(READ_ROLES))
  end

  def manage_current_organization?
    current_organization.present? && (founder? || current_membership_has_any_role?(MANAGE_ROLES))
  end

  def current_membership_has_any_role?(roles)
    current_membership&.membership_roles&.where(role: roles)&.exists?
  end
end
