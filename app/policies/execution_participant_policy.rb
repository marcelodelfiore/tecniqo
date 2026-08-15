class ExecutionParticipantPolicy < ApplicationPolicy
  def create?
    ExecutionPolicy.new(user, record.execution).add_participant?
  end

  def destroy?
    ExecutionPolicy.new(user, record.execution).remove_participant?
  end

  class EligibleScope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless Current.organization
      return eligible_memberships if user.founder?

      membership = user.memberships.active.find_by(organization: Current.organization)
      return scope.none unless membership&.membership_roles&.where(role: WorkOrderPolicy::MANAGE_ROLES)&.exists?

      eligible_memberships
    end

    private

    def eligible_memberships
      scope.technicians.where(organization: Current.organization).includes(:user).order("users.email")
    end
  end
end
