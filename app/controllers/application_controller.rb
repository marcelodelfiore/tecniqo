class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :set_current_user

  helper_method :authenticated?

  private

  def set_current_user
    Current.user = User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def authenticated?
    Current.user.present?
  end

  def require_authentication
    return if authenticated?

    redirect_to new_session_path, alert: "Please sign in to continue."
  end

  def redirect_if_authenticated
    return unless authenticated?

    redirect_to dashboard_path, notice: "You are already signed in."
  end
end
