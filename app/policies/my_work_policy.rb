class MyWorkPolicy < ApplicationPolicy
  def show?
    membership = current_membership
    current_organization.present? && membership&.membership_roles&.exists?(role: "technician")
  end
end
