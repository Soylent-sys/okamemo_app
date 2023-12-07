class ShoppingRecordsController < ApplicationController
  include Pagy::Backend

  before_action :authenticate_user!
  before_action :set_all_categories, only: [:new, :confirm, :back_new, :create]

  INDEX_PAGENATION_SIZE = 5

  def index
    @pagy, @shopping_records = pagy(current_user.shopping_records.opened, items: INDEX_PAGENATION_SIZE, size: [1, 1, 1, 1])
  end

  def new
    @shopping_record_form = ShoppingRecordForm.new
  end

  def confirm
    @shopping_record_form = ShoppingRecordForm.new(shopping_record_params)
    if @shopping_record_form.valid?
      render 'confirm', status: :see_other
    else
      render 'new', status: :unprocessable_entity
    end
  end

  def back_new
    @shopping_record_form = ShoppingRecordForm.new(shopping_record_params)
    render 'new', status: :see_other
  end

  def create
    shopping_record_form = ShoppingRecordForm.new(create_shopping_record_params)
    shopping_record_form.save
    flash[:notice] = "お買い物が登録されました。"
    redirect_to root_url
  end

  def edit
    @shopping_record = current_user.shopping_records.find_by_hashid(params[:id])
    if @shopping_record.blank?
      flash[:error] = "指定されたお買い物は存在しません。"
      redirect_to shopping_index_url
    elsif @shopping_record.closed?
      flash[:error] = "指定されたお買い物は終了しています。"
      redirect_to shopping_index_url
    end
    @shopping_record_form = ShoppingRecordForm.new
  end

  def edit_confirm
    @shopping_record = set_shopping_record_from_post
    @shopping_record_form = set_shopping_record_form_from_post
    render 'edit_confirm', status: :see_other
  end

  def back_edit
    @shopping_record = set_shopping_record_from_post
    @shopping_record_form = set_shopping_record_form_from_post
    render 'edit', status: :see_other
  end

  def update
    shopping_record_form = set_shopping_record_form_from_post
    shopping_record_form.update_shopping_record
    flash[:notice] = "お買い物が完了しました。"
    redirect_to root_url
  end

  def destroy
    shopping_record = current_user.shopping_records.find_by_hashid!(params[:id])
    shopping_record.destroy!
    flash[:notice] = "お買い物が削除されました。"
    redirect_to shopping_index_url
  end

  private

  def set_all_categories
    @categories = Category.all
  end

  def shopping_record_params
    params.require(:shopping_record_form).permit(:title, hashids: [])
  end

  def create_shopping_record_params
    params.require(:shopping_record_form).permit(:title, hashids: []).merge(user_id: current_user.id)
  end

  def update_shopping_record_params
    params.require(:shopping_record_form).permit(:shopping_record_id, hashids: [])
  end

  def set_shopping_record_from_post
    current_user.shopping_records.find_by_hashid!(update_shopping_record_params[:shopping_record_id])
  end

  def set_shopping_record_form_from_post
    ShoppingRecordForm.new(update_shopping_record_params)
  end
end
