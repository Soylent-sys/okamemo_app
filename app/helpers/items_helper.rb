module ItemsHelper
  # current_userが登録したアイテムのみを取得し「おまとめ」カテゴリー以外をソートする
  def my_items(category)
    items = category.items.where(user_id: current_user.id)
    if category.name == "おまとめ"
      items
    else
      items.sorted
    end
  end
end
