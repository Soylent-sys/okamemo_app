class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  has_many :items, dependent: :delete_all
  has_many :buys, dependent: :delete_all
  has_many :shopping_records, dependent: :destroy

  MAX_LENGTH_EMAIL = 255
  MAX_LENGTH_NAME = 20
  VALID_PASSWORD_REGEX = /\A(?=.*?[a-z])(?=.*?[\d])[a-z\d]+\z/i

  validates :email, length: { maximum: MAX_LENGTH_EMAIL }
  validates :password, format: { with: VALID_PASSWORD_REGEX }, on: :create
  validates :password, format: { with: VALID_PASSWORD_REGEX }, allow_blank: true, on: :update
  validates :name, presence: true, length: { maximum: MAX_LENGTH_NAME }

  class << self
    def master_admin_user
      User.find_by!(email: "#{ENV['ADMIN_USER_EMAIL']}")
    end
  end
end
