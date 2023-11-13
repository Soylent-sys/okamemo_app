class ShoppingRecord < ApplicationRecord
  include Hashid::Rails

  belongs_to :user
  has_one :shopping_location, dependent: :delete
  has_many :buys, dependent: :delete_all

  scope :opened, -> { where(closed: false) }
  scope :closed, -> { where(closed: true) }

  MAX_LENGTH_TITLE = 40

  validates :title, presence: true, length: { maximum: MAX_LENGTH_TITLE }
end
