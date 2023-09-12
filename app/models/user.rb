class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  MAX_LENGTH_EMAIL = 255
  MAX_LENGTH_NAME = 20
  VALID_PASSWORD_REGEX = /\A(?=.*?[a-z])(?=.*?[\d])[a-z\d]+\z/i.freeze

  validates :email, length: { maximum: MAX_LENGTH_EMAIL }
  validates :password, format: { with: VALID_PASSWORD_REGEX }
  validates :name, presence: true, length: { maximum: MAX_LENGTH_NAME }
end
