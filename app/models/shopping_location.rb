class ShoppingLocation < ApplicationRecord
  include Hashid::Rails

  belongs_to :shopping_record
end
