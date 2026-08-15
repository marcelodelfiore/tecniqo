class InvitationMailer < ApplicationMailer
  def organization_invitation(invitation, raw_token)
    I18n.with_locale(params[:locale].presence || I18n.default_locale) do
      @invitation = invitation
      @accept_url = invitation_acceptance_url(token: raw_token, locale: I18n.locale)

      mail to: invitation.email,
           subject: t("mailers.invitation.subject", organization: invitation.organization.name)
    end
  end
end
