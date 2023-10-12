Hashid::Rails.configure do |config|
  config.salt = "#{ENV['HASHID_SALT_CHAR']}"
end
