class ShoppingRecordsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_all_categories, only: [:new, :confirm, :back_new, :create]

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
end
