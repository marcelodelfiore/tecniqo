class MembershipsController < ApplicationController
  before_action :require_authentication
  before_action :set_membership, only: %i[edit update]
  after_action :verify_policy_scoped
  after_action :verify_authorized

  def index
    authorize Membership
    @memberships = policy_scope(Membership).joins(:user).includes(:user, :membership_roles).order("users.email")
  end

  def edit
    authorize @membership
  end

  def update
    authorize @membership
    @membership.update_access!(active: membership_params[:active], roles: membership_params[:roles])

    redirect_to memberships_path, notice: t("flash.memberships.updated")
  rescue Membership::LastAdministratorError
    flash.now[:alert] = t("flash.memberships.last_administrator")
    render :edit, status: :unprocessable_content
  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = t("flash.memberships.invalid_roles")
    render :edit, status: :unprocessable_content
  end

  private

  def set_membership
    @membership = policy_scope(Membership).find_by(id: params[:id])
    raise Pundit::NotAuthorizedError unless @membership
  end

  def membership_params
    params.expect(membership: [ :active, roles: [] ])
  end
end
