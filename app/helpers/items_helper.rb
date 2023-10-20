module ItemsHelper
  CATEGORY_FIRST_ID = 1

  def my_items(category)
    items = category.items.where(user_id: current_user.id)
    if category.id == CATEGORY_FIRST_ID
      items
    else
      items.sorted
    end
  end
end
