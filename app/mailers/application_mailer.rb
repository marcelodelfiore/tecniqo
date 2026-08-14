class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "Base App <no-reply@example.com>")
  layout "mailer"
end
