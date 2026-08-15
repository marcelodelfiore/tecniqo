require "rails_helper"

RSpec.describe InvitationMailer, type: :mailer do
  describe ".organization_invitation" do
    it "addresses the invitee and includes the confirmation URL" do
      invitation = build_stubbed(
        :invitation,
        email: "person@example.com",
        organization: build_stubbed(:organization, name: "Técniqo Services")
      )
      mail = described_class.organization_invitation(invitation, "raw-token")

      expect(mail.to).to eq([ "person@example.com" ])
      expect(mail.subject).to eq("You're invited to Técniqo Services")
      expect(mail.text_part.body.decoded).to include(invitation_acceptance_url(token: "raw-token"))
    end
  end
end
