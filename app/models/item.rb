class Item < ApplicationRecord
  belongs_to :user
  belongs_to :category

  MAX_LENGTH_NAME = 20
  MAX_LENGTH_HIRAGANA = 20
  VALID_HIRAGANA_REGEX = /\A[ぁ-んー－]+\z/

  validates :name, presence: true, uniqueness: { scope: [:user_id, :category_id], message: "は同じカテゴリーの中で二つ以上登録できません。" },
                   length: { maximum: MAX_LENGTH_NAME }
  validates :hiragana, presence: true, uniqueness: { scope: [:user_id, :category_id], message: "は同じカテゴリーの中で二つ以上登録できません。" },
                       length: { maximum: MAX_LENGTH_HIRAGANA },
                       format: { with: VALID_HIRAGANA_REGEX, message: "の項目はひらがなで入力してください。" }
end
