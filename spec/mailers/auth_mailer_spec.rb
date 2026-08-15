require "rails_helper"

RSpec.describe AuthMailer, type: :mailer do
  describe ".magic_link" do
    it "addresses the user and includes the confirmation URL" do
      user = build_stubbed(:user, email: "person@example.com")
      mail = described_class.magic_link(user, "raw-token")

      expect(mail.to).to eq([ "person@example.com" ])
      expect(mail.subject).to eq("Your sign-in link")
      expect(mail.body.encoded).to include(magic_session_url(token: "raw-token", locale: :en))
    end

    it "renders in the requested locale" do
      user = build_stubbed(:user, email: "person@example.com")
      mail = described_class.with(locale: "pt-BR").magic_link(user, "raw-token")

      expect(mail.subject).to eq("Seu link de acesso")
      expect(mail.text_part.body.decoded).to include("Este link expira em 15 minutos")
      expect(mail.text_part.body.decoded).to include("locale=pt-BR")
    end
  end
end
