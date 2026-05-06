module ShoppingRecordsHelper
  # 各カテゴリーのプリセットアイテムとcurrent_userの登録アイテムを取得し「おまとめ」カテゴリ以外をソートする
  def categoy_items(category)
    category_items = category.items.where(user_id: [User.master_admin_user.id, current_user.id])
    if category.name == "おまとめ"
      category_items
    else
      category_items.sorted
    end
  end

  # お買い物登録フォームのタイトルをセット
  def shopping_title(shopping_record_form)
    if shopping_record_form.title.blank?
      "#{Date.today.to_fs(:date_ja)}のお買い物"
    else
      shopping_record_form.title
    end
  end

  # 各アイテムの最終購入日を表示
  def last_bought_day(item)
    last_bought_day = current_user.buys.purchased.where(item_name: item.name).
      order(updated_at: :desc).pick(:updated_at)

    if last_bought_day.blank?
      "購入記録なし"
    elsif Date.current.all_day.cover? last_bought_day
      "今日購入してます"
    elsif Date.yesterday.all_day.cover? last_bought_day
      "昨日購入してます"
    elsif Date.current - 7.day < last_bought_day.to_date
      "#{(Date.current - last_bought_day.to_date).to_i}日前に購入"
    else
      "#{last_bought_day.to_fs(:date_ymd)} 購入"
    end
  end

  # 購入したアイテムを取得（お買い物単位）
  def bought_items(shopping_record_form)
    shopping_record_form.hashids.map do |buy_hashid|
      Buy.find_by_hashid!(buy_hashid)
    end
  end

  # 未購入のアイテムを取得（お買い物単位）
  def no_bought_items(shopping_record_form)
    shopping_record = current_user.shopping_records.find_by_hashid!(shopping_record_form.shopping_record_hashid)
    if shopping_record_form.hashids.present?
      buy_item_ids = shopping_record_form.hashids.map do |buy_hashid|
        Buy.find_by_hashid!(buy_hashid).id
      end
      shopping_record.buys.where.not(id: buy_item_ids)
    else
      shopping_record.buys
    end
  end

  # お買い物完了日（更新日）を'%Y年 %-m月'に変換
  def updated_at_change_format_ja(shopping_record)
    shopping_record.updated_at.to_fs(:month_ja)
  end

  # お買い物完了日（更新日）の年月を'%Y-%m'に変換
  def updated_at_change_format_ym(shopping_record)
    shopping_record.updated_at.to_fs(:date_ym)
  end

  # '%Y-%m'で渡された年月を"#{year}年#{month}月"に変換
  def date_change_format_ja(params_date)
    year_month = params_date.split("-")
    year = year_month[0]
    month = year_month[1][0] == "0" ? year_month[1].delete("0") : year_month[1]
    "#{year}年#{month}月"
  end

  # ひらがなモードの設定状態でカテゴリー・アイテム名の表示を分岐
  def display_name_of_category_or_item(category_or_item)
    if current_user.hiragana_view.present?
      category_or_item.hiragana
    else
      category_or_item.name
    end
  end

  # ひらがなモードの設定状態で購入アイテム名の表示を分岐
  def display_item_name_of_buy(buy)
    if current_user.hiragana_view.present?
      buy.item_hiragana
    else
      buy.item_name
    end
  end
end
