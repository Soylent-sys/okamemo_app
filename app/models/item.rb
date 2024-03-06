class Item < ApplicationRecord
  include Hashid::Rails

  belongs_to :user
  belongs_to :category

  scope :sorted, -> { order(:category_id, :hiragana) }
  scope :preset, -> { where(user_id: User.master_admin_user.id) }

  MAX_LENGTH_NAME = 20
  MAX_LENGTH_HIRAGANA = 20
  VALID_HIRAGANA_REGEX = /\A[ぁ-んー－]+\z/

  validates :name, presence: true, uniqueness: { scope: [:user_id, :category_id], message: "は同じカテゴリーの中で二つ以上登録できません。" },
                   length: { maximum: MAX_LENGTH_NAME }
  validates :hiragana, presence: true, uniqueness: { scope: [:user_id, :category_id], message: "は同じカテゴリーの中で二つ以上登録できません。" },
                       length: { maximum: MAX_LENGTH_HIRAGANA },
                       format: { with: VALID_HIRAGANA_REGEX, message: "の項目はひらがなで入力してください。" }
  # 管理ユーザーで登録したデフォルトアイテムと同じ内容の登録を制御するバリデーション
  validate :same_preset_item

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
end
