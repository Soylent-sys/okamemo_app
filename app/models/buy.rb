class Buy < ApplicationRecord
  include Hashid::Rails

  belongs_to :user
  belongs_to :shopping_record

  scope :purchased, -> { where(purchased: true) }
  scope :unpurchased, -> { where(purchased: false) }

  validates :item_name, presence: true
  validates :item_hiragana, presence: true

  class << self
    # ユーザーが過去に購入したアイテム毎の最新更新日を取得
    def last_bought_times(user)
      user.buys.purchased.group(:item_name).maximum(:updated_at)
    end
  end
end
