class Buy < ApplicationRecord
  belongs_to :user
  belongs_to :shopping_record
end
