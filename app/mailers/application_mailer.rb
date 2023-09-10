class ApplicationMailer < ActionMailer::Base
  default from: "no-reply@okamemo.com"
  layout "mailer"
end
