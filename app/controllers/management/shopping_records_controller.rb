class Management::ShoppingRecordsController < ApplicationController
  include Pagy::Backend

  SHOPPING_RECORDS_PAGENATION_SIZE = 50

  def index
    @pagy, @shopping_records = pagy(ShoppingRecord.all, items: SHOPPING_RECORDS_PAGENATION_SIZE, size: [1, 2, 2, 1])
  end

  def show
  end

  def destroy
  end
end
