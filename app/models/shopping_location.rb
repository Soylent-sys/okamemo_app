class ShoppingLocation < ApplicationRecord
  include Hashid::Rails

  belongs_to :shopping_record

  validates :shopping_record_id, presence: true, uniqueness: true
  validates :latitude, presence: true
  validates :longitude, presence: true

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
