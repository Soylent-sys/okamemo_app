class ShoppingLocation < ApplicationRecord
  include Hashid::Rails

  belongs_to :shopping_record

  validates :shopping_record_id, presence: true, uniqueness: true
  validates :latitude, presence: true, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
  validates :longitude, presence: true, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }

  class << self
    # ransackでの検索・ソートが可能なカラム、アソシエーションのホワイトリスト
    def ransackable_attributes(auth_object = nil)
      ["id"]
    end

    def ransackable_associations(auth_object = nil)
      []
    end
  end
end
