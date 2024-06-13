class Management::ShoppingRecordsController < ApplicationController
  include Pagy::Backend

  SHOPPING_RECORDS_PAGENATION_SIZE = 50

  def index
    @pagy, @shopping_records = pagy(ShoppingRecord.all, items: SHOPPING_RECORDS_PAGENATION_SIZE, size: [1, 2, 2, 1])
  end

  def show
  end

  def destroy
    shopping_record = ShoppingRecord.find(params[:id])
    shopping_record.destroy!
    flash[:notice] = "お買い物の削除が完了しました。"
    redirect_to management_shopping_records_url
  end
end
