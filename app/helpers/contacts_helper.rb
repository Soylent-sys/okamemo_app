module ContactsHelper
  # お問い合わせフォームの項目説明（ログイン状態で分岐）
  def form_info_text_name
    if user_signed_in?
      "ご登録のニックネームで送信されます"
    else
      "お名前は最大#{UserSharedConstants::MAX_LENGTH_NAME}文字まで入力できます"
    end
  end

  def form_info_text_email
    if user_signed_in?
      "ご登録のメールアドレスにご連絡いたします"
    else
      "このメールアドレスにご連絡いたします"
    end
  end

  # お問い合わせ送信完了画面のメッセージ（ログイン状態で分岐）
  def done_text
    if user_signed_in?
      "お問い合わせの内容を確認・受付の後、ご登録のEメールアドレスへご連絡いたします。しばらくお待ちください。"
    else
      "お問い合わせの内容を確認・受付の後、ご入力いただいたEメールアドレスへご連絡いたします。しばらくお待ちください。"
    end
  end
end
