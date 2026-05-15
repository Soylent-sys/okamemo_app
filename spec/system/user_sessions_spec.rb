require 'rails_helper'

RSpec.describe "UserSessions", type: :system do
  describe "ビューの要素" do
    describe "new" do
      context "サインインしていない場合" do
        before do
          visit new_user_session_path
        end

        it "ページタイトルが表示されていること" do
          expect(page).to have_selector("h1", text: "ログイン")
        end

        it "ログインフォームが表示されること" do
          within "form.new_user" do
            expect(page).to have_selector("h2", text: "ユーザー情報の入力")
            expect(page).to have_field("Eメールアドレス")
            expect(page).to have_field("パスワード")
            expect(page).to have_unchecked_field("ログインを記憶する")
            expect(page).to have_button("ログイン")
          end
        end

        it "ログインを記憶するチェックボックスにチェックを入れられること" do
          within "form.new_user" do
            check "ログインを記憶する"

            expect(find_field("ログインを記憶する")).to be_checked
          end
        end

        it "未登録ユーザー向けのユーザー登録画面へのリンクが存在すること" do
          within ".form-other-bg" do
            expect(page).to have_link("ユーザー登録", href: new_user_registration_path)
          end
        end

        it "未登録ユーザー向けのユーザー登録画面へのリンクでログイン画面に遷移すること" do
          within ".form-other-bg" do
            click_link "ユーザー登録"
          end

          expect(page).to have_http_status(:success)
          expect(current_path).to eq(new_user_registration_path)
        end

        it "パスワード再設定画面へのリンクが存在すること" do
          within ".form-other-bg" do
            expect(page).to have_link("パスワードを忘れましたか？", href: new_user_password_path)
          end
        end

        it "パスワード再設定画面へのリンクでパスワード再設定画面に遷移すること" do
          within ".form-other-bg" do
            click_link "パスワードを忘れましたか？"
          end

          expect(page).to have_http_status(:success)
          expect(current_path).to eq(new_user_password_path)
        end

        it "確認メール再送画面へのリンクが存在すること" do
          within ".form-other-bg" do
            expect(page).to have_link("アカウント確認のメールを受け取っていませんか？", href: new_user_confirmation_path)
          end
        end

        it "確認メール再送画面へのリンクで確認メール再送画面に遷移すること" do
          within ".form-other-bg" do
            click_link "アカウント確認のメールを受け取っていませんか？"
          end

          expect(page).to have_http_status(:success)
          expect(current_path).to eq(new_user_confirmation_path)
        end
      end

      context "サインインしている場合" do
        let(:user) { create(:user) }

        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content("ログインしました。")
          visit new_user_session_path
        end

        include_examples "ログイン状態で非ログイン専用ページにアクセスした時のリダイレクトテスト"
      end
    end
  end

  describe "ユーザーログインのフロー" do
    context "正常系" do
      let(:user) { create(:user, password: "password123") }

      scenario "ユーザーがログインする" do
        visit new_user_session_path

        fill_in "Eメールアドレス", with: user.email
        fill_in "パスワード", with: "password123"
        click_button "ログイン"

        expect(page).to have_content("ログインしました。")
        expect(current_path).to eq(root_path)
      end
    end

    context "異常系" do
      context "サインインしていない場合" do
        let!(:user) { create(:user, password: "password123") }
        let(:unactivated_user) { create(:user, :unactivated, password: "password111") }
        let(:unexist_email) { "unexist-mail@example.test" }

        before do
          visit new_user_session_path
        end

        scenario "登録されていないメールアドレスでログインを試みる" do
          fill_in "Eメールアドレス", with: unexist_email
          fill_in "パスワード", with: "password123"
          click_button "ログイン"

          expect(page).to have_content("Eメールアドレスまたはパスワードが違います。")
          expect(current_path).to eq(new_user_session_path)
        end

        scenario "間違ったパスワードでログインを試みる" do
          fill_in "Eメールアドレス", with: user.email
          fill_in "パスワード", with: "WrongPass123"
          click_button "ログイン"

          expect(page).to have_content("Eメールアドレスまたはパスワードが違います。")
          expect(current_path).to eq(new_user_session_path)
        end

        scenario "必須フィールドが空の状態でログインを試みる" do
          click_button "ログイン"

          expect(page).to have_content("Eメールアドレスまたはパスワードが違います。")
          expect(current_path).to eq(new_user_session_path)
        end

        scenario "未認証のユーザーがログインを試みる" do
          # フローの中でconfirm関連カラムのupdateがされるため
          # before_updateメソッドの処理にマスター管理ユーザーが必要
          create(:user, :master_admin)

          fill_in "Eメールアドレス", with: unactivated_user.email
          fill_in "パスワード", with: "password111"
          click_button "ログイン"

          expect(page).to have_content("メールアドレスの本人確認が必要です。")
          expect(current_path).to eq(new_user_session_path)
        end
      end

      context "サインインしている場合" do
        let(:user) { create(:user, password: "password123") }

        scenario "ログイン状態のユーザーがログインを試みる" do
          sign_in_as(user)
          expect(page).to have_content("ログインしました。")
          visit new_user_session_path

          expect(page).to have_content("すでにログインしています。")
          expect(current_path).to eq(root_path)
        end
      end
    end
  end

  describe "ログインを記憶する(remember_me)機能", js: true do
    let!(:user) { create(:user) }
    # フローの中でremember_created_atカラムのupdateがされるため
    # before_updateメソッドの処理にマスター管理ユーザーが必要
    let!(:master_user) { create(:user, :master_admin) }
    # 現在のセッションのクッキーを削除してブラウザを閉じる操作をシミュレーション
    let(:window_close) { page.driver.browser.manage.delete_cookie("_okamemo_app_session") }

    before do
      visit new_user_session_path
    end

    scenario "ユーザーが「ログインを記憶する」をチェックしてログインする" do
      fill_in "Eメールアドレス", with: user.email
      fill_in "パスワード", with: user.password
      check "ログインを記憶する"
      click_button "ログイン"

      expect(page).to have_content("ログインしました。")
      expect(user.reload.remember_created_at).to_not be_nil

      window_close

      # ブラウザを再度開いた際にログイン状態が保持されていることを確認
      visit root_path
      within "nav" do
        expect(page).to have_button("ログアウト")
      end
    end

    scenario "ユーザーが「ログインを記憶する」をチェックしないでログインする" do
      fill_in "Eメールアドレス", with: user.email
      fill_in "パスワード", with: user.password
      uncheck "ログインを記憶する"
      click_button "ログイン"

      expect(page).to have_content("ログインしました。")
      expect(user.reload.remember_created_at).to be_nil

      window_close

      # ブラウザを再度開いた際にログイン状態が保持されていないことを確認
      visit root_path
      within "nav" do
        expect(page).to have_link("ログイン")
      end
    end

    scenario "ユーザーがログアウトしてremember_user_tokenが無効化される" do
      fill_in "Eメールアドレス", with: user.email
      fill_in "パスワード", with: user.password
      check "ログインを記憶する"
      click_button "ログイン"

      expect(page).to have_content("ログインしました。")
      expect(user.reload.remember_created_at).to_not be_nil

      within "nav" do
        click_button "ログアウト"
      end
      expect(page).to have_selector("#turbo-confirm-modal", visible: true)
      within "#turbo-confirm-modal" do
        click_button "ログアウトする"
      end
      expect(page).to have_content("ログアウトしました。")
      expect(user.reload.remember_created_at).to be_nil

      window_close

      # ブラウザを再度開いた際にログイン状態が保持されていないことを確認
      visit root_path
      within "nav" do
        expect(page).to have_link("ログイン")
      end
    end

    scenario "remember_user_tokenの有効期限が切れた後にアクセスする" do
      fill_in "Eメールアドレス", with: user.email
      fill_in "パスワード", with: user.password
      check "ログインを記憶する"
      click_button "ログイン"

      expect(page).to have_content("ログインしました。")
      expect(user.reload.remember_created_at).to_not be_nil

      window_close

      # Deviseでデフォルト設定されている有効期限
      remember_user_token_expiration = 2.weeks

      # remember_user_tokenの有効期限が切れた後にrootページにアクセス
      # ログイン状態が保持されていないことを確認
      travel_to(Time.current + remember_user_token_expiration + 1.day) do
        visit root_path
        within "nav" do
          expect(page).to have_link("ログイン")
        end
      end
    end
  end

  describe "ユーザーログアウトのフロー", js: true do
    let(:user) { create(:user) }
    # ログアウト時にusers_sessionsコントローラーのdestroyが実行されるため
    # before_destroyメソッドの処理にマスター管理ユーザーが必要
    let!(:master_user) { create(:user, :master_admin) }

    context "ログインを記憶しない場合" do
      before do
        sign_in_as(user)
        expect(page).to have_content("ログインしました。")
      end

      scenario "ログアウト後に非サインイン時のrootページにリダイレクトする" do
        # rootページからプライバシーポリシーのページに移動
        click_link "プライバシーポリシー"
        expect(page).to have_selector("h1", text: "プライバシーポリシー")
        expect(current_path).to eq(policy_path)

        within "nav" do
          expect(page).to_not have_button("ログイン")
          expect(page).to have_button("ログアウト")
          click_button "ログアウト"
        end
        expect(page).to have_selector("#turbo-confirm-modal", visible: true)
        within "#turbo-confirm-modal" do
          click_button "ログアウトする"
        end

        expect(page).to have_content("ログアウトしました。")
        expect(current_path).to eq(root_path)
        within "nav" do
          expect(page).to_not have_button("ログアウト")
          expect(page).to have_button("ログイン")
        end
      end

      scenario "ログアウト後に保護されたページにアクセスするとログイン画面にリダイレクトする" do
        # rootページからユーザー設定のページに移動
        within "nav" do
          click_link "ユーザー設定"
        end
        expect(page).to have_selector("h2", text: "ユーザー情報の編集")
        expect(current_path).to eq(edit_user_registration_path)

        within "nav" do
          expect(page).to_not have_button("ログイン")
          expect(page).to have_button("ログアウト")
          click_button "ログアウト"
        end
        expect(page).to have_selector("#turbo-confirm-modal", visible: true)
        within "#turbo-confirm-modal" do
          click_button "ログアウトする"
        end

        expect(page).to have_content("ログアウトしました。")
        expect(current_path).to eq(root_path)
        within "nav" do
          expect(page).to_not have_button("ログアウト")
          expect(page).to have_button("ログイン")
        end

        visit edit_user_registration_path
        expect(page).to have_content("ログインもしくはアカウント登録してください。")
        expect(current_path).to eq(new_user_session_path)
      end
    end

    context "ログインを記憶する場合" do
      scenario "ログアウト時にremember_me機能のクッキーが削除される" do
        # ログインを記憶するをチェックしてログイン
        visit new_user_session_path
        fill_in "Eメールアドレス", with: user.email
        fill_in "パスワード", with: user.password
        check "ログインを記憶する"
        click_button "ログイン"
        expect(page).to have_content("ログインしました。")

        # 保護されたページに移動
        visit edit_user_registration_path
        expect(page).to have_selector("h2", text: "ユーザー情報の編集")
        expect(current_path).to eq(edit_user_registration_path)

        # remember_user_token クッキーがセットされていることを確認する
        # ログアウト前の全てのクッキー情報をall_cookies_before_logout変数に格納
        all_cookies_before_logout = page.driver.browser.manage.all_cookies
        # クッキー情報からクッキーの名前の配列を取得
        before_logout_cookies = all_cookies_before_logout.map { |cookie| cookie[:name] }
        expect(before_logout_cookies).to include("remember_user_token")

        within "nav" do
          expect(page).to_not have_button("ログイン")
          expect(page).to have_button("ログアウト")
          click_button "ログアウト"
        end
        expect(page).to have_selector("#turbo-confirm-modal", visible: true)
        within "#turbo-confirm-modal" do
          click_button "ログアウトする"
        end
        expect(page).to have_content("ログアウトしました。")

        # remember_user_token クッキーが削除されていることを確認する
        # ログアウト前の全てのクッキー情報をall_cookies_before_logout変数に格納
        all_cookies_after_logout = page.driver.browser.manage.all_cookies
        # クッキー情報からクッキーの名前の配列を取得
        after_logout_cookies = all_cookies_after_logout.map { |cookie| cookie[:name] }
        expect(after_logout_cookies).to_not include("remember_user_token")
      end
    end
  end
end
