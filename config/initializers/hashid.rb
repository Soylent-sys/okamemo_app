Hashid::Rails.configure do |config|
  config.salt = ENV["HASHID_SALT_CHAR"]
  config.min_hash_length = 10
  config.alphabet = "abcdefghijklmnopqrstuvwxyz" \
  "1234567890"
end
