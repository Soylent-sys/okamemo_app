class ShoppingRecord < ApplicationRecord
  include Hashid::Rails

  belongs_to :user
  has_one :shopping_location, dependent: :delete
  has_many :buys, dependent: :delete_all

  scope :opened, -> { where(closed: false) }
  scope :closed, -> { where(closed: true) }
  scope :recent_updated, -> { order(updated_at: :desc) }

  MAX_LENGTH_TITLE = 40

  validates :title, presence: true, length: { maximum: MAX_LENGTH_TITLE }

  class << self
    def first_record_by_month(user)
      shopping_record_month_grouping = grouping_closed_and_date_ym(user)
      if shopping_record_month_grouping.present?
        month_group_first_record_ids = shopping_record_month_grouping.map { |month_group| month_group.second[0].id }
        ShoppingRecord.where(id: month_group_first_record_ids)
      else
        ShoppingRecord.none
      end
    end

    def extract_one_month(user, date)
      shopping_record_month_grouping = grouping_closed_and_date_ym(user)
      if shopping_record_month_grouping[date].present?
        one_month_record_ids = shopping_record_month_grouping[date].map { |record| record.id }
        ShoppingRecord.where(id: one_month_record_ids)
      else
        ShoppingRecord.none
      end
    end

    # ransackでの検索・ソートが可能なカラム、アソシエーションのホワイトリスト
    def ransackable_attributes(auth_object = nil)
      ["id", "user_id", "title", "closed", "created_at", "updated_at"]
    end

    def ransackable_associations(auth_object = nil)
      ["shopping_location"]
    end

    private

    def grouping_closed_and_date_ym(user)
      user.shopping_records.closed.group_by { |record| record.updated_at.to_fs(:date_ym) }
    end
  end
end
