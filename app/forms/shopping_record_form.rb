class ShoppingRecordForm
  include ActiveModel::Model

  attr_accessor :shopping_record_hashid, :user_id, :title, :hashids

  HASHIDS_MINIMUM_SIZE = 1
  HASHIDS_MAXIMUM_SIZE = 20
  SHOPPING_REGISTRATION_MAXIMUM_COUNT = 5
  GUEST_SHOPPING_MAXIMUM_COUNT = 20

  validates :title, presence: true, length: { maximum: ShoppingRecord::MAX_LENGTH_TITLE }
  validates :hashids, length: {
    in: HASHIDS_MINIMUM_SIZE..HASHIDS_MAXIMUM_SIZE,
    too_short: "は#{HASHIDS_MINIMUM_SIZE} つ以上選択してください。",
    too_long: "のチェック数が#{HASHIDS_MAXIMUM_SIZE} 個を超えています。",
  }
  validate :check_count
  validate :guest_check_count

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
      shopping_record = ShoppingRecord.find_by_hashid!(shopping_record_hashid)
      if hashids.present?
        hashids.each do |buy_hashid|
          buy = shopping_record.buys.find_by_hashid!(buy_hashid)
          buy.update!(purchased: true)
        end
      end
      shopping_record.update!(closed: true)
    end
  end

  private

  def check_count
    if ShoppingRecord.opened.where(user_id: user_id).count >= SHOPPING_REGISTRATION_MAXIMUM_COUNT
      errors.add(:shopping_record, "の登録数が最大数（#{SHOPPING_REGISTRATION_MAXIMUM_COUNT}つ）に達しています。")
    end
  end

  def guest_check_count
    user = User.find(user_id)
    return unless user.guest?

    if ShoppingRecord.where(user_id: user.id).count >= GUEST_SHOPPING_MAXIMUM_COUNT
      errors.add(:base, "ゲストユーザーが登録できるお買い物は履歴を含めて#{GUEST_SHOPPING_MAXIMUM_COUNT}件までです。新しく登録する場合は登録済みのお買い物またはお買い物履歴を削除してください。")
    end
  end
end
