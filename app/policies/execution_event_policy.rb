class ExecutionEventPolicy < ApplicationPolicy
  def create?
    ExecutionPolicy.new(user, record.execution).perform_event?
  end
end
