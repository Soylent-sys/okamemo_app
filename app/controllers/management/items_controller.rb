class Management::ItemsController < ApplicationController
  include Pagy::Backend

  ITEMS_PAGENATION_SIZE = 50

  def index
    @q = Item.ransack(params[:q])
    @pagy, @items = pagy(@q.result.includes(:category), items: ITEMS_PAGENATION_SIZE, size: [1, 2, 2, 1])
  end

  def new
    @categories = Category.all
    @item = Item.new
  end

  def create
    @item = Item.new(item_params)
    if @item.save
      flash[:notice] = "アイテムの登録が完了しました。"
      redirect_to management_items_url
    else
      @categories = Category.all
      render 'new', status: :unprocessable_entity
    end
  end

  def edit
    @categories = Category.all
    @item = Item.find(params[:id])
  end

  def update
    @item = Item.find(params[:id])
    if @item.update(update_item_params)
      flash[:notice] = "アイテムの更新が完了しました。"
      redirect_to management_items_url
    else
      @categories = Category.all
      render 'edit', status: :unprocessable_entity
    end
  end

  def destroy
    item = Item.find(params[:id])
    item.destroy!
    flash[:notice] = "アイテムの削除が完了しました。"
    redirect_to management_items_url
  end

  private

  def item_params
    params.require(:item).permit(:user_id, :category_id, :name, :hiragana)
  end

  def update_item_params
    params.require(:item).permit(:category_id, :name, :hiragana)
  end
end
