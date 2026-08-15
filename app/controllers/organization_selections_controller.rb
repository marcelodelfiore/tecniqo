class OrganizationSelectionsController < ApplicationController
  layout "guest"

  before_action :require_authentication
  after_action :verify_policy_scoped
  after_action :verify_authorized, only: :update

  def show
    @organizations = policy_scope(Organization).order(:name)
  end

  def update
    organizations = policy_scope(Organization)
    organization = organizations.find_by(id: params[:organization_id])
    raise Pundit::NotAuthorizedError unless organization

    authorize organization, :select?

    session[:organization_id] = organization.id
    Current.organization = organization

    redirect_to dashboard_path, notice: t("flash.organizations.selected")
  end
end
