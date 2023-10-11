class ItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_all_categories, only: [:new, :create, :edit, :update]

  def index
    @categories = Category.created_item_categories(current_user.id)
  end

  def new
    @item = Item.new
  end

  def create
    @item = Item.new(item_params)
    if @item.save
      flash[:notice] = "アイテム登録が完了しました。"
      redirect_to items_url
    else
      render 'new', status: :unprocessable_entity
    end
  end

  def edit
    @item = current_user.items.find_by(id: params[:id])
    if @item.blank?
      flash[:error] = "指定されたアイテムは存在しません。"
      redirect_to items_url
    end
  end

  def update
    @item = current_user.items.find(params[:id])
    item_params.delete(:user_id)
    if @item.update(item_params)
      flash[:notice] = "アイテムの更新が完了しました。"
      redirect_to items_url
    else
      render 'edit', status: :unprocessable_entity
    end
  end

  def destroy
    @item = current_user.items.find(params[:id])
    @item.destroy
    flash[:notice] = "アイテムが削除されました。"
    redirect_to items_url
  end

  private

  def set_all_categories
    @categories = Category.all
  end

  def item_params
    params.require(:item).permit(:user_id, :category_id, :name, :hiragana)
  end
end
