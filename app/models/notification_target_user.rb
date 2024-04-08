class NotificationTargetUser < ApplicationRecord
  include Hashid::Rails
  include UserSharedConstants

  belongs_to :user

  scope :old_created, -> { order(created_at: :asc) }

  enum confirmation_status: {
    unconfirmed: 0,
    confirmed: 1,
  }

  before_save :downcase_email
  before_create :set_email_confirmation

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  EMAIL_CONFIRMATION_LIMIT = 10.minutes
  NOTIFICATION_TARGET_USER_MUXIMUM_COUNT = 3

  validates :email, presence: true, uniqueness: { scope: [:user_id, :email], message: "は既に登録されています。" },
                    length: { maximum: MAX_LENGTH_EMAIL }, format: { with: VALID_EMAIL_REGEX }
  validates :name,  presence: true, length: { maximum: MAX_LENGTH_NAME }
  validate :check_count, on: :create

  class << self
    def confirmation_new_token
      loop do
        token = SecureRandom.urlsafe_base64(47)
        break token unless NotificationTargetUser.exists?(confirmation_token: token)
      end
    end
  end

  def expired?
    expiration_date.present? ? expiration_date < Time.zone.now : false
  end

  def activate
    status = NotificationTargetUser.confirmation_statuses[:confirmed]
    update!(
      confirmation_status: status,
      confirmation_token: nil,
      expiration_date: nil,
    )
  end

  def reset_email_confirmation
    set_email_confirmation
    update!(
      confirmation_token:,
      expiration_date:,
    )
  end

  private

  def downcase_email
    email.downcase!
  end

  def set_email_confirmation
    self.confirmation_token = NotificationTargetUser.confirmation_new_token
    self.expiration_date = Time.zone.now + EMAIL_CONFIRMATION_LIMIT
  end

  def check_count
    if NotificationTargetUser.where(user_id: user_id).count >= NOTIFICATION_TARGET_USER_MUXIMUM_COUNT
      errors.add(:notification_target_user, "の登録数が最大数（#{NOTIFICATION_TARGET_USER_MUXIMUM_COUNT}つ）に達しています。")
    end
  end
end
