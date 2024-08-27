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

  EMAIL_CONFIRMATION_LIMIT = 10
  NOTIFICATION_TARGET_USER_MUXIMUM_COUNT = 3

  validates :email, presence: true, uniqueness: { scope: [:user_id, :email], message: "は既に登録されています。" },
                    length: { maximum: MAX_LENGTH_EMAIL }, format: { with: VALID_EMAIL_REGEX }
  validates :name,  presence: true, length: { maximum: MAX_LENGTH_NAME }
  validate :check_count, on: :create

  class << self
    # トークンを生成（DB上で重複した場合は再生成）
    def confirmation_new_token
      loop do
        token = SecureRandom.urlsafe_base64(47)
        break token unless NotificationTargetUser.exists?(confirmation_token: token)
      end
    end

    # ransackでの検索・ソートが可能なカラム、アソシエーションのホワイトリスト
    def ransackable_attributes(auth_object = nil)
      ["id", "user_id", "name", "email", "created_at", "updated_at"]
    end

    def ransackable_associations(auth_object = nil)
      []
    end
  end

  # メール認証の有効期限判定
  def expired?
    expiration_date.present? ? expiration_date < Time.current : false
  end

  # 通知ユーザーの有効化
  def activate
    status = NotificationTargetUser.confirmation_statuses[:confirmed]
    update!(
      confirmation_status: status,
      confirmation_token: nil,
      expiration_date: nil,
    )
  end

  # メール認証項目（トークン、有効期限）の再設定
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

  # 未認証の通知ユーザーのメール認証項目（トークン、有効期限）を設定
  def set_email_confirmation
    if unconfirmed?
      self.confirmation_token = NotificationTargetUser.confirmation_new_token
      self.expiration_date = Time.current + EMAIL_CONFIRMATION_LIMIT.minutes
    end
  end

  # 通知ユーザー登録数の制限
  def check_count
    if NotificationTargetUser.where(user_id: user_id).count >= NOTIFICATION_TARGET_USER_MUXIMUM_COUNT
      errors.add(:notification_target_user, "の登録数が最大数（#{NOTIFICATION_TARGET_USER_MUXIMUM_COUNT}つ）に達しています。")
    end
  end
end
