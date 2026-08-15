class EvidencePolicy < ApplicationPolicy
  def show?
    ExecutionPolicy.new(user, record.execution).show?
  end

  def create?
    same_organization? && !record.execution.submitted? &&
      ExecutionPolicy.new(user, record.execution).perform_event?
  end

  def download?
    show?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless Current.organization

      execution_ids = ExecutionPolicy::Scope.new(user, Execution.all).resolve.select(:id)
      scope.where(organization: Current.organization, execution_id: execution_ids)
    end
  end
end
