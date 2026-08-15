class InvitationMailer < ApplicationMailer
  def organization_invitation(invitation, raw_token)
    @invitation = invitation
    @accept_url = invitation_url(token: raw_token)

    mail to: invitation.email,
         subject: "You're invited to #{invitation.organization.name}"
  end
end
