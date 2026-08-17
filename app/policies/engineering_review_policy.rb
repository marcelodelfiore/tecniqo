class EngineeringReviewPolicy < ApplicationPolicy
  VIEW_ROLES = %w[administrator supervisor engineer].freeze

  def index?
    current_organization.present? && (founder? || engineer?)
  end

  def show?
    same_organization? && (founder? || current_membership&.membership_roles&.where(role: VIEW_ROLES)&.exists?)
  end

  def start?
    same_organization? && record.state == "pending" && (founder? || engineer?)
  end

  def request_clarification?
    same_organization? && record.state == "in_review" && record.reviewer?(user)
  end

  def resolve_clarification?
    same_organization? && record.state == "changes_requested" && record.reviewer?(user)
  end

  def approve?
    same_organization? && record.state == "in_review" && record.reviewer?(user)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless Current.organization

      tenant_scope = scope.where(organization: Current.organization)
      return tenant_scope if user.founder?

      membership = user.memberships.active.find_by(organization: Current.organization)
      return scope.none unless membership&.membership_roles&.where(role: VIEW_ROLES)&.exists?

      tenant_scope
    end
  end

  private

  def engineer?
    current_membership&.membership_roles&.exists?(role: "engineer")
  end
end
