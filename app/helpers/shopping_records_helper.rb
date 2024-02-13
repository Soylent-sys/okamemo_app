module ShoppingRecordsHelper
  CATEGORY_FIRST_ID = 1

  def categoy_items(category)
    category_items = category.items.where(user_id: [User.master_admin_user.id, current_user.id])
    if category.id == CATEGORY_FIRST_ID
      category_items
    else
      category_items.sorted
    end
  end

  def shopping_title(shopping_record_form)
    if shopping_record_form.title.blank?
      "#{Date.today.to_fs(:date_ja)}のお買い物"
    else
      shopping_record_form.title
    end
  end

  def last_bought_day(item)
    last_bought_day = current_user.buys.purchased.where(item_name: item.name).
      order(updated_at: :desc).pick(:updated_at)

    if last_bought_day.blank?
      "購入記録なし"
    elsif Date.current.all_day.cover? last_bought_day
      "今日購入しています"
    elsif Date.yesterday.all_day.cover? last_bought_day
      "昨日購入しています"
    elsif Date.current - 7.day < last_bought_day.to_date
      "#{(Date.current - last_bought_day.to_date).to_i}日前に購入"
    else
      "#{last_bought_day.to_fs(:date_ymd)} 購入"
    end
  end

  def wish_items(shopping_record_form)
    shopping_record_form.hashids.map do |item_hashid|
      Item.find_by_hashid!(item_hashid)
    end
  end

  def bought_items(shopping_record_form)
    shopping_record_form.hashids.map do |buy_hashid|
      Buy.find_by_hashid!(buy_hashid)
    end
  end

  def no_bought_items(shopping_record_form)
    shopping_record = current_user.shopping_records.find_by_hashid!(shopping_record_form.shopping_record_id)
    if shopping_record_form.hashids.present?
      buy_item_ids = shopping_record_form.hashids.map do |buy_hashid|
        Buy.find_by_hashid!(buy_hashid).id
      end
      shopping_record.buys.where.not(id: buy_item_ids)
    else
      shopping_record.buys
    end
  end
end
