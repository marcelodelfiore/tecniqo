class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    raise Pundit::NotAuthorizedError, "authentication required" unless user

    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  class Scope
    def initialize(user, scope)
      raise Pundit::NotAuthorizedError, "authentication required" unless user

      @user = user
      @scope = scope
    end

    def resolve
      scope.none
    end

    private

    attr_reader :user, :scope
  end
end
