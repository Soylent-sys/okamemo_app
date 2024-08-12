class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  include UserSharedConstants

  before_update :prevent_master_admin_change
  before_update :prevent_guest_change
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

    # ゲストユーザーを作成または取得するメソッド
    def guest
      User.find_or_create_by!(email: 'guest@example.com') do |user|
        user.password = generate_guest_password
        user.name = "ゲストユーザー"
        user.confirmed_at = Time.current
      end
    end

    # ransackでの検索・ソートが可能なカラム、アソシエーションのホワイトリスト
    def ransackable_attributes(auth_object = nil)
      ["id", "admin", "email", "name", "hiragana_view", "confirmed_at", "created_at", "updated_at"]
    end

    def ransackable_associations(auth_object = nil)
      []
    end

    private

    # ゲストユーザーのパスワードを生成する
    def generate_guest_password
      loop do
        password = SecureRandom.urlsafe_base64
        return password if password.match?(VALID_PASSWORD_REGEX)
      end
    end
  end

  # マスター管理ユーザーかどうかを返す
  def master_admin_user?
    self == User.master_admin_user
  end

  # ゲストユーザーかどうかを返す
  def guest?
    self == User.guest
  end

  # ユーザー編集で現在のパスワード入力を省略する（deviseのupdate_resourceのオーバーライド）
  def update_without_current_password(params)
    params.delete(:current_password)

    if params[:password].blank?
      params.delete(:password)
      params.delete(:password_confirmation) if params[:password_confirmation].blank?
    end

    result = update(params)
    clean_up_passwords
    result
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

    if will_save_change_to_unconfirmed_email?
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

  # ゲストユーザーアカウントの権限とメールアドレスの変更制御
  def prevent_guest_change
    return unless guest?

    changes_detected = false

    if will_save_change_to_admin?
      errors.add(:admin, "は変更できません。ゲストユーザーの権限変更は制限されています。")
      changes_detected = true
    end

    if will_save_change_to_name?
      errors.add(:name, "は変更できません。ゲストユーザーのニックネーム変更は制限されています。")
      changes_detected = true
    end

    if will_save_change_to_email?
      errors.add(:email, "は変更できません。ゲストユーザーのメールアドレス変更は制限されています。")
      changes_detected = true
    end

    if will_save_change_to_unconfirmed_email?
      errors.add(:email, "は変更できません。ゲストユーザーのメールアドレス変更は制限されています。")
      changes_detected = true
    end

    if will_save_change_to_encrypted_password?
      errors.add(:password, "は変更できません。ゲストユーザーのパスワード変更は制限されています。")
      changes_detected = true
    end

    throw(:abort) if changes_detected
  end
end
