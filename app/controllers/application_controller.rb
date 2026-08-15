class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  around_action :switch_locale
  before_action :set_current_user
  before_action :set_current_organization

  rescue_from Pundit::NotAuthorizedError, with: :handle_unauthorized_access

  helper_method :authenticated?

  private

  def switch_locale(&action)
    available_locales = I18n.available_locales.map(&:to_s)
    requested_locale = params[:locale].to_s.presence_in(available_locales)
    session[:locale] = requested_locale if requested_locale
    locale = session[:locale].presence_in(available_locales) || I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  def reset_session_preserving_locale
    locale = session[:locale]
    reset_session
    session[:locale] = locale if locale
  end

  def pundit_user
    Current.user
  end

  def set_current_user
    Current.user = User.find_by(id: session[:user_id])
  end

  def set_current_organization
    Current.organization = nil
    return unless Current.user

    available_organizations = OrganizationPolicy::Scope.new(Current.user, Organization.all).resolve
    Current.organization = available_organizations.find_by(id: session[:organization_id])

    if Current.organization
      return
    elsif session[:organization_id]
      session.delete(:organization_id)
    end

    organizations = available_organizations.limit(2).to_a
    return unless organizations.one?

    Current.organization = organizations.first
    session[:organization_id] = Current.organization.id
  end

  def handle_unauthorized_access
    redirect_to organization_selection_path, alert: t("flash.authorization.denied")
  end

  def authenticated?
    Current.user.present?
  end

  def require_authentication
    return if authenticated?

    redirect_to new_session_path, alert: t("flash.authentication.required")
  end

  def redirect_if_authenticated
    return unless authenticated?

    redirect_to dashboard_path, notice: t("flash.authentication.already_signed_in")
  end
end
