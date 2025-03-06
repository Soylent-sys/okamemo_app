require 'rails_helper'

RSpec.describe "ManagementUsers", type: :system do
  shared_examples "サイドバーにあるリンクの背景色CSSのテスト" do
    it "表示中のページ（ユーザー管理）のリンクに背景色のCSSが設定されていること" do
      within("ul.management-menu-list") do
        expect(page).to have_selector("li.bg-secondary-subtle", text: "ユーザー管理")
      end
    end

    it "表示中のページ（ユーザー管理）以外のリンクに背景色のCSSが設定されていないこと" do
      within("ul.management-menu-list") do
        expect(page).to_not have_selector("li.bg-secondary-subtle", text: "通知ユーザー管理")
        expect(page).to_not have_selector("li.bg-secondary-subtle", text: "アイテム管理")
        expect(page).to_not have_selector("li.bg-secondary-subtle", text: "お買い物管理")
      end
    end
  end

  describe "ビューの要素" do
    describe "index" do
      context "管理ユーザーの場合" do
        # beforeブロックのvisit時にマスター管理ユーザーが必要
        let!(:master_user) { create(:user, :master_admin) }
        let(:user) { create(:user, :admin) }

        before do
          sign_in_as(user)
          visit management_users_path
        end

        include_examples "ユーザー情報の表示テスト"

        include_examples "管理ページのサイドバーメニューのテスト"

        include_examples "サイドバーにあるリンクの背景色CSSのテスト"

        it "ページタイトルが表示されること" do
          within "div.management-main" do
            expect(page).to have_selector("h2", text: "ユーザー管理")
          end
        end

        it "検索フォームが表示されること" do
          expect(page).to have_selector("form#user_search")
          expect(page).to have_field("q[name_or_email_cont]", type: "search", placeholder: "Email または Name 部分一致")
          expect(page).to have_button "検索"
        end

        it "初期状態では登録済みユーザーの件数が表示されること" do
          expect(page).to have_selector("h5", text: "件数： #{User.count} 件")
        end

        it "ユーザー登録画面へのリンクが存在すること" do
          expect(page).to have_link("登録", href: new_management_user_path)
        end

        it "ユーザー登録画面へのリンクをクリックしてユーザー登録画面へ遷移すること" do
          within "div.management-main" do
            click_link "登録"
          end

          expect(page).to have_http_status(:success)
          expect(current_path).to eq new_management_user_path
        end

        it "ユーザー一覧テーブルの各見出しが表示されること" do
          within "thead" do
            expect(page).to have_selector("th", text: "ID")
            expect(page).to have_selector("th", text: "Admin")
            expect(page).to have_selector("th", text: "Email")
            expect(page).to have_selector("th", text: "Name")
            expect(page).to have_selector("th", text: "Hiragana Mode")
            expect(page).to have_selector("th", text: "Confirmed_at")
            expect(page).to have_selector("th", text: "Created_at")
            expect(page).to have_selector("th", text: "Updated_at")
            expect(page).to have_selector("th", text: "編集")
            expect(page).to have_selector("th", text: "削除")
          end
        end
      end

      context "管理ユーザー以外の場合" do
        let(:user) { create(:user) }

        before do
          sign_in_as(user)
        end

        it "404エラーになること" do
          expect { visit management_users_path }.to raise_error(ActionController::RoutingError)
        end
      end

      context "サインインしていない場合" do
        it "404エラーになること" do
          expect { visit management_users_path }.to raise_error(ActionController::RoutingError)
        end
      end

      describe "各ユーザーの情報表示・ボタンのテスト" do
        # beforeブロックのvisit時にマスター管理ユーザーが必要
        let!(:master_user) { create(:user, :master_admin) }
        let!(:user) { create(:user, :admin) }

        describe "ユーザー状態で共通のテスト" do
          before do
            sign_in_as(user)
            # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
            expect(page).to have_content "ログインしました。"
            visit management_users_path
          end

          it "登録ユーザー毎にID、メールアドレス、ニックネーム、作成・更新日時が表示されること" do
            within("tr", text: master_user.id) do
              expect(page).to have_selector("td", text: master_user.id)
              expect(page).to have_selector("td", text: master_user.email)
              expect(page).to have_selector("td", text: master_user.name)
              expect(page).to have_selector("td", text: master_user.created_at.to_fs(:date_time))
              expect(page).to have_selector("td", text: master_user.updated_at.to_fs(:date_time))
            end

            within("tr", text: user.id) do
              expect(page).to have_selector("td", text: user.id)
              expect(page).to have_selector("td", text: user.email)
              expect(page).to have_selector("td", text: user.name)
              expect(page).to have_selector("td", text: user.created_at.to_fs(:date_time))
              expect(page).to have_selector("td", text: user.updated_at.to_fs(:date_time))
            end
          end

          it "登録ユーザー毎に更新画面へのリンクが存在すること" do
            within("tr", text: master_user.id) do
              expect(page).to have_selector("i.edit-icon")
              expect(page).to have_link(href: edit_management_user_path(master_user.id))
            end

            within("tr", text: user.id) do
              expect(page).to have_selector("i.edit-icon")
              expect(page).to have_link(href: edit_management_user_path(user.id))
            end
          end

          it "ユーザーの更新画面へのリンクをクリックして該当ユーザーの更新画面へ遷移すること" do
            within("tr", text: user.id) do
              click_link(href: edit_management_user_path(user.id))
            end

            expect(page).to have_http_status(:success)
            expect(current_path).to eq edit_management_user_path(user.id)
          end

          it "マスター管理ユーザーの行には削除ボタンが存在しないこと" do
            within("tr", text: master_user.id) do
              expect(page).to_not have_selector("i.delete-icon")
            end
          end

          it "マスター管理ユーザー以外の行には削除ボタンが存在すること" do
            within("tr", text: user.id) do
              expect(page).to have_selector("i.delete-icon")
            end
          end

          it "ユーザー削除ボタンをクリックするとモーダルが表示されること", js: true do
            expect(page).to have_selector("#turbo-confirm-modal", visible: false)

            within("tr", text: user.id) do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)
          end

          it "ユーザー削除モーダルにタイトルが表示されること", js: true do
            within("tr", text: user.id) do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            within "#turbo-confirm-modal" do
              expect(page).to have_selector("h1", visible: true, text: "ユーザー（#{user.email}）の削除")
            end
          end

          it "ユーザー削除モーダルのヘッダーにモーダルを閉じるボタンがあること", js: true do
            within("tr", text: user.id) do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            within "#turbo-confirm-modal" do
              within ".modal-header" do
                expect(page).to have_selector("button.btn-close", visible: true)
              end
            end
          end

          it "ユーザー削除モーダルに削除ボタン・キャンセルボタンが表示されること", js: true do
            within("tr", text: user.id) do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            within "#turbo-confirm-modal" do
              expect(page).to have_selector("button", visible: true, text: "削除する")
              expect(page).to have_selector("button", visible: true, text: "キャンセル")
            end
          end

          it "ユーザー削除モーダルのキャンセルボタンでお買い物削除を中止できること", js: true do
            within("tr", text: user.id) do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            within "#turbo-confirm-modal" do
              click_button "キャンセル"
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: false)
          end

          it "ユーザー削除モーダルの外をクリックするとモーダルが閉じること", js: true do
            within("tr", text: user.id) do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            # モーダルの外をクリック
            page.execute_script("document.querySelector('body').click();")

            expect(page).to have_selector("#turbo-confirm-modal", visible: false)
          end
        end

        describe "一覧に表示されるユーザーの状態で異なる箇所のテスト" do
          context "管理ユーザーの場合" do
            before do
              sign_in_as(user)
              visit management_users_path
            end

            it "'管理者'の表示が存在すること" do
              within("tr", text: user.id) do
                expect(page).to have_selector("td", text: "管理者")
              end
            end
          end

          context "管理ユーザー以外の場合" do
            let!(:general_user) { create(:user, admin: false) }

            before do
              sign_in_as(user)
              visit management_users_path
            end

            it "'一般'の表示が存在すること" do
              within("tr", text: general_user.id) do
                expect(page).to have_selector("td", text: "一般")
              end
            end
          end

          context "ひらがなモードがOFFの場合" do
            let!(:hiragana_off_user) { create(:user, hiragana_view: false) }

            before do
              sign_in_as(user)
              visit management_users_path
            end

            it "'OFF'の表示が存在すること" do
              within("tr", text: hiragana_off_user.id) do
                expect(page).to have_selector("td", text: "OFF")
              end
            end
          end

          context "ひらがなモードがONの場合" do
            let!(:hiragana_on_user) { create(:user, hiragana_view: true) }

            before do
              sign_in_as(user)
              visit management_users_path
            end

            it "'ON'の表示が存在すること" do
              within("tr", text: hiragana_on_user.id) do
                expect(page).to have_selector("td", text: "ON")
              end
            end
          end

          context "認証済みの場合" do
            let!(:confirmed_user) { create(:user) }

            before do
              sign_in_as(user)
              visit management_users_path
            end

            it "認証日時（date_timeフォーマット）の表示が存在すること" do
              within("tr", text: confirmed_user.id) do
                expect(page).to have_selector("td", text: confirmed_user.confirmed_at.to_fs(:date_time))
              end
            end
          end

          context "未認証の場合" do
            let!(:unconfirmed_user) { create(:user, :unactivated) }

            before do
              sign_in_as(user)
              visit management_users_path
            end

            it "'未認証'の表示が存在すること" do
              within("tr", text: unconfirmed_user.id) do
                expect(page).to have_selector("td", text: "未認証")
              end
            end
          end
        end

        describe "マスター管理ユーザーの更新画面へのアクセス制御のテスト" do
          # beforeブロックのvisit時にマスター管理ユーザーが必要
          let!(:master_user) { create(:user, :master_admin) }
          let!(:user) { create(:user, :admin) }

          context "マスター管理ユーザーの場合" do
            before do
              sign_in_as(master_user)
              visit management_users_path
            end

            it "マスター管理ユーザーの更新画面へのリンクをクリックして更新画面へ遷移できること" do
              within("tr", text: master_user.id) do
                click_link(href: edit_management_user_path(master_user.id))
              end

              expect(page).to have_http_status(:success)
              expect(current_path).to eq edit_management_user_path(master_user.id)
            end
          end

          context "管理ユーザーの場合" do
            before do
              sign_in_as(user)
              visit management_users_path
            end

            it "マスター管理ユーザーの更新画面へのリンクをクリックしてユーザー管理画面へリダイレクトされること" do
              within("tr", text: master_user.id) do
                click_link(href: edit_management_user_path(master_user.id))
              end

              expect(page).to have_content "対象のユーザーはマスター管理ユーザーのみ編集可能です。"
              expect(current_path).to eq management_users_path
            end
          end
        end
      end

      describe "ページネーションのテスト" do
        # beforeブロックのvisit時にマスター管理ユーザーが必要
        let!(:master_user) { create(:user, :master_admin) }
        let!(:user) { create(:user, :admin) }
        let!(:users) { create_list(:user, 48) } # 登録ユーザーを50件にする
        let(:one_pagenation_max_size) { 50 }

        context "表示対象のユーザー件数が50件以下の場合" do
          before do
            # ユーザーの件数が50件であることを確認
            expect(User.count).to eq(one_pagenation_max_size)

            sign_in_as(user)
            visit management_users_path
          end

          it "ページネーションのナビゲーションが存在しないこと" do
            expect(page).to_not have_selector("nav.pagy-nav")
          end
        end

        context "表示対象のユーザー件数が50件を超える場合" do
          let!(:user_51st) { create(:user) } # 登録ユーザーを51件にする
          let(:one_pagenation_over_size) { 51 }

          before do
            # ユーザーの件数が51件であることを確認
            expect(User.count).to eq(one_pagenation_over_size)

            sign_in_as(user)
            visit management_users_path
          end

          it "最初のページに50件のユーザーが表示されること" do
            expect(page).to have_selector("tr", text: master_user.email)
            expect(page).to have_selector("tr", text: user.email)
            users.each do |user|
              expect(page).to have_selector("tr", text: user.email)
            end
          end

          it "最初のページに51件目のユーザーが表示されないこと" do
            expect(page).to_not have_selector("tr", text: user_51st.email)
          end

          it "ページネーションのナビゲーションが存在すること" do
            expect(page).to have_selector("nav.pagy-nav")
          end

          it "ページネーションの別のページへのリンクが存在すること" do
            within "nav.pagy-nav" do
              expect(page).to have_link("2", href: management_users_path(page: 2))
              expect(page).to have_link("次", href: management_users_path(page: 2))
            end
          end

          it "1ページ目（現在のページ）のリンクが存在しないこと" do
            within "nav.pagy-nav" do
              expect(page).to_not have_link("1", href: management_users_path(page: 1))
              expect(page).to have_selector("span.active", text: "1")
            end
          end

          it "最初のページの前ページへのリンクが存在しないこと" do
            within "nav.pagy-nav" do
              expect(page).to_not have_link("前")
              expect(page).to have_selector("span.disabled", text: "前")
            end
          end

          context "2ページ目に移動した場合" do
            before do
              click_link "次"
              expect(URI.parse(current_url).request_uri).to eq management_users_path(page: 2)
            end

            it "51件目のユーザーが表示されること" do
              expect(page).to have_selector("tr", text: user_51st.email)
            end

            it "最初のページの50件のユーザーが表示されないこと" do
              expect(page).to_not have_selector("tr", text: master_user.email)
              expect(page).to_not have_selector("tr", text: user.email)
              users.each do |user|
                expect(page).to_not have_selector("tr", text: user.email)
              end
            end

            it "ページネーションの別のページへのリンクが存在すること" do
              within "nav.pagy-nav" do
                expect(page).to have_link("前", href: management_users_path(page: 1))
                expect(page).to have_link("1", href: management_users_path(page: 1))
              end
            end

            it "前ページへのリンクが活性状態で存在すること" do
              within "nav.pagy-nav" do
                expect(page).to have_link("前")
                expect(page).to_not have_selector("span.disabled", text: "前")
              end
            end

            it "2ページ目（現在のページ）のリンクが存在しないこと" do
              within "nav.pagy-nav" do
                expect(page).to_not have_link("2", href: management_users_path(page: 2))
                expect(page).to have_selector("span.active", text: "2")
              end
            end

            it "次ページへのリンクが存在しないこと" do
              within "nav.pagy-nav" do
                expect(page).to_not have_link("次")
                expect(page).to have_selector("span.disabled", text: "次")
              end
            end
          end
        end
      end
    end

    describe "new" do
      context "管理ユーザーの場合" do
        # beforeブロックのvisit時にマスター管理ユーザーが必要
        let!(:master_user) { create(:user, :master_admin) }
        let(:user) { create(:user, :admin) }

        before do
          sign_in_as(user)
          visit new_management_user_path
        end

        include_examples "ユーザー情報の表示テスト"

        include_examples "管理ページのサイドバーメニューのテスト"

        include_examples "サイドバーにあるリンクの背景色CSSのテスト"

        it "ページタイトルが表示されること" do
          within "div.management-main" do
            expect(page).to have_selector("h2", text: "ユーザー登録")
          end
        end

        it "戻るリンクが表示されること" do
          expect(page).to have_link "戻る"
        end

        it "ユーザー登録フォームが表示されること" do
          within "form.new_user" do
            expect(page).to have_selector("h2", text: "登録情報の入力")
            expect(page).to have_selector("h5", text: "ユーザー区分")
            expect(page).to have_field("管理者", type: "radio", with: true)
            expect(page).to have_field("一般", type: "radio", with: false)
            expect(page).to have_field("ニックネーム")
            expect(page).to have_field("Eメールアドレス")
            # ラベルは部分一致するためIDを指定
            expect(page).to have_field("user_password", exact: true)
            expect(page).to have_field("user_password_confirmation", exact: true)
            expect(page).to have_button("登録")
          end
        end

        it "ユーザー区分のラジオボタンの初期値は'一般'が選択されていること" do
          expect(page).to have_checked_field("一般")
          expect(page).to have_unchecked_field("管理者")
        end
      end

      context "管理ユーザー以外の場合" do
        let(:user) { create(:user) }

        before do
          sign_in_as(user)
        end

        it "404エラーになること" do
          expect { visit new_management_user_path }.to raise_error(ActionController::RoutingError)
        end
      end

      context "サインインしていない場合" do
        it "404エラーになること" do
          expect { visit new_management_user_path }.to raise_error(ActionController::RoutingError)
        end
      end

      describe "戻るリンクのテスト" do
        # 管理ページのvisit時にマスター管理ユーザーが必要
        let!(:master_user) { create(:user, :master_admin) }
        let(:user) { create(:user, :admin) }
        let!(:users) { create_list(:user, 49) } # 登録ユーザーを51件にする
        # 戻るリンクのテストに必要な変数を定義
        let(:test_index_page_path) { management_users_path }
        let(:test_index_page2_path) { management_users_path(page: 2) }
        let(:test_page_path) { new_management_user_path }
        let(:td_text) { user.email }

        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
        end

        include_examples "back_linkによる戻るリンクのテスト"
      end
    end

    describe "edit" do
      context "マスター管理ユーザー／管理ユーザーの場合" do
        # beforeブロックのvisit時にマスター管理ユーザーが必要
        let!(:master_user) { create(:user, :master_admin) }
        let(:user) { create(:user, :admin) }

        before do
          sign_in_as(user)
          visit edit_management_user_path(user.id)
        end

        include_examples "ユーザー情報の表示テスト"

        include_examples "管理ページのサイドバーメニューのテスト"

        include_examples "サイドバーにあるリンクの背景色CSSのテスト"

        it "ページタイトルが表示されること" do
          within "div.management-main" do
            expect(page).to have_selector("h2", text: "ユーザー編集")
          end
        end

        it "戻るリンクが表示されること" do
          expect(page).to have_link "戻る"
        end

        it "ユーザー編集フォームが表示されること" do
          within "form.edit_user" do
            expect(page).to have_selector("h2", text: "編集情報の入力")
            expect(page).to have_selector("h5", text: "ユーザー区分")
            expect(page).to have_field("管理者", type: "radio", with: true)
            expect(page).to have_field("一般", type: "radio", with: false)
            expect(page).to have_field("ニックネーム")
            expect(page).to have_field("Eメールアドレス")
            # ラベルは部分一致するためIDを指定
            expect(page).to have_field("user_password", exact: true)
            expect(page).to have_field("user_password_confirmation", exact: true)
            expect(page).to have_selector("h5", text: "ひらがなモード")
            expect(page).to have_field("ON", type: "radio", with: true)
            expect(page).to have_field("OFF", type: "radio", with: false)
            expect(page).to have_button("更新")
          end
        end

        it "デフォルトでニックネームのフィールドに現在のニックネームが入力されていること" do
          expect(page).to have_field("ニックネーム", with: user.name)
        end

        it "デフォルトでEメールアドレスのフィールドに現在のEメールアドレスが入力されていること" do
          expect(page).to have_field("Eメールアドレス", with: user.email)
        end
      end

      context "管理ユーザー以外の場合" do
        let(:user) { create(:user) }

        before do
          sign_in_as(user)
        end

        it "404エラーになること" do
          expect { visit edit_management_user_path(user.id) }.to raise_error(ActionController::RoutingError)
        end
      end

      context "サインインしていない場合" do
        let!(:user) { create(:user) }

        it "404エラーになること" do
          expect { visit edit_management_user_path(user.id) }.to raise_error(ActionController::RoutingError)
        end
      end

      describe "ラジオボタン初期値のテスト" do
        # beforeブロックのvisit時にマスター管理ユーザーが必要
        let!(:master_user) { create(:user, :master_admin) }
        let(:user) { create(:user, :admin) }

        before do
          sign_in_as(user)
        end

        context "編集対象が管理ユーザーの場合" do
          it "ユーザー区分のラジオボタンの初期値は'管理者'が選択されていること" do
            visit edit_management_user_path(user.id)

            expect(page).to have_checked_field("管理者")
            expect(page).to have_unchecked_field("一般")
          end
        end

        context "編集対象が管理ユーザーではない場合" do
          let!(:general_user) { create(:user, admin: false) }

          it "ユーザー区分のラジオボタンの初期値は'一般'が選択されていること" do
            visit edit_management_user_path(general_user.id)

            expect(page).to have_checked_field("一般")
            expect(page).to have_unchecked_field("管理者")
          end
        end

        context "編集対象ユーザーがひらがなモードを使用している場合" do
          let!(:hiragana_on_user) { create(:user, hiragana_view: true) }

          it "ひらがなモードのラジオボタンの初期値は'ON'が選択されていること" do
            visit edit_management_user_path(hiragana_on_user.id)

            expect(page).to have_checked_field("ON")
            expect(page).to have_unchecked_field("OFF")
          end
        end

        context "編集対象ユーザーがひらがなモードを使用していない場合" do
          let!(:hiragana_off_user) { create(:user, hiragana_view: false) }

          it "ひらがなモードのラジオボタンの初期値は'OFF'が選択されていること" do
            visit edit_management_user_path(hiragana_off_user.id)

            expect(page).to have_checked_field("OFF")
            expect(page).to have_unchecked_field("ON")
          end
        end
      end

      describe "編集対象となるユーザーで異なる箇所のテスト" do
        # beforeブロックのvisit時にマスター管理ユーザーが必要
        let!(:master_user) { create(:user, :master_admin) }
        let(:user) { create(:user, :admin) }

        context "マスター管理ユーザー以外の場合" do
          before do
            sign_in_as(user)
            visit edit_management_user_path(user.id)
          end

          it "ユーザー区分の'一般'のラジオボタンが活性状態であること" do
            within "form.edit_user" do
              expect(page).to have_field("一般", type: "radio", with: "false", disabled: false)
            end
          end

          it "編集フォームのEメールアドレスのフィールドがreadonlyではないこと" do
            expect(page).to have_field("Eメールアドレス", readonly: false)
          end
        end

        context "マスター管理ユーザーの場合" do
          before do
            sign_in_as(master_user)
            visit edit_management_user_path(master_user.id)
          end

          it "ユーザー区分の'一般'のラジオボタンが非活性状態であること" do
            within "form.edit_user" do
              expect(page).to have_field("一般", type: "radio", with: "false", disabled: true)
            end
          end

          it "編集フォームのEメールアドレスのフィールドがreadonlyであること" do
            expect(page).to have_field("Eメールアドレス", readonly: true)
          end
        end
      end

      describe "戻るリンクのテスト" do
        # 管理ページのvisit時にマスター管理ユーザーが必要
        let!(:master_user) { create(:user, :master_admin) }
        let(:user) { create(:user, :admin) }
        let!(:users) { create_list(:user, 49) } # 登録ユーザーを51件にする
        # 戻るリンクのテストに必要な変数を定義
        let(:test_index_page_path) { management_users_path }
        let(:test_index_page2_path) { management_users_path(page: 2) }
        let(:test_page_path) { edit_management_user_path(user.id) }
        let(:td_text) { user.email }

        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
        end

        include_examples "back_linkによる戻るリンクのテスト"
      end
    end
  end

  describe "ユーザー一覧のソート・検索機能のテスト" do
    let(:master_admin_user_email_original) { ENV["ADMIN_USER_EMAIL"] }
    let(:master_user) do
      create(
        :user, :master_admin,
        id: 1,
        # admin: true
        name: "Alice Red",
        # email: "alice@example.com"
        hiragana_view: false,
        confirmed_at: 1.day.ago,
        created_at: 1.day.ago,
        updated_at: 1.day.ago
      )
    end
    let!(:general_user) do
      create(
        :user,
        id: 2,
        admin: false,
        name: "Bob Brown",
        email: "bob@example.com",
        hiragana_view: true,
        confirmed_at: nil,
        created_at: 2.days.ago,
        updated_at: 2.days.ago
      )
    end
    let(:user) do
      create(
        :user,
        id: 3,
        admin: true,
        name: "Charlie Brown",
        email: "charlie@example.net",
        hiragana_view: false,
        confirmed_at: 3.days.ago,
        created_at: 3.days.ago,
        updated_at: 3.days.ago
      )
    end

    before do
      # マスター管理ユーザーのEmailをソートテスト用に変更
      master_admin_user_email_original
      ENV["ADMIN_USER_EMAIL"] = "alice@example.com"
      master_user

      sign_in_as(user)
      visit management_users_path
    end

    after do
      ENV["ADMIN_USER_EMAIL"] = master_admin_user_email_original
    end

    describe "ソート機能" do
      it "デフォルトではIDの昇順になっていること" do
        within "tbody" do
          rows = all("tr")
          expect(rows[0]).to have_selector("td", text: "alice@example.com")
          expect(rows[1]).to have_selector("td", text: "bob@example.com")
          expect(rows[2]).to have_selector("td", text: "charlie@example.net")
        end
      end

      include_examples "ソート順による見出しのCSSのテスト"

      context "IDででソートする場合" do
        it "IDの昇順でソートされること" do
          click_link "ID"

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "alice@example.com")
            expect(rows[1]).to have_selector("td", text: "bob@example.com")
            expect(rows[2]).to have_selector("td", text: "charlie@example.net")
          end
        end

        it "IDの降順でソートされること" do
          click_link "ID" # 1回目のクリックで昇順
          click_link "ID" # 2回目のクリックで降順

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "charlie@example.net")
            expect(rows[1]).to have_selector("td", text: "bob@example.com")
            expect(rows[2]).to have_selector("td", text: "alice@example.com")
          end
        end
      end

      context "ユーザー区分(Admin)でソートする場合" do
        it "一般ユーザー、管理ユーザーの順でソートされること" do
          click_link "Admin"

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "bob@example.com")
            expect(rows[1]).to have_selector("td", text: "alice@example.com")
            expect(rows[2]).to have_selector("td", text: "charlie@example.net")
          end
        end

        it "管理ユーザー、一般ユーザーの順でソートされること" do
          click_link "Admin" # 1回目のクリックで昇順
          click_link "Admin" # 2回目のクリックで降順

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "alice@example.com")
            expect(rows[1]).to have_selector("td", text: "charlie@example.net")
            expect(rows[2]).to have_selector("td", text: "bob@example.com")
          end
        end
      end

      context "Eメールアドレス(Email)でソートする場合" do
        it "Eメールアドレスの昇順でソートされること" do
          click_link "Email"

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "alice@example.com")
            expect(rows[1]).to have_selector("td", text: "bob@example.com")
            expect(rows[2]).to have_selector("td", text: "charlie@example.net")
          end
        end

        it "Eメールアドレスの降順でソートされること" do
          click_link "Email" # 1回目のクリックで昇順
          click_link "Email" # 2回目のクリックで降順

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "charlie@example.net")
            expect(rows[1]).to have_selector("td", text: "bob@example.com")
            expect(rows[2]).to have_selector("td", text: "alice@example.com")
          end
        end
      end

      context "ニックネーム(Name)でソートする場合" do
        it "ニックネームの昇順でソートされること" do
          click_link "Name"

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "alice@example.com")
            expect(rows[1]).to have_selector("td", text: "bob@example.com")
            expect(rows[2]).to have_selector("td", text: "charlie@example.net")
          end
        end

        it "ニックネームの降順でソートされること" do
          click_link "Name" # 1回目のクリックで昇順
          click_link "Name" # 2回目のクリックで降順

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "charlie@example.net")
            expect(rows[1]).to have_selector("td", text: "bob@example.com")
            expect(rows[2]).to have_selector("td", text: "alice@example.com")
          end
        end
      end

      context "ひらがなモード(Hiragana Mode)でソートする場合" do
        it "ひらがなモードOFF、ONの順でソートされること" do
          click_link "Hiragana Mode"

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "alice@example.com")
            expect(rows[1]).to have_selector("td", text: "charlie@example.net")
            expect(rows[2]).to have_selector("td", text: "bob@example.com")
          end
        end

        it "ひらがなモードON、OFFの順でソートされること" do
          click_link "Hiragana Mode" # 1回目のクリックで昇順
          click_link "Hiragana Mode" # 2回目のクリックで降順

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "bob@example.com")
            expect(rows[1]).to have_selector("td", text: "alice@example.com")
            expect(rows[2]).to have_selector("td", text: "charlie@example.net")
          end
        end
      end

      context "認証日時(Confirmed_at)でソートする場合" do
        it "未認証、認証日時の昇順でソートされること" do
          click_link "Confirmed_at"

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "bob@example.com")
            expect(rows[1]).to have_selector("td", text: "charlie@example.net")
            expect(rows[2]).to have_selector("td", text: "alice@example.com")
          end
        end

        it "認証日時の昇順、未認証の順でソートされること" do
          click_link "Confirmed_at" # 1回目のクリックで昇順
          click_link "Confirmed_at" # 2回目のクリックで降順

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "alice@example.com")
            expect(rows[1]).to have_selector("td", text: "charlie@example.net")
            expect(rows[2]).to have_selector("td", text: "bob@example.com")
          end
        end
      end

      context "作成日時(Created_at)でソートする場合" do
        it "作成日時の昇順でソートされること" do
          click_link "Created_at"

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "charlie@example.net")
            expect(rows[1]).to have_selector("td", text: "bob@example.com")
            expect(rows[2]).to have_selector("td", text: "alice@example.com")
          end
        end

        it "作成日時の降順でソートされること" do
          click_link "Created_at" # 1回目のクリックで昇順
          click_link "Created_at" # 2回目のクリックで降順

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "alice@example.com")
            expect(rows[1]).to have_selector("td", text: "bob@example.com")
            expect(rows[2]).to have_selector("td", text: "charlie@example.net")
          end
        end
      end

      context "更新日時(Updated_at)でソートする場合" do
        it "更新日時の昇順でソートされること" do
          click_link "Updated_at"

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "charlie@example.net")
            expect(rows[1]).to have_selector("td", text: "bob@example.com")
            expect(rows[2]).to have_selector("td", text: "alice@example.com")
          end
        end

        it "更新日時の降順でソートされること" do
          click_link "Updated_at" # 1回目のクリックで昇順
          click_link "Updated_at" # 2回目のクリックで降順

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "alice@example.com")
            expect(rows[1]).to have_selector("td", text: "bob@example.com")
            expect(rows[2]).to have_selector("td", text: "charlie@example.net")
          end
        end
      end
    end

    describe "検索機能" do
      it "Eメールアドレスでユーザーの絞り込みができること" do
        fill_in "q_name_or_email_cont", with: ".com"
        click_button "検索"

        within "tbody" do
          expect(page).to have_selector("td", text: "alice@example.com")
          expect(page).to have_selector("td", text: "bob@example.com")
          expect(page).to_not have_selector("td", text: "charlie@example.net")
        end
      end

      it "ニックネームでユーザーの絞り込みができること" do
        fill_in "q_name_or_email_cont", with: "Brown"
        click_button "検索"

        within "tbody" do
          expect(page).to have_selector("td", text: "Bob Brown")
          expect(page).to have_selector("td", text: "Charlie Brown")
          expect(page).to_not have_selector("td", text: "Alice Red")
        end
      end
    end

    describe "ソート・検索機能の組み合わせ" do
      it "ユーザーを検索で絞り込んだあとにソートできること" do
        fill_in "q_name_or_email_cont", with: "Brown"
        click_button "検索"

        within "tbody" do
          rows = all("tr")
          expect(rows[0]).to have_selector("td", text: "Bob Brown")
          expect(rows[1]).to have_selector("td", text: "Charlie Brown")
          expect(page).to_not have_selector("td", text: "Alice Red")
        end

        # ニックネームの昇順でソート
        click_link "Name"
        within "tbody" do
          rows = all("tr")
          expect(rows[0]).to have_selector("td", text: "Bob Brown")
          expect(rows[1]).to have_selector("td", text: "Charlie Brown")
          expect(page).to_not have_selector("td", text: "Alice Red")
        end

        # ニックネームの降順でソート
        click_link "Name"
        within "tbody" do
          rows = all("tr")
          expect(rows[0]).to have_selector("td", text: "Charlie Brown")
          expect(rows[1]).to have_selector("td", text: "Bob Brown")
          expect(page).to_not have_selector("td", text: "Alice Red")
        end
      end
    end
  end

  describe "ユーザー登録のフロー" do
    # 管理ページのvisit時にマスター管理ユーザーが必要
    let!(:master_user) { create(:user, :master_admin) }
    let(:user) { create(:user, :admin) }

    before do
      sign_in_as(user)
      visit new_management_user_path
    end

    context "正常系" do
      scenario "一般ユーザーを新規登録する" do
        expect do
          fill_in "ニックネーム", with: "テストユーザー"
          fill_in "Eメールアドレス", with: "registration@example.test"
          # パスワード関連のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "user_password", with: "testpass123"
          fill_in "user_password_confirmation", with: "testpass123"
          click_button "登録"
        end.to change { User.count }.by(1)

        new_user = User.last
        expect(new_user.admin?).to be_falsey

        expect(page).to have_content "ユーザーの登録が完了しました。"
        expect(current_path).to eq management_users_path
      end

      scenario "管理ユーザーを新規登録する" do
        expect do
          choose "管理者"
          fill_in "ニックネーム", with: "テストユーザー"
          fill_in "Eメールアドレス", with: "registration@example.test"
          # パスワード関連のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "user_password", with: "testpass123"
          fill_in "user_password_confirmation", with: "testpass123"
          click_button "登録"
        end.to change { User.count }.by(1)

        new_user = User.last
        expect(new_user.admin?).to be_truthy

        expect(page).to have_content "ユーザーの登録が完了しました。"
        expect(current_path).to eq management_users_path
      end
    end

    context "異常系" do
      let(:valid_name) { "テストユーザー" }
      let(:valid_email) { "registration@example.test" }
      let(:valid_password) { "testpass123" }

      scenario "必須フィールドが空の状態でユーザー登録を試みる" do
        expect do
          click_button "登録"
        end.to_not change { User.count }

        expect(page).to have_content "ニックネームを入力してください。"
        expect(page).to have_content "Eメールアドレスを入力してください。"
        expect(page).to have_content "パスワードを入力してください。"
      end

      let(:over_length_name) { "a" * 21 }

      scenario "ニックネームの文字数がオーバーしている状態でユーザー登録を試みる" do
        expect do
          fill_in "ニックネーム", with: over_length_name
          fill_in "Eメールアドレス", with: valid_email
          # パスワード関連のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "user_password", with: valid_password
          fill_in "user_password_confirmation", with: valid_password
          click_button "登録"
        end.to_not change { User.count }

        expect(page).to have_content "ニックネームは#{User::MAX_LENGTH_NAME}文字以内で入力してください。"
      end

      scenario "既に登録済みのメールアドレスでユーザー登録を試みる" do
        expect do
          fill_in "ニックネーム", with: valid_name
          fill_in "Eメールアドレス", with: user.email
          # パスワード関連のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "user_password", with: valid_password
          fill_in "user_password_confirmation", with: valid_password
          click_button "登録"
        end.to_not change { User.count }

        expect(page).to have_content "Eメールアドレスはすでに存在します。"
      end

      let(:over_length_email) { "#{"a" * 244}@example.com" }

      scenario "メールアドレスの文字数がオーバーしている状態でユーザー登録を試みる" do
        expect do
          fill_in "ニックネーム", with: valid_name
          fill_in "Eメールアドレス", with: over_length_email
          # パスワード関連のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "user_password", with: valid_password
          fill_in "user_password_confirmation", with: valid_password
          click_button "登録"
        end.to_not change { User.count }

        expect(page).to have_content "Eメールアドレスは#{User::MAX_LENGTH_EMAIL}文字以内で入力してください。"
      end

      scenario "メールアドレスのフォーマットが正しくない状態でユーザー登録を試みる" do
        expect do
          fill_in "ニックネーム", with: valid_name
          fill_in "Eメールアドレス", with: "invalid-email"
          # パスワード関連のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "user_password", with: valid_password
          fill_in "user_password_confirmation", with: valid_password
          click_button "登録"
        end.to_not change { User.count }

        expect(page).to have_content "Eメールアドレスは不正な値です。"
      end

      let(:lack_length_password) { "pass123" }

      scenario "パスワードの文字数が不足している状態でユーザー登録を試みる" do
        expect do
          fill_in "ニックネーム", with: valid_name
          fill_in "Eメールアドレス", with: valid_email
          # パスワード関連のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "user_password", with: lack_length_password
          fill_in "user_password_confirmation", with: lack_length_password
          click_button "登録"
        end.to_not change { User.count }

        expect(page).to have_content "パスワードは#{Devise.password_length.min}文字以上で入力してください。"
      end

      let(:over_length_password) { "Ab1" * 43 } # 129文字

      scenario "パスワードの文字数がオーバーしている状態でユーザー登録を試みる" do
        expect do
          fill_in "ニックネーム", with: valid_name
          fill_in "Eメールアドレス", with: valid_email
          # パスワード関連のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "user_password", with: over_length_password
          fill_in "user_password_confirmation", with: over_length_password
          click_button "登録"
        end.to_not change { User.count }

        expect(page).to have_content "パスワードは#{Devise.password_length.max}文字以内で入力してください。"
      end

      let(:invalid_password) { "password" }

      scenario "パスワードのフォーマットが正しくない状態でユーザー登録を試みる" do
        expect do
          fill_in "ニックネーム", with: valid_name
          fill_in "Eメールアドレス", with: valid_email
          # パスワード関連のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "user_password", with: invalid_password
          fill_in "user_password_confirmation", with: invalid_password
          click_button "登録"
        end.to_not change { User.count }

        expect(page).to have_content "パスワードは不正な値です。"
      end

      scenario "パスワードとパスワード確認が一致しない状態でユーザー登録を試みる" do
        expect do
          fill_in "ニックネーム", with: valid_name
          fill_in "Eメールアドレス", with: valid_email
          # パスワード関連のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "user_password", with: "password123"
          fill_in "user_password_confirmation", with: "differentpass123"
          click_button "登録"
        end.to_not change { User.count }

        expect(page).to have_content "パスワード（確認用）とパスワードの入力が一致しません。"
      end
    end
  end

  describe "ユーザー更新のフロー" do
    # 管理ページのvisit時にマスター管理ユーザーが必要
    let!(:master_user) { create(:user, :master_admin) }
    let(:user) { create(:user, :admin) }
    let!(:edit_user) do
      create(:user, admin: false, name: "テストユーザー", email: "test-user@example.test", password: "password123", hiragana_view: false)
    end

    context "正常系" do
      let(:new_name) { "新しいユーザー名" }
      let(:new_email) { "new-test-user@example.test" }
      let(:new_password) { "newPass123" }

      before do
        sign_in_as(user)
        visit edit_management_user_path(edit_user.id)
      end

      scenario "ユーザーのユーザー区分を変更する" do
        expect do
          choose "管理者"
          click_button "更新"
        end.to change { edit_user.reload.admin }.from(false).to(true)

        expect(current_path).to eq management_users_path
        expect(page).to have_content "ユーザーの更新が完了しました。"
      end

      scenario "ユーザーのニックネームを更新する" do
        before_name = edit_user.name
        expect do
          fill_in "ニックネーム", with: new_name
          click_button "更新"
        end.to change { edit_user.reload.name }.from(before_name).to(new_name)

        expect(current_path).to eq management_users_path
        expect(page).to have_content "ユーザーの更新が完了しました。"
      end

      scenario "ユーザーのEメールアドレスを更新する" do
        before_email = edit_user.email
        expect do
          fill_in "Eメールアドレス", with: new_email
          click_button "更新"
        end.to change { edit_user.reload.email }.from(before_email).to(new_email)

        expect(current_path).to eq management_users_path
        expect(page).to have_content "ユーザーの更新が完了しました。"
      end

      scenario "ユーザーのパスワードを更新する" do
        expect(edit_user.valid_password?("password123")).to be_truthy

        expect do
          # パスワード関連のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "user_password", with: new_password
          fill_in "user_password_confirmation", with: new_password
          click_button "更新"
        end.to change { edit_user.reload.encrypted_password }
        expect(edit_user.valid_password?(new_password)).to be_truthy

        expect(current_path).to eq management_users_path
        expect(page).to have_content "ユーザーの更新が完了しました。"
      end

      scenario "パスワードとパスワード（確認用）のフィールドが空だとパスワードが更新されない" do
        expect do
          # パスワード関連のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "user_password", with: ""
          fill_in "user_password_confirmation", with: ""
          click_button "更新"
        end.to_not change { edit_user.reload.encrypted_password }
        expect(edit_user.valid_password?("password123")).to be_truthy
      end

      scenario "ユーザーのひらがなモードを変更する" do
        expect do
          choose "ON"
          click_button "更新"
        end.to change { edit_user.reload.hiragana_view }.from(false).to(true)

        expect(current_path).to eq management_users_path
        expect(page).to have_content "ユーザーの更新が完了しました。"
      end
    end

    context "異常系" do
      before do
        sign_in_as(user)
        visit edit_management_user_path(edit_user.id)
      end

      scenario "ニックネームが空の状態で更新を試みる" do
        expect do
          fill_in "ニックネーム", with: ""
          click_button "更新"
        end.to_not change { edit_user.reload.name }

        expect(page).to have_content "ニックネームを入力してください。"
        expect(page).to have_selector("h2", text: "編集情報の入力")
      end

      let(:over_length_name) { "a" * 21 }

      scenario "ニックネームの文字数がオーバーしている状態で更新を試みる" do
        expect do
          fill_in "ニックネーム", with: over_length_name
          click_button "更新"
        end.to_not change { edit_user.reload.name }

        expect(page).to have_content "ニックネームは#{User::MAX_LENGTH_NAME}文字以内で入力してください。"
        expect(page).to have_selector("h2", text: "編集情報の入力")
      end

      scenario "メールアドレスが空の状態で更新を試みる" do
        expect do
          fill_in "Eメールアドレス", with: ""
          click_button "更新"
        end.to_not change { edit_user.reload.unconfirmed_email }

        expect(page).to have_content "Eメールアドレスを入力してください。"
        expect(page).to have_selector("h2", text: "編集情報の入力")
      end

      let(:over_length_email) { "#{"a" * 244}@example.com" }

      scenario "メールアドレスの文字数がオーバーしている状態で更新を試みる" do
        expect do
          fill_in "Eメールアドレス", with: over_length_email
          click_button "更新"
        end.to_not change { edit_user.reload.unconfirmed_email }

        expect(page).to have_content "Eメールアドレスは#{User::MAX_LENGTH_EMAIL}文字以内で入力してください。"
        expect(page).to have_selector("h2", text: "編集情報の入力")
      end

      scenario "メールアドレスのフォーマットが正しくない状態で更新を試みる" do
        expect do
          fill_in "Eメールアドレス", with: "invalid-email"
          click_button "更新"
        end.to_not change { edit_user.reload.unconfirmed_email }

        expect(page).to have_content "Eメールアドレスは不正な値です。"
        expect(page).to have_selector("h2", text: "編集情報の入力")
      end

      let(:lack_length_password) { "pass123" }

      scenario "パスワードの文字数が不足している状態で更新を試みる" do
        expect do
          # パスワード関連のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "user_password", with: lack_length_password
          fill_in "user_password_confirmation", with: lack_length_password
          click_button "更新"
        end.to_not change { edit_user.reload.encrypted_password }

        expect(page).to have_content "パスワードは#{Devise.password_length.min}文字以上で入力してください。"
        expect(page).to have_selector("h2", text: "編集情報の入力")
      end

      let(:over_length_password) { "Ab1" * 43 } # 129文字

      scenario "パスワードの文字数がオーバーしている状態で更新を試みる" do
        expect do
          # パスワード関連のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "user_password", with: over_length_password
          fill_in "user_password_confirmation", with: over_length_password
          click_button "更新"
        end.to_not change { edit_user.reload.encrypted_password }

        expect(page).to have_content "パスワードは#{Devise.password_length.max}文字以内で入力してください"
        expect(page).to have_selector("h2", text: "編集情報の入力")
      end

      let(:invalid_password) { "password" }

      scenario "パスワードのフォーマットが正しくない状態で更新を試みる" do
        expect do
          # パスワード関連のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "user_password", with: invalid_password
          fill_in "user_password_confirmation", with: invalid_password
          click_button "更新"
        end.to_not change { edit_user.reload.encrypted_password }

        expect(page).to have_content "パスワードは不正な値です。"
        expect(page).to have_selector("h2", text: "編集情報の入力")
      end
    end

    describe "ゲストユーザーの編集制御のテスト" do
      let!(:guest_user) { User.guest }
      let(:new_name) { "新しいユーザー名" }
      let(:new_email) { "new-test-user@example.test" }
      let(:new_password) { "newPass123" }

      before do
        sign_in_as(user)
        # 操作ユーザー自身の編集ページにアクセス
        visit edit_management_user_path(guest_user.id)
      end

      scenario "ゲストユーザーのユーザー区分は変更できない" do
        expect do
          choose "管理者"
          click_button "更新"
        end.to_not change { guest_user.reload.admin }

        expect(page).to have_content "ユーザー区分は変更できません。ゲストユーザーの権限変更は制限されています。"
        expect(page).to have_selector("h2", text: "編集情報の入力")
      end

      scenario "ゲストユーザーのニックネームは変更できない" do
        expect do
          fill_in "ニックネーム", with: new_name
          click_button "更新"
        end.to_not change { guest_user.reload.name }

        expect(page).to have_content "ニックネームは変更できません。ゲストユーザーのニックネーム変更は制限されています。"
        expect(page).to have_selector("h2", text: "編集情報の入力")
      end

      scenario "ゲストユーザーのEメールアドレスは変更できない" do
        expect do
          fill_in "Eメールアドレス", with: new_email
          click_button "更新"
        end.to_not change { guest_user.reload.email }

        expect(page).to have_content "Eメールアドレスは変更できません。ゲストユーザーのメールアドレス変更は制限されています。"
        expect(page).to have_selector("h2", text: "編集情報の入力")
      end

      scenario "ゲストユーザーのパスワードは変更できない" do
        expect do
          # パスワード関連のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "user_password", with: new_password
          fill_in "user_password_confirmation", with: new_password
          click_button "更新"
        end.to_not change { guest_user.reload.encrypted_password }

        expect(page).to have_content "パスワードは変更できません。ゲストユーザーのパスワード変更は制限されています。"
        expect(page).to have_selector("h2", text: "編集情報の入力")
      end
    end

    describe "操作ユーザー自身の更新によるリダイレクトのテスト" do
      before do
        sign_in_as(user)
        # 操作ユーザー自身の編集ページにアクセス
        visit edit_management_user_path(user.id)
      end

      scenario "ユーザーが自身のユーザー区分を'一般'に更新する" do
        # ユーザー区分を'一般'に更新する
        choose "一般"
        click_button "更新"

        # 更新後メインメニュー画面にリダイレクトする
        expect(page).to have_content "更新が完了し管理者権限が解除されました。メインメニューにリダイレクトします。"
        expect(current_path).to eq root_path
        # 管理者機能へのリンクが存在しないことを確認
        expect(page).to_not have_link("管理者機能", href: management_users_path)
        # 管理者機能へのアクセスができないことを確認
        expect { visit management_users_path }.to raise_error(ActionController::RoutingError)
      end
    end
  end

  describe "ユーザー削除のフロー" do
    # 管理ページのvisit時にマスター管理ユーザーが必要
    let!(:master_user) { create(:user, :master_admin) }
    let(:user) { create(:user, :admin) }
    let!(:delete_user) { create(:user) }

    before do
      sign_in_as(user)
      # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
      expect(page).to have_content "ログインしました。"
      visit management_users_path
    end

    scenario "ユーザーを削除する", js: true do
      # ユーザー一覧から削除対象ユーザー削除ボタンをクリック
      within("tr", text: delete_user.email) do
        find("i.delete-icon").click
      end

      # アカウント削除のconfirmモーダルを確認
      expect(page).to have_selector("#turbo-confirm-modal", visible: true)
      within "#turbo-confirm-modal" do
        expect(page).to have_selector("h1", visible: true, text: "ユーザー（#{delete_user.email}）の削除")
      end

      expect do
        within "#turbo-confirm-modal" do
          click_button "削除する"
        end

        expect(page).to have_content "ユーザーが削除されました。"
        expect(current_path).to eq management_users_path
      end.to change { User.count }.by(-1)

      # 削除したユーザーがDBに存在しないことを確認
      expect(User.where(id: delete_user.id)).to_not exist
    end

    describe "操作ユーザー自身のユーザーアカウント削除によるリダイレクトのテスト" do
      scenario "ユーザーが自身のユーザーアカウントを削除する", js: true do
        # ユーザー一覧から自身のユーザー削除ボタンをクリック
        within("tr", text: user.email) do
          find("i.delete-icon").click
        end

        # アカウント削除のconfirmモーダルを確認
        expect(page).to have_selector("#turbo-confirm-modal", visible: true)
        within "#turbo-confirm-modal" do
          expect(page).to have_selector("h1", visible: true, text: "ユーザー（#{user.email}）の削除")
        end

        expect do
          within "#turbo-confirm-modal" do
            click_button "削除する"
          end

          # アカウント削除と同時にログアウトしrootページへリダイレクトする
          expect(page).to have_content "ログイン中の管理ユーザーが削除されました。再度登録が必要な場合は管理者に依頼してください。"
          expect(current_path).to eq root_path

          within "nav" do
            expect(page).to have_link("ログイン", href: new_user_session_path)
          end
        end.to change { User.count }.by(-1)

        # 削除したユーザーがDBに存在しないことを確認
        expect(User.where(id: user.id)).to_not exist
      end
    end
  end
end
