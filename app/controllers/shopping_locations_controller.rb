class ShoppingLocationsController < ApplicationController
  before_action :authenticate_user!

  def new
    @shopping_record = current_user.shopping_records.closed.find_by_hashid(params[:id])
    if @shopping_record.blank?
      flash[:error] = "指定されたお買い物履歴は存在しません。"
      redirect_to shopping_result_url
    end

    @shopping_location = ShoppingLocation.new
  end

  def create
    shopping_record = current_user.shopping_records.closed.find_by_hashid!(shopping_location_params[:shopping_record_id])
    # shopping_location_params の shopping_record_id を hashid から id に変換する
    sl_params = shopping_location_params
    sl_params[:shopping_record_id] = shopping_record.id
    ShoppingLocation.new(sl_params).save!
    flash[:notice] = "お買い物場所が登録されました。"
    redirect_to shopping_results_url(shopping_record.hashid)
  end

  private

  def shopping_location_params
    params.require(:shopping_location).permit(:shopping_record_id, :latitude, :longitude)
  end
end
