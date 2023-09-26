class Category < ApplicationRecord
  has_many :items, dependent: :delete_all

  MAX_LENGTH_NAME = 20
  MAX_LENGTH_HIRAGANA = 20

  validates :name, presence: true, uniqueness: true, length: { maximum: MAX_LENGTH_NAME }
  validates :hiragana, presence: true, uniqueness: true, length: { maximum: MAX_LENGTH_HIRAGANA }
end
