class DashboardPolicy < ApplicationPolicy
  def show?
    current_organization.present? && (founder? || current_membership.present?)
  end
end
