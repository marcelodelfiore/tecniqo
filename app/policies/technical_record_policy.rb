class TechnicalRecordPolicy < ApplicationPolicy
  def show?
    ExecutionPolicy.new(user, record.execution).show?
  end

  def create?
    editable_participant?
  end

  def update?
    editable_participant?
  end

  def destroy?
    editable_participant?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless Current.organization

      execution_ids = ExecutionPolicy::Scope.new(user, Execution.all).resolve.select(:id)
      scope.where(organization: Current.organization, execution_id: execution_ids)
    end
  end

  private

  def editable_participant?
    record.execution && !record.execution.submitted? &&
      ExecutionPolicy.new(user, record.execution).perform_event?
  end
end
