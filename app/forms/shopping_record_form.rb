class ShoppingRecordForm
  include ActiveModel::Model

  attr_accessor :shopping_record_id, :user_id, :title, :hashids

  HASHIDS_MINIMUM_SIZE = 1
  HASHIDS_MAXIMUM_SIZE = 20

  validates :title, presence: true, length: { maximum: ShoppingRecord::MAX_LENGTH_TITLE }
  validates :hashids, length: {
    in: HASHIDS_MINIMUM_SIZE..HASHIDS_MAXIMUM_SIZE,
    too_short: "は#{HASHIDS_MINIMUM_SIZE} つ以上選択してください。",
    too_long: "のチェック数が#{HASHIDS_MAXIMUM_SIZE} 個を超えています。",
  }

  def save
    ActiveRecord::Base.transaction do
      shopping_record = ShoppingRecord.create!(user_id:, title:)
      hashids.each do |item_hashid|
        item = Item.find_by_hashid!(item_hashid)
        Buy.create!(user_id: shopping_record.user_id, shopping_record_id: shopping_record.id,
                    item_name: item.name, item_hiragana: item.hiragana)
      end
    end
  end

  def update_shopping_record
    ActiveRecord::Base.transaction do
      shopping_record = ShoppingRecord.find_by_hashid!(shopping_record_id)
      if hashids.present?
        hashids.each do |buy_hashid|
          buy = shopping_record.buys.find_by_hashid!(buy_hashid)
          buy.update!(purchased: true)
        end
      end
      shopping_record.update!(closed: true)
    end
  end
end
