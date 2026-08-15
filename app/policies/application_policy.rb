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

  private

  def founder?
    user.founder?
  end

  def current_organization
    Current.organization
  end

  def current_membership
    return unless current_organization

    user.memberships.active.find_by(organization: current_organization)
  end

  def same_organization?
    current_organization && record.respond_to?(:organization_id) &&
      record.organization_id == current_organization.id
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
