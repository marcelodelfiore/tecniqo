class SessionsController < ApplicationController
  layout "guest"

  before_action :redirect_if_authenticated, only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create, name: "ip",
             with: -> { redirect_to new_session_path, alert: "Too many attempts. Try again later." }
  rate_limit to: 3, within: 15.minutes, only: :create, name: "email",
             by: -> { params[:email].to_s.strip.downcase },
             with: -> { redirect_to new_session_path, alert: "Too many attempts. Try again later." }

  def new
  end

  def create
    email = params[:email].to_s.strip.downcase

    if email.blank?
      flash.now[:alert] = "Please enter your email."
      return render :new, status: :unprocessable_content
    end

    user = User.find_or_create_by!(email: email)

    _login_token, raw_token = LoginToken.issue_for!(user)
    AuthMailer.magic_link(user, raw_token).deliver_later

    redirect_to new_session_path, notice: "Check your email for your sign-in link."
  end

  def show
    @raw_token = params[:token].to_s
    login_token = LoginToken.find_active(@raw_token)

    unless login_token
      return redirect_to new_session_path, alert: "That sign-in link is invalid or expired."
    end

    response.headers["Cache-Control"] = "no-store"
    response.headers["Referrer-Policy"] = "no-referrer"
  end

  def update
    login_token = LoginToken.consume(params[:token].to_s)

    unless login_token
      return redirect_to new_session_path, alert: "That sign-in link is invalid or expired."
    end

    reset_session
    session[:user_id] = login_token.user_id
    login_token.user.update!(last_seen_at: Time.current)

    redirect_to dashboard_path, notice: "Signed in successfully."
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "Signed out successfully."
  end
end
