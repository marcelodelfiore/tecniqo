class InvitationsController < ApplicationController
  layout "guest", only: %i[show update]

  before_action :require_authentication, only: %i[index new create resend destroy]
  before_action :set_managed_invitation, only: %i[resend destroy]
  after_action :verify_policy_scoped, only: %i[index resend destroy]
  after_action :verify_authorized, only: %i[index new create resend destroy]

  def index
    authorize Invitation
    @invitations = policy_scope(Invitation).active.order(created_at: :desc)
  end

  def new
    authorize Invitation
    @invitation = Current.organization.invitations.new
  end

  def create
    authorize Invitation
    invitation, raw_token = Invitation.issue_for!(
      organization: Current.organization,
      email: invitation_params[:email],
      roles: invitation_params[:roles],
      invited_by: Current.user
    )
    InvitationMailer.organization_invitation(invitation, raw_token).deliver_later

    redirect_to invitations_path, notice: "Invitation sent."
  rescue ActiveRecord::RecordInvalid => error
    @invitation = error.record
    render :new, status: :unprocessable_content
  end

  def resend
    authorize @invitation, :resend?
    invitation, raw_token = Invitation.issue_for!(
      organization: Current.organization,
      email: @invitation.email,
      roles: @invitation.roles,
      invited_by: Current.user
    )
    InvitationMailer.organization_invitation(invitation, raw_token).deliver_later

    redirect_to invitations_path, notice: "Invitation resent."
  end

  def destroy
    authorize @invitation
    @invitation.revoke!

    redirect_to invitations_path, notice: "Invitation revoked."
  end

  def show
    @raw_token = params[:token].to_s
    @invitation = Invitation.find_active(@raw_token)

    unless @invitation
      return redirect_to new_session_path, alert: "That invitation is invalid or expired."
    end

    response.headers["Cache-Control"] = "no-store"
    response.headers["Referrer-Policy"] = "no-referrer"
  end

  def update
    result = Invitation.accept(params[:token].to_s)

    unless result
      return redirect_to new_session_path, alert: "That invitation is invalid or expired."
    end

    _invitation, user = result
    reset_session
    session[:user_id] = user.id
    user.update!(last_seen_at: Time.current)

    redirect_to dashboard_path, notice: "Invitation accepted."
  end

  private

  def set_managed_invitation
    @invitation = policy_scope(Invitation).find_by(id: params[:id])
    raise Pundit::NotAuthorizedError unless @invitation
  end

  def invitation_params
    params.expect(invitation: [ :email, roles: [] ])
  end
end
