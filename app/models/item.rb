class Item < ApplicationRecord
  include Hashid::Rails

  belongs_to :user
  belongs_to :category

  scope :sorted, -> { order(:category_id, :hiragana) }
  scope :preset, -> { where(user_id: User.master_admin_user.id) }

  MAX_LENGTH_NAME = 20
  MAX_LENGTH_HIRAGANA = 20
  VALID_HIRAGANA_REGEX = /\A[ぁ-んー－]+\z/
  GUEST_ITEM_MAXIMUM_COUNT = 10

  validates :name, presence: true, uniqueness: { scope: [:user_id, :category_id], message: "は同じカテゴリーの中で二つ以上登録できません。" },
                   length: { maximum: MAX_LENGTH_NAME }
  validates :hiragana, presence: true, uniqueness: { scope: [:user_id, :category_id], message: "は同じカテゴリーの中で二つ以上登録できません。" },
                       length: { maximum: MAX_LENGTH_HIRAGANA },
                       format: { with: VALID_HIRAGANA_REGEX, message: "の項目はひらがなで入力してください。" }
  # 管理ユーザーで登録したデフォルトアイテムと同じ内容の登録を制御するバリデーション
  validate :same_preset_item
  validate :guest_check_count

  class << self
    # ransackでの検索・ソートが可能なカラム、アソシエーションのホワイトリスト
    def ransackable_attributes(auth_object = nil)
      ["id", "user_id", "category_id", "name", "hiragana", "created_at", "updated_at"]
    end

    def ransackable_associations(auth_object = nil)
      ["category"]
    end
  end

  private

  def same_preset_item
    preset_items = Item.preset
    same_item_name = preset_items.find do |item|
      item[:category_id].eql?(category_id) && item[:name].eql?(name)
    end
    if same_item_name.present?
      errors.add(:name, "が同じカテゴリーに存在するデフォルトアイテムと重複しています。")
    end

    same_item_hiragana = preset_items.find do |item|
      item[:category_id].eql?(category_id) && item[:hiragana].eql?(hiragana)
    end
    if same_item_hiragana.present?
      errors.add(:hiragana, "が同じカテゴリーに存在するデフォルトアイテムと重複しています。")
    end
  end

  # ゲストユーザーのアイテム登録は10件まで
  def guest_check_count
    user = User.find(user_id)
    return unless user.guest?

    if Item.where(user_id: user.id).count >= GUEST_ITEM_MAXIMUM_COUNT
      errors.add(:base, "ゲストユーザーが登録できるアイテムは#{GUEST_ITEM_MAXIMUM_COUNT}個までです。新しく登録する場合は登録済みアイテムを削除してください。")
    end
  end
end
