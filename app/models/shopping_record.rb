class ShoppingRecord < ApplicationRecord
  belongs_to :user
  has_one :shopping_location, dependent: :delete
  has_many :buys, dependent: :delete_all
end
