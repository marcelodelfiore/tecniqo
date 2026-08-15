require "rails_helper"

RSpec.describe "Invitations", type: :request do
  describe "GET /invitation" do
    it "shows a valid invitation without accepting it" do
      invitation, raw_token = Invitation.issue_for!(
        organization: create(:organization),
        email: "invited@example.com",
        roles: [ "technician" ],
        invited_by: create(:user)
      )

      get invitation_acceptance_path(token: raw_token)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(invitation.organization.name)
      expect(response.headers["Cache-Control"]).to eq("no-store")
      expect(response.headers["Referrer-Policy"]).to eq("no-referrer")
      expect(invitation.reload.accepted_at).to be_nil
    end

    it "rejects an invalid or expired invitation" do
      get invitation_acceptance_path(token: "invalid")
      expect(response).to redirect_to(new_session_path)

      invitation, raw_token = Invitation.issue_for!(
        organization: create(:organization),
        email: "invited@example.com",
        roles: [ "technician" ],
        invited_by: create(:user)
      )
      invitation.update!(expires_at: 1.minute.ago)

      get invitation_acceptance_path(token: raw_token)
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "POST /invitation" do
    it "accepts the invitation, signs in, and establishes the organization" do
      invitation, raw_token = Invitation.issue_for!(
        organization: create(:organization),
        email: "invited@example.com",
        roles: [ "technician" ],
        invited_by: create(:user)
      )

      post consume_invitation_path, params: { token: raw_token }
      get dashboard_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(invitation.organization.name)
      expect(User.find_by(email: invitation.email).last_seen_at).to be_present
    end

    it "rejects a reused invitation" do
      _invitation, raw_token = Invitation.issue_for!(
        organization: create(:organization),
        email: "invited@example.com",
        roles: [ "technician" ],
        invited_by: create(:user)
      )

      post consume_invitation_path, params: { token: raw_token }
      delete session_path
      post consume_invitation_path, params: { token: raw_token }

      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to eq("That invitation is invalid or expired.")
    end
  end
end
