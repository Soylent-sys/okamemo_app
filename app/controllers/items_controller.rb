class ItemsController < ApplicationController
  before_action :authenticate_user!

  def index
    @categories = Category.created_item_categories(current_user.id)
  end

  def new
    @categories = Category.all
    @item = Item.new
  end

  def create
    @categories = Category.all
    @item = Item.new(item_params)
    if @item.save
      flash[:notice] = "アイテム登録が完了しました。"
      redirect_to items_url
    else
      render 'new', status: :unprocessable_entity
    end
  end

  def edit
    @categories = Category.all
    @item = current_user.items.find_by_hashid(params[:id])
    if @item.blank?
      flash[:error] = "指定されたアイテムは存在しません。"
      redirect_to items_url
    end
  end

  def update
    @categories = Category.all
    @item = current_user.items.find_by_hashid!(params[:id])
    item_params.delete(:user_id)
    if @item.update(item_params)
      flash[:notice] = "アイテムの更新が完了しました。"
      redirect_to items_url
    else
      render 'edit', status: :unprocessable_entity
    end
  end

  def destroy
    item = current_user.items.find_by_hashid!(params[:id])
    item.destroy
    flash[:notice] = "アイテムが削除されました。"
    redirect_to items_url
  end

  private

  def item_params
    params.require(:item).permit(:category_id, :name, :hiragana).merge(user_id: current_user.id)
  end
end
