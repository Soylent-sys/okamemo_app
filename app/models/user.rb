class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  include Hashid::Rails

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
end
