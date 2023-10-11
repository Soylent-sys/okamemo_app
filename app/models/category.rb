class Category < ApplicationRecord
  has_many :items, dependent: :delete_all

  MAX_LENGTH_NAME = 20
  MAX_LENGTH_HIRAGANA = 20

  validates :name, presence: true, uniqueness: true, length: { maximum: MAX_LENGTH_NAME }
  validates :hiragana, presence: true, uniqueness: true, length: { maximum: MAX_LENGTH_HIRAGANA }

  class << self
    def created_item_categories(current_user_id)
      all_categories = Category.all
      user = User.find(current_user_id)
      all_categories.filter_map do |category|
        category if user.items.where(category_id: category.id).present?
      end
    end
  end
end
