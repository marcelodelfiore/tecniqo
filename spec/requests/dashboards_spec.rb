require 'rails_helper'

RSpec.describe 'Dashboard', type: :request do
  def sign_in(user)
    _login_token, raw_token = LoginToken.issue_for!(user)
    post consume_magic_session_path(token: raw_token)
  end

  describe 'GET /dashboard' do
    it 'redirects guests to the login page' do
      get dashboard_path

      expect(response).to redirect_to(new_session_path)

      follow_redirect!
      expect(response.body).to include('Please sign in to continue.')
    end

    it 'allows authenticated users to access the dashboard' do
      user = create(:user)
      membership = create(:membership, user: user)

      sign_in(user)
      get dashboard_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(membership.organization.name)
    end

    it 'renders successfully for authenticated users' do
      user = create(:user)
      create(:membership, user: user)

      sign_in(user)
      get dashboard_path

      expect(response.body).to include('Dashboard')
    end

    it 'does not allow access after logout' do
      user = create(:user)
      create(:membership, user: user)

      sign_in(user)
      delete session_path

      get dashboard_path

      expect(response).to redirect_to(new_session_path)
    end

    it 'requires an organization choice when several active memberships exist' do
      user = create(:user)
      create_list(:membership, 2, user: user)

      sign_in(user)
      get dashboard_path

      expect(response).to redirect_to(organization_selection_path)
    end

    it 'rejects a selected organization after its membership becomes inactive' do
      user = create(:user)
      membership = create(:membership, user: user)
      remaining_membership = create(:membership, user: user)
      sign_in(user)
      patch organization_selection_path, params: { organization_id: membership.organization_id }

      membership.update!(active: false)
      get dashboard_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(remaining_membership.organization.name)
      expect(response.body).not_to include(membership.organization.name)
    end
  end
end
