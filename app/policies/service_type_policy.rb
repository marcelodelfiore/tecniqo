class ServiceTypePolicy < ApplicationPolicy
  READ_ROLES = %w[administrator supervisor engineer].freeze
  MANAGE_ROLES = %w[administrator supervisor].freeze

  def index?
    read?
  end

  def show?
    read? && same_organization?
  end

  def create?
    manage?
  end

  def update?
    manage? && same_organization?
  end

  def activate?
    update? && !record.active?
  end

  def deactivate?
    update? && record.active?
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

  def read?
    current_organization.present? && (founder? || current_membership_has_role?(READ_ROLES))
  end

  def manage?
    current_organization.present? && (founder? || current_membership_has_role?(MANAGE_ROLES))
  end

  def current_membership_has_role?(roles)
    current_membership&.membership_roles&.where(role: roles)&.exists?
  end
end
