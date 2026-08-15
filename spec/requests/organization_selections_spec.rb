require "rails_helper"

RSpec.describe "Organization selection", type: :request do
  def sign_in(user)
    _login_token, raw_token = LoginToken.issue_for!(user)
    post consume_magic_session_path(token: raw_token)
  end

  describe "GET /organization_selection" do
    it "redirects guests to sign in" do
      get organization_selection_path

      expect(response).to redirect_to(new_session_path)
    end

    it "shows only organizations from active memberships" do
      user = create(:user)
      active_membership = create(:membership, user: user)
      inactive_membership = create(:membership, user: user, active: false)
      other_organization = create(:organization)
      sign_in(user)

      get organization_selection_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(active_membership.organization.name)
      expect(response.body).not_to include(inactive_membership.organization.name)
      expect(response.body).not_to include(other_organization.name)
    end

    it "shows every organization to a Founder" do
      founder = create(:user, founder: true)
      organizations = create_list(:organization, 2)
      sign_in(founder)

      get organization_selection_path

      expect(response.body).to include(*organizations.map(&:name))
    end

    it "explains when no active organization is available" do
      user = create(:user)
      create(:membership, user: user, active: false)
      sign_in(user)

      get organization_selection_path

      expect(response.body).to include("does not have access to an active organization")
    end
  end

  describe "PATCH /organization_selection" do
    it "selects an organization from an active membership" do
      user = create(:user)
      membership = create(:membership, user: user)
      create(:membership, user: user)
      sign_in(user)

      patch organization_selection_path, params: { organization_id: membership.organization_id }
      get dashboard_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(membership.organization.name)
    end

    it "does not select an organization belonging to another user" do
      user = create(:user)
      create(:membership, user: user)
      create(:membership, user: user)
      inaccessible_organization = create(:organization)
      sign_in(user)

      patch organization_selection_path, params: { organization_id: inaccessible_organization.id }

      expect(response).to redirect_to(organization_selection_path)
      expect(flash[:alert]).to eq("You are not authorized to access that organization.")
    end

    it "does not select an organization from an inactive membership" do
      user = create(:user)
      inactive_membership = create(:membership, user: user, active: false)
      sign_in(user)

      patch organization_selection_path, params: { organization_id: inactive_membership.organization_id }

      expect(response).to redirect_to(organization_selection_path)
    end

    it "allows a Founder to select an organization without a membership" do
      founder = create(:user, founder: true)
      organization = create(:organization)
      create(:organization)
      sign_in(founder)

      patch organization_selection_path, params: { organization_id: organization.id }
      get dashboard_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(organization.name)
    end
  end
end
