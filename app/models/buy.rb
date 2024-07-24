class Buy < ApplicationRecord
  include Hashid::Rails

  belongs_to :user
  belongs_to :shopping_record

  scope :purchased, -> { where(purchased: true) }
  scope :unpurchased, -> { where(purchased: false) }

  validates :item_name, presence: true
  validates :item_hiragana, presence: true
end
