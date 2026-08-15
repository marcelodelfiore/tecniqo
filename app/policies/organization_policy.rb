class OrganizationPolicy < ApplicationPolicy
  def select?
    founder? || user.memberships.active.exists?(organization: record)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user.founder?

      scope.joins(:memberships)
           .where(memberships: { user_id: user.id, active: true })
           .distinct
    end
  end
end
