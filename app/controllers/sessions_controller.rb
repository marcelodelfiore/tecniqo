class SessionsController < ApplicationController
  layout "guest"

  before_action :redirect_if_authenticated, only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create, name: "ip",
             with: -> { redirect_to new_session_path, alert: t("flash.authentication.rate_limited") }
  rate_limit to: 3, within: 15.minutes, only: :create, name: "email",
             by: -> { params[:email].to_s.strip.downcase },
             with: -> { redirect_to new_session_path, alert: t("flash.authentication.rate_limited") }

  def new
  end

  def create
    email = params[:email].to_s.strip.downcase

    if email.blank?
      flash.now[:alert] = t("flash.authentication.email_required")
      return render :new, status: :unprocessable_content
    end

    user = User.find_by(email: email)
    user = nil unless user&.founder? || user&.memberships&.exists?

    if user
      _login_token, raw_token = LoginToken.issue_for!(user)
      AuthMailer.with(locale: I18n.locale.to_s).magic_link(user, raw_token).deliver_later
    end

    redirect_to new_session_path, notice: t("flash.authentication.email_sent")
  end

  def show
    @raw_token = params[:token].to_s
    login_token = LoginToken.find_active(@raw_token)

    unless login_token
      return redirect_to new_session_path, alert: t("flash.authentication.invalid_link")
    end

    response.headers["Cache-Control"] = "no-store"
    response.headers["Referrer-Policy"] = "no-referrer"
  end

  def update
    login_token = LoginToken.consume(params[:token].to_s)

    unless login_token
      return redirect_to new_session_path, alert: t("flash.authentication.invalid_link")
    end

    reset_session_preserving_locale
    session[:user_id] = login_token.user_id
    login_token.user.update!(last_seen_at: Time.current)

    redirect_to dashboard_path, notice: t("flash.authentication.signed_in")
  end

  def destroy
    reset_session_preserving_locale
    redirect_to root_path, notice: t("flash.authentication.signed_out")
  end
end
