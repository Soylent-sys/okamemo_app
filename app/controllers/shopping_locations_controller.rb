class ShoppingLocationsController < ApplicationController
  before_action :authenticate_user!

  def new
    @shopping_record = current_user.shopping_records.closed.find_by_hashid(params[:hashid])
    if @shopping_record.blank?
      flash[:error] = "指定されたお買い物履歴は存在しません。"
      redirect_to shopping_result_group_url
      return
    end

    if @shopping_record.shopping_location.blank?
      @shopping_location = ShoppingLocation.new
      # テスト環境の場合はビューのスクリプトにテスト用の処理を追加するため
      gon.env = Rails.env
    else
      # 場所登録済みの場合は編集(edit)にリダイレクトする
      redirect_to edit_shopping_location_url(@shopping_record.hashid)
    end
  end

  def create
    # paramsで渡されたshopping_record.hashidからshopping_recordを取得する
    shopping_record = current_user.shopping_records.closed.find_by_hashid!(shopping_location_params[:shopping_record_hashid])
    # 緯度経度はparamsのまま、shopping_record_idだけは上で取得したshopping_recordのidを使用してnewする
    new_shopping_location = ShoppingLocation.new(shopping_record_id: shopping_record.id,
                                                 latitude: shopping_location_params[:latitude],
                                                 longitude: shopping_location_params[:longitude])
    if new_shopping_location.save
      flash[:notice] = "お買い物場所が登録されました。"
      redirect_to shopping_results_url(shopping_record.hashid)
    else
      flash[:error] = "処理中に問題が発生しました。本ページから再度登録・編集してください。"
      redirect_to shopping_results_url(shopping_record.hashid)
    end
  end

  def edit
    @shopping_record = current_user.shopping_records.closed.find_by_hashid(params[:hashid])
    if @shopping_record.blank?
      flash[:error] = "指定されたお買い物場所の記録は存在しません。"
      redirect_to shopping_result_group_url
      return
    end

    @shopping_location = @shopping_record.shopping_location
    if @shopping_location.blank?
      flash[:error] = "指定されたお買い物場所の記録は存在しません。"
      redirect_to shopping_result_group_url
      return
    end

    gon.lat = @shopping_location.latitude
    gon.lng = @shopping_location.longitude
    # テスト環境の場合はビューのスクリプトにテスト用の処理を追加するため
    gon.env = Rails.env
  end

  def update
    shopping_location = ShoppingLocation.find_by_hashid!(params[:hashid])
    shopping_location.update!(update_shopping_location_params)
    flash[:notice] = "お買い物場所が更新されました。"
    redirect_to shopping_results_url(shopping_location.shopping_record.hashid)
  end

  def destroy
    shopping_location = ShoppingLocation.find_by_hashid!(params[:hashid])
    shopping_record = shopping_location.shopping_record
    shopping_location.destroy!
    flash[:notice] = "お買い物場所が削除されました。"
    redirect_to shopping_results_url(shopping_record.hashid)
  end

  private

  def shopping_location_params
    params.require(:shopping_location).permit(:shopping_record_hashid, :latitude, :longitude)
  end

  def update_shopping_location_params
    params.require(:shopping_location).permit(:latitude, :longitude)
  end
end
