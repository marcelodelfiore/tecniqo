class AuthMailer < ApplicationMailer
  def magic_link(user, raw_token)
    @user = user
    @magic_link = magic_session_url(token: raw_token)

    mail to: user.email, subject: "Your sign-in link"
  end
end
