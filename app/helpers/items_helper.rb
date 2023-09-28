module ItemsHelper
  def current_user_create_items(category)
    current_user.items.where(category_id: category.id)
  end
end
