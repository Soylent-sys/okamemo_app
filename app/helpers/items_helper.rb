module ItemsHelper
  CATEGORY_FIRST_ID = 1

  # current_userが登録したアイテムのみを取得し「おまとめ」カテゴリー以外をソートする
  def my_items(category)
    items = category.items.where(user_id: current_user.id)
    if category.id == CATEGORY_FIRST_ID
      items
    else
      items.sorted
    end
  end
end
