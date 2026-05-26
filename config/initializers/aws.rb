creds = Aws::Credentials.new(ENV["SES_AWS_ACCESS_KEY_ID"], ENV["SES_AWS_SECRET_ACCESS_KEY"])

Aws::Rails.add_action_mailer_delivery_method(
  :ses,
  credentials: creds,
  region: "ap-northeast-1",
)
