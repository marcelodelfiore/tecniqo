require "rails_helper"

RSpec.describe "Invitation management", type: :request do
  def sign_in(user)
    _login_token, raw_token = LoginToken.issue_for!(user)
    post consume_magic_session_path(token: raw_token)
  end

  def create_administrator(active: true)
    membership = create(:membership, active: active)
    create(:membership_role, membership: membership, role: "administrator")
    membership
  end

  describe "GET /invitations" do
    it "redirects guests to sign in" do
      get invitations_path

      expect(response).to redirect_to(new_session_path)
    end

    it "renders current-organization pending invitations for an Administrator" do
      membership = create_administrator
      pending = create(:invitation, organization: membership.organization)
      create(:invitation, organization: membership.organization, accepted_at: Time.current)
      create(:invitation)
      sign_in(membership.user)

      get invitations_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Invitations", pending.email, "Resend", "Revoke")
    end

    it "renders an empty state" do
      membership = create_administrator
      sign_in(membership.user)

      get invitations_path

      expect(response.body).to include("No pending invitations")
    end

    it "denies a non-Administrator" do
      membership = create(:membership)
      create(:membership_role, membership: membership, role: "supervisor")
      sign_in(membership.user)

      get invitations_path

      expect(response).to redirect_to(organization_selection_path)
    end

    it "allows a Founder within the selected organization" do
      organization = create(:organization)
      founder = create(:user, founder: true)
      invitation = create(:invitation, organization: organization)
      sign_in(founder)

      get invitations_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(invitation.email)
    end
  end

  describe "GET /invitations/new" do
    it "renders the email and fixed-role form for an Administrator" do
      membership = create_administrator
      sign_in(membership.user)

      get new_invitation_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Invite member", "Administrator", "Supervisor", "Technician", "Engineer")
    end

    it "safely denies an authenticated user without an active organization" do
      membership = create_administrator(active: false)
      sign_in(membership.user)

      get new_invitation_path

      expect(response).to redirect_to(organization_selection_path)
    end
  end

  describe "POST /invitations" do
    it "issues and delivers an invitation with selected roles" do
      membership = create_administrator
      sign_in(membership.user)

      expect do
        post invitations_path, params: {
          invitation: { email: " New.Member@Example.com ", roles: %w[technician engineer] }
        }
      end.to change(Invitation, :count).by(1)
        .and have_enqueued_mail(InvitationMailer, :organization_invitation)

      invitation = Invitation.order(:created_at).last
      expect(invitation.organization).to eq(membership.organization)
      expect(invitation.invited_by).to eq(membership.user)
      expect(invitation.email).to eq("new.member@example.com")
      expect(invitation.roles).to match_array(%w[technician engineer])
    end

    it "renders validation errors without delivering" do
      membership = create_administrator
      sign_in(membership.user)

      expect do
        post invitations_path, params: { invitation: { email: "invalid", roles: [] } }
      end.not_to change(Invitation, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Email is invalid", "Roles must contain at least one valid role")
    end

    it "denies a non-Administrator" do
      membership = create(:membership)
      create(:membership_role, membership: membership, role: "engineer")
      sign_in(membership.user)

      expect do
        post invitations_path, params: {
          invitation: { email: "invited@example.com", roles: [ "technician" ] }
        }
      end.not_to change(Invitation, :count)

      expect(response).to redirect_to(organization_selection_path)
    end
  end

  describe "POST /invitations/:id/resend" do
    it "revokes the old invitation, issues a replacement, and delivers it" do
      membership = create_administrator
      invitation = create(:invitation, organization: membership.organization)
      sign_in(membership.user)

      expect do
        post resend_invitation_path(invitation)
      end.to change(Invitation, :count).by(1)
        .and have_enqueued_mail(InvitationMailer, :organization_invitation)

      expect(invitation.reload.revoked_at).to be_present
      expect(response).to redirect_to(invitations_path)
    end

    it "does not expose another organization's invitation" do
      membership = create_administrator
      inaccessible = create(:invitation)
      sign_in(membership.user)

      expect { post resend_invitation_path(inaccessible) }.not_to change(Invitation, :count)
      expect(response).to redirect_to(organization_selection_path)
    end
  end

  describe "DELETE /invitations/:id" do
    it "revokes rather than deletes the invitation" do
      membership = create_administrator
      invitation = create(:invitation, organization: membership.organization)
      sign_in(membership.user)

      expect do
        delete invitation_path(invitation)
      end.not_to change(Invitation, :count)

      expect(invitation.reload.revoked_at).to be_present
      expect(response).to redirect_to(invitations_path)
    end
  end
end
