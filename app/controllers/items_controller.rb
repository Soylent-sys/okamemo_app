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
    @item = Item.new(item_params)
    if @item.save
      flash[:notice] = "アイテム登録が完了しました。"
      redirect_to items_url
    else
      @categories = Category.all
      render "new", status: :unprocessable_entity
    end
  end

  def edit
    @categories = Category.all
    @item = current_user.items.find_by_hashid(params[:hashid])
    if @item.blank?
      flash[:error] = "指定されたアイテムは存在しません。"
      redirect_to items_url
    end
  end

  def update
    @item = current_user.items.find_by_hashid!(params[:hashid])
    if @item.update(update_item_params)
      flash[:notice] = "アイテムの更新が完了しました。"
      redirect_to items_url
    else
      @categories = Category.all
      render "edit", status: :unprocessable_entity
    end
  end

  def destroy
    item = current_user.items.find_by_hashid!(params[:hashid])
    item.destroy!
    flash[:notice] = "アイテムが削除されました。"
    redirect_to items_url
  end

  private

  def item_params
    params.require(:item).permit(:category_id, :name, :hiragana).merge(user_id: current_user.id)
  end

  def update_item_params
    params.require(:item).permit(:category_id, :name, :hiragana)
  end
end
