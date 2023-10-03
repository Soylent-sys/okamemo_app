class ItemsController < ApplicationController
  before_action :set_categories, only: [:index, :new, :create, :edit, :update]

  def index
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
    @item = Item.find(params[:id])
  end

  def update
    @item = Item.find(params[:id])
    if @item.update(item_params)
      flash[:notice] = "アイテムの更新が完了しました。"
      redirect_to items_url
    else
      render 'edit', status: :unprocessable_entity
    end
  end

  private

  def set_categories
    @categories = Category.all
  end

  def item_params
    params.require(:item).permit(:user_id, :category_id, :name, :hiragana)
  end
end
