class ClarificationRequestPolicy < ApplicationPolicy
  def show?
    same_organization? && (review_visible? || recipient?)
  end

  def create?
    EngineeringReviewPolicy.new(user, record.engineering_review).request_clarification?
  end

  def respond?
    same_organization? && record.state == "requested" && recipient?
  end

  def add_evidence?
    same_organization? && record.state.in?(%w[requested responded]) && recipient?
  end

  def resolve?
    record.state == "responded" &&
      EngineeringReviewPolicy.new(user, record.engineering_review).resolve_clarification?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless Current.organization

      tenant_scope = scope.where(organization: Current.organization)
      return tenant_scope if user.founder?

      membership = user.memberships.active.find_by(organization: Current.organization)
      return scope.none unless membership
      return tenant_scope if membership.membership_roles
                                       .where(role: EngineeringReviewPolicy::VIEW_ROLES).exists?

      tenant_scope.where(recipient_membership: membership)
    end
  end

  private

  def review_visible?
    EngineeringReviewPolicy.new(user, record.engineering_review).show?
  end

  def recipient?
    record.recipient_membership_id == current_membership&.id &&
      current_membership&.membership_roles&.exists?(role: "technician")
  end
end
