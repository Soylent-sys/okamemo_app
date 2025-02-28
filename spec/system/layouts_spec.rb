require 'rails_helper'

RSpec.describe "Layouts", type: :system do
  describe "header" do
    shared_examples "ヘッダー部の共通テスト" do
      it "サービスロゴの画像が表示されていること" do
        within "nav" do
          expect(page).to have_selector("img[src*='logo_transparent_side']")
        end
      end

      it "サービスロゴをクリックしてrootページへ遷移できること" do
        within "nav" do
          click_link "サービスロゴ"
        end

        expect(page).to have_http_status(:success)
        expect(current_path).to eq root_path
      end

      context "ブラウザ幅が広い場合（992px以上）", js: true do
        before do
          page.driver.browser.manage.window.resize_to(992, 1050)
        end

        # window幅のリセット
        after do
          page.driver.browser.manage.window.resize_to(1680, 1050)
        end

        it "navbar-toggler（ハンバーガーメニューボタン）が非表示になっていること" do
          within "nav" do
            expect(page).to have_selector(".navbar-toggler", visible: false)
          end
        end

        it "初期状態でハンバーガーメニューの内容が表示されていること" do
          within "nav" do
            expect(page).to have_selector("#navbarSupportedContent", visible: true)
          end
        end
      end

      context "ブラウザ幅が狭い場合（991px以下）", js: true do
        before do
          page.driver.browser.manage.window.resize_to(991, 1050)
        end

        # window幅のリセット
        after do
          page.driver.browser.manage.window.resize_to(1680, 1050)
        end

        it "navbar-toggler（ハンバーガーメニューボタン）が表示されていること" do
          within "nav" do
            expect(page).to have_selector(".navbar-toggler", visible: true)
          end
        end

        it "初期状態でハンバーガーメニューの内容が非表示であること" do
          within "nav" do
            expect(page).to have_selector("#navbarSupportedContent", visible: false)
          end
        end

        let(:wait_time_second) { 1 }

        it "navbar-toggler（ハンバーガーメニューボタン）を押すとメニューの内容が表示されること" do
          within "nav" do
            find("button.navbar-toggler").click

            expect(page).to have_selector("#navbarSupportedContent", visible: true, wait: wait_time_second)
          end
        end

        it "メニューが表示されている状態でnavbar-toggler（ハンバーガーメニューボタン）を押すとメニューが非表示になること" do
          within "nav" do
            find("button.navbar-toggler").click

            expect(page).to have_selector("#navbarSupportedContent", visible: true, wait: wait_time_second)

            find("button.navbar-toggler").click

            expect(page).to have_selector("#navbarSupportedContent", visible: false)
          end
        end
      end
    end

    context "サインインしていない場合" do
      before do
        visit root_path
      end

      it_behaves_like "ヘッダー部の共通テスト"

      it "ログイン画面へ遷移するリンクが存在していること" do
        within "nav" do
          expect(page).to have_link("ログイン", href: new_user_session_path)
        end
      end

      it "ログインをクリックしてログインページへ遷移できること" do
        within "nav" do
          click_link "ログイン"
        end

        expect(page).to have_http_status(:success)
        expect(current_path).to eq new_user_session_path
      end

      it "ユーザー登録画面へ遷移するリンクが存在していること" do
        within "nav" do
          expect(page).to have_link("ユーザー登録", href: new_user_registration_path)
        end
      end

      it "ユーザー登録をクリックしてユーザー登録画面へ遷移できること" do
        within "nav" do
          click_link "ユーザー登録"
        end

        expect(page).to have_http_status(:success)
        expect(current_path).to eq new_user_registration_path
      end

      it "ゲストログインボタンが存在していること" do
        within "nav" do
          expect(page).to have_selector("button", text: "ゲストログイン")
        end
      end

      it "ゲストログインボタンのクリックでゲストログインができること" do
        within "nav" do
          click_button "ゲストログイン"
        end

        expect(current_path).to eq root_path

        within ".alert" do
          expect(page).to have_content "ゲストユーザーとしてログインしました。"
        end

        within "nav" do
          expect(page).to have_selector("button", text: "ログアウト")
        end
      end

      it "お買い物登録画面へ遷移するリンクが存在しないこと" do
        within "nav" do
          expect(page).to_not have_link("お買い物の登録", href: shopping_new_path)
        end
      end

      it "お買い物モード画面へ遷移するリンクが存在しないこと" do
        within "nav" do
          expect(page).to_not have_link("お買い物モード", href: shopping_index_path)
        end
      end

      it "お買い物履歴画面へ遷移するリンクが存在しないこと" do
        within "nav" do
          expect(page).to_not have_link("お買い物の履歴", href: shopping_result_group_path)
        end
      end

      it "アイテム一覧画面へ遷移するリンクが存在しないこと" do
        within "nav" do
          expect(page).to_not have_link("アイテム登録", href: items_path)
        end
      end

      it "通知対象ユーザー一覧画面へ遷移するリンクが存在しないこと" do
        within "nav" do
          expect(page).to_not have_link("通知メール登録", href: notification_target_users_path)
        end
      end

      it "ユーザー編集画面へ遷移するリンクが存在しないこと" do
        within "nav" do
          expect(page).to_not have_link("ユーザー設定", href: edit_user_registration_path)
        end
      end

      it "ログアウトボタンが存在しないこと" do
        within "nav" do
          expect(page).to have_no_selector("button", text: "ログアウト")
        end
      end

      it "管理画面へ遷移するリンクが存在しないこと" do
        expect(page).to_not have_link("管理者機能", href: management_users_path)
      end
    end

    context "サインインしている場合" do
      before do
        sign_in_as(user)
      end

      let(:user) { create(:user) }
      # ログアウト時に実行されるbeforeアクションにマスター管理ユーザーが必要
      # session_controllerのdestroy時にuserモデルのbefore_updateに設定している
      # prevent_master_admin_changeメソッド内のmaster_admin?が実行される
      let!(:master_user) { create(:user, :master_admin) }

      it_behaves_like "ヘッダー部の共通テスト"

      it "ログイン画面へ遷移するリンクが存在しないこと" do
        within "nav" do
          expect(page).to_not have_link("ログイン", href: new_user_session_path)
        end
      end

      it "ユーザー登録画面へ遷移するリンクが存在しないこと" do
        within "nav" do
          expect(page).to_not have_link("ユーザー登録", href: new_user_registration_path)
        end
      end

      it "ゲストログインボタンが存在しないこと" do
        within "nav" do
          expect(page).to_not have_selector("button", text: "ゲストログイン")
        end
      end

      it "お買い物登録画面へ遷移するリンクが存在すること" do
        within "nav" do
          expect(page).to have_link("お買い物の登録", href: shopping_new_path)
        end
      end

      it "お買い物登録をクリックしてお買い物登録画面へ遷移できること" do
        within "nav" do
          click_link "お買い物の登録"
        end

        expect(page).to have_http_status(:success)
        expect(current_path).to eq shopping_new_path
      end

      it "お買い物モード画面へ遷移するリンクが存在すること" do
        within "nav" do
          expect(page).to have_link("お買い物モード", href: shopping_index_path)
        end
      end

      it "お買い物モードをクリックしてお買い物モード画面へ遷移できること" do
        within "nav" do
          click_link "お買い物モード"
        end

        expect(page).to have_http_status(:success)
        expect(current_path).to eq shopping_index_path
      end

      it "お買い物履歴画面へ遷移するリンクが存在すること" do
        within "nav" do
          expect(page).to have_link("お買い物の履歴", href: shopping_result_group_path)
        end
      end

      it "お買い物の履歴をクリックしてお買い物履歴画面へ遷移できること" do
        within "nav" do
          click_link "お買い物の履歴"
        end

        expect(page).to have_http_status(:success)
        expect(current_path).to eq shopping_result_group_path
      end

      it "アイテム一覧画面へ遷移するリンクが存在すること" do
        within "nav" do
          expect(page).to have_link("アイテム登録", href: items_path)
        end
      end

      it "アイテム登録をクリックしてアイテム一覧画面へ遷移できること" do
        within "nav" do
          click_link "アイテム登録"
        end

        expect(page).to have_http_status(:success)
        expect(current_path).to eq items_path
      end

      it "通知対象ユーザー一覧画面へ遷移するリンクが存在すること" do
        within "nav" do
          expect(page).to have_link("通知メール登録", href: notification_target_users_path)
        end
      end

      it "通知メール登録をクリックして通知対象ユーザー一覧画面へ遷移できること" do
        within "nav" do
          click_link "通知メール登録"
        end

        expect(page).to have_http_status(:success)
        expect(current_path).to eq notification_target_users_path
      end

      it "ユーザー編集画面へ遷移するリンクが存在すること" do
        within "nav" do
          expect(page).to have_link("ユーザー設定", href: edit_user_registration_path)
        end
      end

      it "ユーザー設定をクリックしてユーザー編集画面へ遷移できること" do
        within "nav" do
          click_link "ユーザー設定"
        end

        expect(page).to have_http_status(:success)
        expect(current_path).to eq edit_user_registration_path
      end

      # ログアウトボタン・モーダルの基本機能テスト用変数
      let(:selector) { "nav" }

      include_examples "ログアウトボタン・モーダルの基本機能テスト"
    end

    describe "ユーザー区分で異なる箇所のテスト" do
      before do
        sign_in_as(user)
      end

      context "一般ユーザー・ゲストユーザーの場合" do
        let(:user) { create(:user) }

        it "管理画面へ遷移するリンクが存在しないこと" do
          expect(page).to_not have_link("管理者機能", href: management_users_path)
        end
      end

      context "管理ユーザー・マスター管理ユーザーの場合" do
        let(:user) { create(:user, :admin) }
        # 管理機能のコントローラー上でマスター管理ユーザーのインスタンス変数を定義するために必要
        let!(:master_user) { create(:user, :master_admin) }

        it "管理画面へ遷移するリンクが存在すること" do
          expect(page).to have_link("管理者機能", href: management_users_path)
        end

        it "管理者機能をクリックして管理画面へ遷移できること" do
          within "nav" do
            click_link "管理者機能"
          end

          expect(page).to have_http_status(:success)
          expect(current_path).to eq management_users_path
        end
      end
    end
  end

  describe "footer" do
    before do
      visit root_path
    end

    it "利用規約・推奨環境ページへのリンクが存在すること" do
      expect(page).to have_link("利用規約・推奨環境", href: terms_path)
    end

    it "利用規約・推奨環境をクリックして利用規約・推奨環境ページへ遷移できること" do
      within "footer" do
        click_link "利用規約・推奨環境"
      end

      expect(page).to have_http_status(:success)
      expect(current_path).to eq terms_path
    end

    it "プライバシーポリシーページへのリンクが存在すること" do
      expect(page).to have_link("プライバシーポリシー", href: policy_path)
    end

    it "プライバシーポリシーをクリックしてプライバシーポリシーのページへ遷移できること" do
      within "footer" do
        click_link "プライバシーポリシー"
      end

      expect(page).to have_http_status(:success)
      expect(current_path).to eq policy_path
    end

    it "お問い合わせ画面へのリンクが存在すること" do
      expect(page).to have_link("お問い合わせ", href: contact_path)
    end

    it "お問い合わせをクリックしてお問い合わせ画面へ遷移できること" do
      within "footer" do
        click_link "お問い合わせ"
      end

      expect(page).to have_http_status(:success)
      expect(current_path).to eq contact_path
    end

    it "ページのトップ（最上段）に移動するリンクが存在すること" do
      within "footer" do
        expect(page).to have_link("ページTOPへ", href: "#")
        click_link "ページTOPへ"
      end

      expect(current_path).to eq root_path
    end

    it "著作権表示が存在すること" do
      within "footer" do
        expect(page).to have_content "© 2024 okamemo.com"
      end
    end

    it "著作権表示をクリックするとrootページへ遷移すること" do
      within "footer" do
        click_link "© 2024 okamemo.com"
      end

      expect(page).to have_http_status(:success)
      expect(current_path).to eq root_path
    end
  end
end
