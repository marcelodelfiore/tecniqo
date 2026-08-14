require 'rails_helper'

RSpec.describe 'Dashboard', type: :request do
  describe 'GET /dashboard' do
    it 'redirects guests to the login page' do
      get dashboard_path

      expect(response).to redirect_to(new_session_path)

      follow_redirect!
      expect(response.body).to include('Please sign in to continue.')
    end

    it 'allows authenticated users to access the dashboard' do
      user = create(:user)
      _login_token, raw_token = LoginToken.issue_for!(user)

      post consume_magic_session_path(token: raw_token)
      get dashboard_path

      expect(response).to have_http_status(:ok)
    end

    it 'renders successfully for authenticated users' do
      user = create(:user)
      _login_token, raw_token = LoginToken.issue_for!(user)

      post consume_magic_session_path(token: raw_token)
      get dashboard_path

      expect(response.body).to include('Dashboard')
    end

    it 'does not allow access after logout' do
      user = create(:user)
      _login_token, raw_token = LoginToken.issue_for!(user)

      post consume_magic_session_path(token: raw_token)
      delete session_path

      get dashboard_path

      expect(response).to redirect_to(new_session_path)
    end
  end
end
