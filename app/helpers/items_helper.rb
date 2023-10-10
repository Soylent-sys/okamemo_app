module ItemsHelper
  CATEGORY_FIRST_ID = 1

  def current_user_create_items(category)
    items = current_user.items.where(category_id: category.id)
    if category.id == CATEGORY_FIRST_ID
      items
    else
      items.sorted
    end
  end
end
