class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "no-reply@sewalink.example.com")
  layout "mailer"
end
