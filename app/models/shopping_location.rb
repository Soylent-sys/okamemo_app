class ShoppingLocation < ApplicationRecord
  include Hashid::Rails

  belongs_to :shopping_record

  validates :shopping_record_id, presence: true, uniqueness: true
  validates :latitude, presence: true
  validates :longitude, presence: true
end
