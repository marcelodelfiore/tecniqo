class AuthMailer < ApplicationMailer
  def magic_link(user, raw_token)
    I18n.with_locale(params[:locale].presence || I18n.default_locale) do
      @user = user
      @magic_link = magic_session_url(token: raw_token, locale: I18n.locale)

      mail to: user.email, subject: t("mailers.auth.subject")
    end
  end
end
