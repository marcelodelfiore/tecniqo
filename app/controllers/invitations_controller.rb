class InvitationsController < ApplicationController
  layout "guest"

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
end
