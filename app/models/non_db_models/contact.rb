class Contact
  include ActiveModel::Model
  include UserSharedConstants

  attr_accessor :name, :email, :subject, :message

  MAX_LENGTH_SUBJECT = 50
  MAX_LENGTH_MESSAGE = 500

  validates :name, presence: true, length: { maximum: MAX_LENGTH_NAME }
  validates :email, presence: true, length: { maximum: MAX_LENGTH_EMAIL }, format: { with: VALID_EMAIL_REGEX }
  validates :subject, presence: true, length: { maximum: MAX_LENGTH_SUBJECT }
  validates :message, presence: true, length: { maximum: MAX_LENGTH_MESSAGE }
end
