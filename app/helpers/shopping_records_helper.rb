module ShoppingRecordsHelper
  # お買い物登録フォームのタイトルをセット
  def shopping_title(shopping_record_form)
    if shopping_record_form.title.blank?
      "#{Date.today.to_fs(:date_ja)}のお買い物"
    else
      shopping_record_form.title
    end
  end

  # 各アイテムの最終購入日を表示
  def last_bought_day(buy_updated_at)
    if buy_updated_at.blank?
      "購入記録なし"
    elsif Date.current.all_day.cover? buy_updated_at
      "今日購入してます"
    elsif Date.yesterday.all_day.cover? buy_updated_at
      "昨日購入してます"
    elsif Date.current - 7.day < buy_updated_at.to_date
      "#{(Date.current - buy_updated_at.to_date).to_i}日前に購入"
    else
      "#{buy_updated_at.to_fs(:date_ymd)} 購入"
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
