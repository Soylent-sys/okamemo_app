class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  include UserSharedConstants

  before_update :prevent_master_admin_change
  before_destroy :prevent_master_admin_delete

  has_many :items, dependent: :delete_all
  has_many :buys, dependent: :delete_all
  has_many :shopping_records, dependent: :destroy
  has_many :notification_target_users, dependent: :delete_all

  VALID_PASSWORD_REGEX = /\A(?=.*?[a-z])(?=.*?[\d])[a-z\d]+\z/i

  validates :email, length: { maximum: MAX_LENGTH_EMAIL }
  validates :password, format: { with: VALID_PASSWORD_REGEX }, on: :create
  validates :password, format: { with: VALID_PASSWORD_REGEX }, allow_blank: true, on: :update
  validates :name, presence: true, length: { maximum: MAX_LENGTH_NAME }

  class << self
    def master_admin_user
      User.find_by!(email: "#{ENV['ADMIN_USER_EMAIL']}")
    end

    # ransackでの検索・ソートが可能なカラム、アソシエーションのホワイトリスト
    def ransackable_attributes(auth_object = nil)
      ["id", "admin", "email", "name", "hiragana_view", "confirmed_at", "created_at", "updated_at"]
    end

    def ransackable_associations(auth_object = nil)
      []
    end
  end

  def master_admin_user?
    self == User.master_admin_user
  end

  private

  # マスター管理ユーザーアカウントの権限とメールアドレスの変更制御
  def prevent_master_admin_change
    return unless master_admin_user?

    changes_detected = false

    if will_save_change_to_admin?
      errors.add(:admin, "は変更できません。マスター管理ユーザーの権限変更は制限されています。")
      changes_detected = true
    end

    if will_save_change_to_email?
      errors.add(:email, "は変更できません。マスター管理ユーザーのメールアドレス変更は制限されています。")
      changes_detected = true
    end

    throw(:abort) if changes_detected
  end

  # マスター管理ユーザーアカウントの削除制御
  def prevent_master_admin_delete
    if master_admin_user?
      errors.add(:base, "マスター管理ユーザーのアカウント削除は制限されています。")
      throw(:abort)
    end
  end
end
