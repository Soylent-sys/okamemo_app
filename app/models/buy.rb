class Buy < ApplicationRecord
  include Hashid::Rails

  belongs_to :user
  belongs_to :shopping_record

  scope :purchased, -> { where(purchased: true) }
end
