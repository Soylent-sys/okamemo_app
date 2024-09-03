module ApplicationHelper
  include Pagy::Frontend

  BASE_TITLE = "おかメchan".freeze

  def full_title(title: '')
    title.blank? ? "#{BASE_TITLE} - 買い物お助けサービス" : "#{title} - #{BASE_TITLE}"
  end

  # ナビゲーションメッセージ作成用（provide上での改行）
  def html_safe_newline(str)
    h(str).gsub(/\r\n|\n|\r/, "<br>").html_safe
  end

  # ログイン前、ログイン済み画面でのflashの表示位置調整
  def position_flash
    if user_signed_in?
      "position-flash"
    else
      "position-flash-no-login"
    end
  end

  # ログインユーザーの状態表示
  def now_info
    path = request.path
    case
    when path.include?("management")
      "管理機能を利用中！"
    when path.include?("users/edit")
      "ユーザー編集中！"
    when path.include?("shopping/new")
      "お買い物登録中！"
    when path.include?("progress")
      "お買い物中！"
    when path.include?("location")
      "マップ記録中！"
    when path.include?("notification_target_users/new")
      "通知ユーザー登録中！"
    when path.include?("items/new")
      "アイテム登録中！"
    when /items\/\w+\/edit/.match?(path)
      "アイテム編集中！"
    else
      "ログイン中！"
    end
  end

  # 管理画面のメニュー項目選択時のデザイン適用
  def management_menu_active_class(path)
    request_path = request.path
    if request_path.include?(path)
      "mx-3 rounded-2 bg-secondary-subtle"
    end
  end

  # 管理画面でのflashのマージン調整
  def management_flash_margin_off
    if request.path.include?("management")
      "mb-0"
    end
  end
end
