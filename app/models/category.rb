class Category < ApplicationRecord
  has_many :items, dependent: :delete_all

  MAX_LENGTH_NAME = 20
  MAX_LENGTH_HIRAGANA = 20

  validates :name, presence: true, uniqueness: true, length: { maximum: MAX_LENGTH_NAME }
  validates :hiragana, presence: true, uniqueness: true, length: { maximum: MAX_LENGTH_HIRAGANA }

  class << self
    # ユーザーが登録したアイテムのカテゴリーのみを取得
    def created_item_categories(current_user_id)
      joins(:items).where(items: { user_id: current_user_id }).distinct.order(:id)
    end

    # ransackでの検索・ソートが可能なカラム、アソシエーションのホワイトリスト
    def ransackable_attributes(auth_object = nil)
      ["name"]
    end

    def ransackable_associations(auth_object = nil)
      []
    end
  end
end
