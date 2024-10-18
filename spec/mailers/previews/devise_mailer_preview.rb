# Preview all emails at http://localhost:80/rails/mailers/devise_mailer
class DeviseMailerPreview < ActionMailer::Preview
  # プレビューに必要なデータはUser.newで用意する
  # また、confirmation_instructionsとreset_password_instructionsは
  # sesを介してメールを送信してしまうため.messageを使用してメール内容を取得しプレビュー表示のみにする

  # ユーザー登録時の確認メールのプレビュー
  def confirmation_instructions
    user = User.new(
      name: "テストユーザー",
      email: "mail-preview-user@example.com",
      confirmation_token: "dummy_confirmation_token"
    )
    Devise::Mailer.confirmation_instructions(user, user.confirmation_token).message
  end

  # パスワードリセットメールのプレビュー
  def reset_password_instructions
    # reset_password_tokenは本プレビューではダミートークンを生トークンとして代用する
    # （実際のreset_password_tokenはsend_reset_password_instructionsメソッドでハッシュ化されている）
    user = User.new(
      name: "テストユーザー",
      email: "mail-preview-user@example.com",
      confirmation_token: "dummy_confirmation_token",
      reset_password_token: "dummy_reset_password_token"
    )
    Devise::Mailer.reset_password_instructions(user, user.reset_password_token).message
  end

  # メールアドレス変更確認メールのプレビュー
  def send_reconfirmation_instructions
    # unconfirmed_emailを設定してメールアドレス変更時（メール変更確認前）の状態を擬似的に再現する
    user = User.new(
      name: "テストユーザー",
      email: "mail-preview-user@example.com",
      confirmation_token: "dummy_confirmation_token",
      unconfirmed_email: "new-email@example.com"
    )
    # send_reconfirmation_instructionsでは最終的に
    # confirmation_instructionsでメールを生成するので同メソッドを実行する
    Devise::Mailer.confirmation_instructions(user, user.confirmation_token).message
  end
end
