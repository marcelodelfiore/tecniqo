require "rails_helper"

RSpec.describe "Sessions", type: :request do
  def sign_in(user)
    _login_token, raw_token = LoginToken.issue_for!(user)
    post consume_magic_session_path(token: raw_token)
  end

  before do
    Rails.cache.clear
    clear_enqueued_jobs
  end

  describe "GET /login" do
    it "renders successfully for a guest" do
      get new_session_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("email")
    end

    it "redirects an authenticated user away from the login page" do
      sign_in(create(:user))

      get new_session_path

      expect(response).to redirect_to(dashboard_path)
    end
  end

  describe "POST /session" do
    it "returns unprocessable content when email is blank" do
      post session_path, params: { email: "   " }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Please enter your email.")
    end

    it "does not create a user when the normalized email does not exist" do
      expect do
        post session_path, params: { email: "  NEW_USER@EXAMPLE.COM  " }
      end.not_to change(User, :count)

      expect(User.find_by(email: "new_user@example.com")).to be_nil
    end

    it "does not create a duplicate user" do
      create(:user, email: "marcelo@example.com")

      expect do
        post session_path, params: { email: "  MARCELO@EXAMPLE.COM  " }
      end.not_to change(User, :count)
    end

    it "issues a login token and enqueues its email for a known user" do
      user = create(:user, email: "mailer_test@example.com")
      create(:membership, user: user)

      expect do
        post session_path, params: { email: "mailer_test@example.com" }
      end.to change(LoginToken, :count).by(1)
        .and have_enqueued_mail(AuthMailer, :magic_link)
    end

    it "does not issue a token or email for an unknown user" do
      expect do
        post session_path, params: { email: "unknown@example.com" }
      end.not_to change(LoginToken, :count)

      expect(enqueued_jobs).to be_empty
    end

    it "does not issue a token for a legacy user without membership history" do
      create(:user, email: "orphan@example.com")

      expect do
        post session_path, params: { email: "orphan@example.com" }
      end.not_to change(LoginToken, :count)
    end

    it "allows a Founder to sign in without a membership" do
      create(:user, email: "founder@example.com", founder: true)

      expect do
        post session_path, params: { email: "founder@example.com" }
      end.to change(LoginToken, :count).by(1)
    end

    it "redirects back to the login page without revealing account existence" do
      post session_path, params: { email: "notice_test@example.com" }

      expect(response).to redirect_to(new_session_path)
      follow_redirect!
      expect(response.body).to include("Check your email for your sign-in link.")
    end

    it "redirects an authenticated user without issuing another token" do
      sign_in(create(:user))

      expect do
        post session_path, params: { email: "another@example.com" }
      end.not_to change(LoginToken, :count)

      expect(response).to redirect_to(dashboard_path)
    end

    it "limits repeated requests for the same normalized email" do
      3.times do
        post session_path, params: { email: "limited@example.com" }
        Rails.cache.delete_matched("rate-limit:sessions:ip:*")
      end

      post session_path, params: { email: "  LIMITED@EXAMPLE.COM " }

      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to eq("Too many attempts. Try again later.")
    end
  end

  describe "GET /session/:token" do
    it "shows confirmation without consuming the token or signing in" do
      login_token, raw_token = LoginToken.issue_for!(create(:user))

      get magic_session_path(token: raw_token)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Confirm sign in")
      expect(response.headers["Cache-Control"]).to eq("no-store")
      expect(response.headers["Referrer-Policy"]).to eq("no-referrer")
      expect(login_token.reload).not_to be_used

      get dashboard_path
      expect(response).to redirect_to(new_session_path)
    end

    it "rejects an invalid or expired token" do
      get magic_session_path(token: "not-a-real-token")
      expect(response).to redirect_to(new_session_path)

      login_token, raw_token = LoginToken.issue_for!(create(:user))
      login_token.update!(expires_at: 1.minute.ago)

      get magic_session_path(token: raw_token)
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "POST /session/:token" do
    it "consumes a valid token and signs the user in" do
      user = create(:user, last_seen_at: nil)
      create(:membership, user: user)
      login_token, raw_token = LoginToken.issue_for!(user)

      expect do
        post consume_magic_session_path(token: raw_token)
      end.to change { user.reload.last_seen_at }.from(nil)

      expect(response).to redirect_to(dashboard_path)
      expect(login_token.reload).to be_used

      get dashboard_path
      expect(response).to have_http_status(:ok)
    end

    it "rejects a reused token" do
      _login_token, raw_token = LoginToken.issue_for!(create(:user))

      post consume_magic_session_path(token: raw_token)
      delete session_path
      post consume_magic_session_path(token: raw_token)

      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to eq("That sign-in link is invalid or expired.")
    end
  end

  describe "DELETE /session" do
    it "logs out an authenticated user" do
      sign_in(create(:user))

      delete session_path

      expect(response).to redirect_to(root_path)
      get dashboard_path
      expect(response).to redirect_to(new_session_path)
    end

    it "behaves safely when no user is signed in" do
      delete session_path

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("Signed out successfully.")
    end
  end
end
