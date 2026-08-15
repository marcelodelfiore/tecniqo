class InvitationPolicy < ApplicationPolicy
  def index?
    manage?
  end

  def create?
    manage?
  end

  def resend?
    manage? && same_organization? && record.active?
  end

  def destroy?
    manage? && same_organization? && record.active?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless Current.organization
      return scope.where(organization: Current.organization) if user.founder?

      membership = user.memberships.active.find_by(organization: Current.organization)
      return scope.none unless membership&.membership_roles&.exists?(role: "administrator")

      scope.where(organization: Current.organization)
    end
  end

  private

  def manage?
    current_organization.present? &&
      (founder? || current_membership&.membership_roles&.exists?(role: "administrator"))
  end
end
