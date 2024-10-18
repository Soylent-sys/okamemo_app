require 'rails_helper'

RSpec.describe "Recaptcha", type: :system do
  # reCAPTCHAがチェックされている場合のverify_recaptchaのモック
  let(:recaptcha_true) do
    allow_any_instance_of(Recaptcha::Adapters::ControllerMethods).to receive(:verify_recaptcha).and_return(true)
  end
  # reCAPTCHAがチェックされていない場合のverify_recaptchaのモック
  # 引数のモデルにエラーを追加する場合のverify_recaptcha(model: resource)の呼び出しも想定
  let(:recaptcha_false) do
    allow_any_instance_of(Recaptcha::Adapters::ControllerMethods).to receive(:verify_recaptcha) do |_, options|
      if options
        model = options[:model]
        model.errors.add(:base, "reCAPTCHA認証に失敗しました。もう一度お試しください。") if model
      end
      false
    end
  end

  describe "ユーザー登録時のreCAPTCHA" do
    it "reCAPTCHAが有効なときユーザー登録が許可されること" do
      # reCAPTCHAがチェックされた場合のverify_recaptchaのモックをセット
      recaptcha_true
      visit new_user_registration_path
      expect do
        fill_in "ニックネーム", with: "テストユーザー"
        fill_in "Eメールアドレス", with: "test-user@example.test"
        # パスワード関連のフィールドはラベル文字列だと重複して扱われるためidを指定
        fill_in "user_password", with: "password123"
        fill_in "user_password_confirmation", with: "password123"
        click_button "ユーザー登録"
      end.to change { User.count }.by(1)

      expect(page).to have_content "本人確認用のメールを送信しました。メール内のリンクからアカウントを有効化させてください。"
    end

    it "reCAPTCHAが有効でなかったときにユーザー登録が許可されないこと" do
      # reCAPTCHAがチェックされない場合のverify_recaptchaのモックをセット
      recaptcha_false
      visit new_user_registration_path
      expect do
        fill_in "ニックネーム", with: "テストユーザー"
        fill_in "Eメールアドレス", with: "test-user@example.test"
        # パスワード関連のフィールドはラベル文字列だと重複して扱われるためidを指定
        fill_in "user_password", with: "password123"
        fill_in "user_password_confirmation", with: "password123"
        click_button "ユーザー登録"
      end.to_not change { User.count }

      expect(page).to have_content "reCAPTCHA認証に失敗しました。もう一度お試しください。"
    end
  end

  describe "お問い合わせ送信時のreCAPTCHA" do
    it "reCAPTCHAが有効なときお問い合わせの投稿が許可され内容確認のページが表示されること" do
      # reCAPTCHAがチェックされた場合のverify_recaptchaのモックをセット
      recaptcha_true
      visit contact_path

      fill_in "お名前", with: "テストユーザー"
      fill_in "Eメールアドレス", with: "test-user@example.test"
      fill_in "件名", with: "テスト件名"
      fill_in "お問い合わせ内容", with: "お問い合わせ内容をテストする"
      click_button "送信内容の確認"

      # お問い合わせ内容の確認ページの表示を確認
      expect(page).to have_selector("h2", text: "お問い合わせ内容の確認")
      expect(page).to have_button "送信"
    end

    it "reCAPTCHAが有効でなかったときにお問い合わせの投稿が許可されないこと" do
      # reCAPTCHAがチェックされない場合のverify_recaptchaのモックをセット
      recaptcha_false
      visit contact_path

      fill_in "お名前", with: "テストユーザー"
      fill_in "Eメールアドレス", with: "test-user@example.test"
      fill_in "件名", with: "テスト件名"
      fill_in "お問い合わせ内容", with: "お問い合わせ内容をテストする"
      click_button "送信内容の確認"

      expect(page).to have_content "reCAPTCHA認証に失敗しました。もう一度お試しください。"
    end
  end
end
