require 'rails_helper'

RSpec.describe "ManagementNotificationTargetUsers", type: :system do
  shared_examples "サイドバーにあるリンクの背景色CSSのテスト" do
    it "表示中のページ（通知ユーザー管理）のリンクに背景色のCSSが設定されていること" do
      within("ul.management-menu-list") do
        expect(page).to have_selector("li.bg-secondary-subtle", text: "通知ユーザー管理")
      end
    end

    it "表示中のページ（通知ユーザー管理）以外のリンクに背景色のCSSが設定されていないこと" do
      within("ul.management-menu-list") do
        # 通知ユーザー管理との部分一致を避けるため exact_text: true を使用する
        expect(page).to_not have_selector("li.bg-secondary-subtle", text: "ユーザー管理", exact_text: true)
        expect(page).to_not have_selector("li.bg-secondary-subtle", text: "アイテム管理")
        expect(page).to_not have_selector("li.bg-secondary-subtle", text: "お買い物管理")
      end
    end
  end

  describe "ビューの要素" do
    describe "index" do
      context "管理ユーザーの場合" do
        let(:user) { create(:user, :admin) }
        # ユーザー管理ページにアクセスするときにマスター管理ユーザーが必要
        let!(:master_user) { create(:user, :master_admin) }

        before do
          sign_in_as(user)
          visit management_notification_target_users_path
        end

        include_examples "ユーザー情報の表示テスト"

        include_examples "管理ページのサイドバーメニューのテスト"

        it_behaves_like "サイドバーにあるリンクの背景色CSSのテスト"

        it "ページタイトルが表示されること" do
          within "div.management-main" do
            expect(page).to have_selector("h2", text: "通知ユーザー管理")
          end
        end

        it "検索フォームが表示されること" do
          expect(page).to have_selector("form#notification_target_user_search")
          expect(page).to have_field("q_user_id_eq", type: "search", placeholder: "User_ID")
          expect(page).to have_field("q_email_cont", type: "search", placeholder: "Email 部分一致")
          expect(page).to have_button "検索"
        end

        it "通知ユーザー登録画面へのリンクが存在すること" do
          expect(page).to have_link("登録", href: new_management_notification_target_user_path)
        end

        it "通知ユーザー登録画面へのリンクをクリックして通知ユーザー登録画面へ遷移すること" do
          within "div.management-main" do
            click_link "登録"
          end

          expect(page).to have_http_status(:success)
          expect(current_path).to eq new_management_notification_target_user_path
        end

        it "通知ユーザー一覧テーブルの各見出しが表示されること" do
          within "thead" do
            expect(page).to have_selector("th", text: "ID")
            expect(page).to have_selector("th", text: "User_ID")
            expect(page).to have_selector("th", text: "Name")
            expect(page).to have_selector("th", text: "Email")
            expect(page).to have_selector("th", text: "Confirmation_status")
            expect(page).to have_selector("th", text: "Created_at")
            expect(page).to have_selector("th", text: "Updated_at")
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
          expect { visit management_notification_target_users_path }.to raise_error(ActionController::RoutingError)
        end
      end

      context "サインインしていない場合" do
        it "404エラーになること" do
          expect { visit management_notification_target_users_path }.to raise_error(ActionController::RoutingError)
        end
      end

      describe "各通知ユーザーの情報表示・ボタンのテスト" do
        # それぞれidを固定してテーブルの情報表示テスト時に他カラムの値と重複が発生しないようにする
        let(:user) { create(:user, :admin, id: 111) }
        let(:other_user) { create(:user, id: 222) }
        let!(:notification_target_user1) { create(:notification_target_user, id: 333, user: user) }
        let!(:notification_target_user2) { create(:notification_target_user, id: 444, user: other_user) }

        describe "通知ユーザー状態で共通のテスト" do
          before do
            sign_in_as(user)
            # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
            expect(page).to have_content "ログインしました。"
            visit management_notification_target_users_path
          end

          it "通知ユーザー毎にID、親ユーザーID、ニックネーム、Eメールアドレス、作成・更新日時が表示されること" do
            within("tr", text: notification_target_user1.email) do
              expect(page).to have_selector("td", text: notification_target_user1.id, exact_text: true)
              expect(page).to have_selector("td", text: notification_target_user1.user_id, exact_text: true)
              expect(page).to have_selector("td", text: notification_target_user1.name)
              expect(page).to have_selector("td", text: notification_target_user1.email)
              expect(page).to have_selector("td", text: notification_target_user1.created_at.to_fs(:date_time))
              expect(page).to have_selector("td", text: notification_target_user1.updated_at.to_fs(:date_time))
            end

            within("tr", text: notification_target_user2.email) do
              expect(page).to have_selector("td", text: notification_target_user2.id, exact_text: true)
              expect(page).to have_selector("td", text: notification_target_user2.user_id, exact_text: true)
              expect(page).to have_selector("td", text: notification_target_user2.name)
              expect(page).to have_selector("td", text: notification_target_user2.email)
              expect(page).to have_selector("td", text: notification_target_user2.created_at.to_fs(:date_time))
              expect(page).to have_selector("td", text: notification_target_user2.updated_at.to_fs(:date_time))
            end
          end

          it "通知ユーザー毎の行に削除ボタンが存在すること" do
            within("tr", text: notification_target_user1.email) do
              expect(page).to have_selector("i.delete-icon")
            end

            within("tr", text: notification_target_user2.email) do
              expect(page).to have_selector("i.delete-icon")
            end
          end

          it "通知ユーザー削除ボタンをクリックするとモーダルが表示されること", js: true do
            expect(page).to have_selector("#turbo-confirm-modal", visible: false)

            within("tr", text: notification_target_user1.email) do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)
          end

          it "通知ユーザー削除モーダルにタイトルが表示されること", js: true do
            within("tr", text: notification_target_user1.email) do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            within "#turbo-confirm-modal" do
              expect(page).to have_selector("h1", visible: true, text: "通知ユーザー（ID: #{notification_target_user1.id}）の削除")
            end
          end

          it "通知ユーザー削除モーダルのヘッダーにモーダルを閉じるボタンがあること", js: true do
            within("tr", text: notification_target_user1.email) do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            within "#turbo-confirm-modal" do
              within ".modal-header" do
                expect(page).to have_selector("button.btn-close", visible: true)
              end
            end
          end

          it "通知ユーザー削除モーダルに削除ボタン・キャンセルボタンが表示されること", js: true do
            within("tr", text: notification_target_user1.email) do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            within "#turbo-confirm-modal" do
              expect(page).to have_selector("button", visible: true, text: "削除する")
              expect(page).to have_selector("button", visible: true, text: "キャンセル")
            end
          end

          it "通知ユーザー削除モーダルのキャンセルボタンでお買い物削除を中止できること", js: true do
            within("tr", text: notification_target_user1.email) do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            within "#turbo-confirm-modal" do
              click_button "キャンセル"
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: false)
          end

          it "通知ユーザー削除モーダルの外をクリックするとモーダルが閉じること", js: true do
            within("tr", text: notification_target_user1.email) do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            # モーダルの外をクリック
            page.execute_script("document.querySelector('body').click();")

            expect(page).to have_selector("#turbo-confirm-modal", visible: false)
          end
        end

        describe "一覧に表示される通知ユーザーの状態で異なる箇所のテスト" do
          context "認証済みの場合" do
            let!(:confirmed_nt_user) { create(:notification_target_user, user: user, confirmation_status: :confirmed) }

            before do
              sign_in_as(user)
              visit management_notification_target_users_path
            end

            it "'認証完了'の表示が存在すること" do
              within("tr", text: confirmed_nt_user.id) do
                expect(page).to have_selector("td", text: "認証完了")
              end
            end
          end

          context "未認証の場合" do
            let!(:unconfirmed_nt_user) { create(:notification_target_user, user: user, confirmation_status: :unconfirmed) }

            before do
              sign_in_as(user)
              visit management_notification_target_users_path
            end

            it "'未認証'の表示が存在すること" do
              within("tr", text: unconfirmed_nt_user.id) do
                expect(page).to have_selector("td", text: "未認証")
              end
            end
          end
        end
      end

      describe "ページネーションのテスト" do
        let(:user) { create(:user, :admin) }
        let!(:users) { create_list(:user, 25) }
        # 25ユーザーで2件ずつの通知ユーザーを作成し登録通知ユーザーを50件にする
        let!(:notification_target_users) do
          users.flat_map do |user|
            create_list(:notification_target_user, 2, user: user)
          end
        end
        let(:one_pagenation_max_size) { 50 }

        context "表示対象の通知ユーザー件数が50件以下の場合" do
          before do
            # 通知ユーザーの件数が50件であることを確認
            expect(NotificationTargetUser.count).to eq(one_pagenation_max_size)

            sign_in_as(user)
            visit management_notification_target_users_path
          end

          it "ページネーションのナビゲーションが存在しないこと" do
            expect(page).to_not have_selector("nav.pagy-nav")
          end
        end

        context "表示対象の通知ユーザー件数が50件を超える場合" do
          let!(:nt_user_51st) { create(:notification_target_user, user: user) } # 登録通知ユーザーを51件にする
          let(:one_pagenation_over_size) { 51 }

          before do
            # 通知ユーザーの件数が51件であることを確認
            expect(NotificationTargetUser.count).to eq(one_pagenation_over_size)

            sign_in_as(user)
            visit management_notification_target_users_path
          end

          it "最初のページに50件の通知ユーザーが表示されること" do
            notification_target_users.each do |nt_user|
              expect(page).to have_selector("tr", text: nt_user.email)
            end
          end

          it "最初のページに51件目の通知ユーザーが表示されないこと" do
            expect(page).to_not have_selector("tr", text: nt_user_51st.email)
          end

          it "ページネーションのナビゲーションが存在すること" do
            expect(page).to have_selector("nav.pagy-nav")
          end

          it "ページネーションの別のページへのリンクが存在すること" do
            within "nav.pagy-nav" do
              expect(page).to have_link("2", href: management_notification_target_users_path(page: 2))
              expect(page).to have_link("次", href: management_notification_target_users_path(page: 2))
            end
          end

          it "1ページ目（現在のページ）のリンクが存在しないこと" do
            within "nav.pagy-nav" do
              expect(page).to_not have_link("1", href: management_notification_target_users_path(page: 1))
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
              expect(URI.parse(current_url).request_uri).to eq management_notification_target_users_path(page: 2)
            end

            it "51件目の通知ユーザーが表示されること" do
              expect(page).to have_selector("tr", text: nt_user_51st.email)
            end

            it "最初のページの50件の通知ユーザーが表示されないこと" do
              notification_target_users.each do |nt_user|
                expect(page).to_not have_selector("tr", text: nt_user.email)
              end
            end

            it "ページネーションの別のページへのリンクが存在すること" do
              within "nav.pagy-nav" do
                expect(page).to have_link("前", href: management_notification_target_users_path(page: 1))
                expect(page).to have_link("1", href: management_notification_target_users_path(page: 1))
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
                expect(page).to_not have_link("2", href: management_notification_target_users_path(page: 2))
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

      describe "表示件数のテスト" do
        let(:user) { create(:user, :admin) }

        context "初期状態の場合" do
          let!(:users) { create_list(:user, 30) }
          # 30ユーザーで2件ずつの通知ユーザーを作成し登録通知ユーザーを60件にする
          # （表示件数がページネーションに関係しないことを確認するため50件以上に設定する）
          let!(:notification_target_users) do
            users.flat_map do |user|
              create_list(:notification_target_user, 2, user: user)
            end
          end
          let(:nt_user_count) { 60 }

          before do
            sign_in_as(user)
            visit management_notification_target_users_path
          end

          it "初期状態では登録済み通知ユーザーの件数が表示されること" do
            expect(NotificationTargetUser.count).to eq nt_user_count
            expect(page).to have_selector("h5", text: "件数： #{nt_user_count} 件")
          end
        end

        context "検索機能で絞り込む場合" do
          let!(:other_user) { create(:user) }
          # 2ユーザーで3件ずつ計6件の通知ユーザーを作成する
          let!(:user_nt_users) { create_list(:notification_target_user, 3, user: user) }
          let!(:other_user_nt_users) { create_list(:notification_target_user, 3, user: other_user) }
          let(:all_nt_user_count) { 6 }
          let(:user_nt_user_count) { 3 }

          before do
            sign_in_as(user)
            visit management_notification_target_users_path
          end

          it "検索による絞り込み後の通知ユーザー件数が表示されること" do
            # 初期状態の通知ユーザー件数表示を確認
            expect(NotificationTargetUser.count).to eq all_nt_user_count
            expect(page).to have_selector("h5", text: "件数： #{all_nt_user_count} 件")

            # 親ユーザーIDによる検索
            fill_in "q_user_id_eq", with: user.id
            click_button "検索"

            # 絞り込み後の通知ユーザー件数表示を確認
            expect(page).to have_selector("h5", text: "件数： #{user_nt_user_count} 件")
          end
        end
      end
    end

    describe "new" do
      context "管理ユーザーの場合" do
        let(:user) { create(:user, :admin) }
        # ユーザー管理ページにアクセスするときにマスター管理ユーザーが必要
        let!(:master_user) { create(:user, :master_admin) }

        before do
          sign_in_as(user)
          visit new_management_notification_target_user_path
        end

        include_examples "ユーザー情報の表示テスト"

        include_examples "管理ページのサイドバーメニューのテスト"

        it_behaves_like "サイドバーにあるリンクの背景色CSSのテスト"

        it "ページタイトルが表示されること" do
          within "div.management-main" do
            expect(page).to have_selector("h2", text: "通知ユーザー登録")
          end
        end

        it "戻るリンクが表示されること" do
          expect(page).to have_link "戻る"
        end

        it "通知ユーザー登録フォームが表示されること" do
          within "form.new_user" do
            expect(page).to have_selector("h2", text: "登録情報の入力")
            expect(page).to have_field("親ユーザーID")
            expect(page).to have_field("ニックネーム")
            expect(page).to have_field("Eメールアドレス")
            expect(page).to have_selector("label.h5", text: "認証区分")
            expect(page).to have_select("notification_target_user[confirmation_status]", options: ["未認証", "認証完了"])
            expect(page).to have_button("登録")
          end
        end

        it "フォームの認証区分のセレクトボックスは初期状態で'未認証(unconfirmed)'が選択されていること" do
          within "form.new_user" do
            expect(find_field("notification_target_user[confirmation_status]").value).to eq "unconfirmed"
          end
        end
      end

      context "管理ユーザー以外の場合" do
        let(:user) { create(:user) }

        before do
          sign_in_as(user)
        end

        it "404エラーになること" do
          expect { visit new_management_notification_target_user_path }.to raise_error(ActionController::RoutingError)
        end
      end

      context "サインインしていない場合" do
        it "404エラーになること" do
          expect { visit new_management_notification_target_user_path }.to raise_error(ActionController::RoutingError)
        end
      end

      describe "戻るリンクのテスト" do
        let(:user) { create(:user, :admin) }
        let!(:users) { create_list(:user, 25) }
        # 25ユーザーで2件ずつの通知ユーザーを作成し登録通知ユーザーを50件にする
        let!(:notification_target_users) do
          users.flat_map do |user|
            create_list(:notification_target_user, 2, user: user)
          end
        end
        # 登録通知ユーザーを51件にする
        let!(:nt_user_51st) { create(:notification_target_user, user: user) }
        # 戻るリンクのテストに必要な変数を定義
        let(:test_index_page_path) { management_notification_target_users_path }
        let(:test_index_page2_path) { management_notification_target_users_path(page: 2) }
        let(:test_page_path) { new_management_notification_target_user_path }
        let(:td_text) { nt_user_51st.email }

        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
        end

        include_examples "back_linkによる戻るリンクのテスト"
      end
    end
  end

  describe "通知ユーザー一覧のソート・検索機能のテスト" do
    let(:user1) { create(:user, :admin, id: 1) }
    let(:user2) { create(:user, id: 2) }
    let(:user3) { create(:user, id: 3) }
    let!(:notification_target_user1) do
      create(
        :notification_target_user,
        id: 1,
        user_id: user1.id,
        name: "Alice",
        email: "alice@example.com",
        confirmation_status: :confirmed,
        created_at: 1.day.ago,
        updated_at: 1.day.ago
      )
    end
    let!(:notification_target_user2) do
      create(
        :notification_target_user,
        id: 2,
        user_id: user2.id,
        name: "Bob",
        email: "bob@example.com",
        confirmation_status: :unconfirmed,
        created_at: 2.days.ago,
        updated_at: 2.days.ago
      )
    end
    let!(:notification_target_user3) do
      create(
        :notification_target_user,
        id: 3,
        user_id: user3.id,
        name: "Charlie",
        email: "charlie@example.net",
        confirmation_status: :confirmed,
        created_at: 3.days.ago,
        updated_at: 3.days.ago
      )
    end

    before do
      sign_in_as(user1)
      visit management_notification_target_users_path
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

      context "IDでソートする場合" do
        it "IDの昇順でソートされること" do
          # IDの見出しでテスト（User_IDの見出しと重複しないようにwithinとfindで指定）
          within find("th", text: "ID", match: :first) do
            click_link "ID"
          end

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "alice@example.com")
            expect(rows[1]).to have_selector("td", text: "bob@example.com")
            expect(rows[2]).to have_selector("td", text: "charlie@example.net")
          end
        end

        it "IDの降順でソートされること" do
          within find("th", text: "ID", match: :first) do
            click_link "ID" # 1回目のクリックで昇順
            click_link "ID" # 2回目のクリックで降順
          end

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "charlie@example.net")
            expect(rows[1]).to have_selector("td", text: "bob@example.com")
            expect(rows[2]).to have_selector("td", text: "alice@example.com")
          end
        end
      end

      context "親ユーザーID（User_ID）でソートする場合" do
        it "親ユーザーID（User_ID）の昇順でソートされること" do
          click_link "User_ID"

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "alice@example.com")
            expect(rows[1]).to have_selector("td", text: "bob@example.com")
            expect(rows[2]).to have_selector("td", text: "charlie@example.net")
          end
        end

        it "親ユーザーID（User_ID）の降順でソートされること" do
          click_link "User_ID" # 1回目のクリックで昇順
          click_link "User_ID" # 2回目のクリックで降順

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

      context "認証区分（Confirmation_status）でソートする場合" do
        it "未認証、認証完了の順でソートされること" do
          click_link "Confirmation_status"

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "bob@example.com")
            expect(rows[1]).to have_selector("td", text: "alice@example.com")
            expect(rows[2]).to have_selector("td", text: "charlie@example.net")
          end
        end

        it "認証完了、未認証の順でソートされること" do
          click_link "Confirmation_status" # 1回目のクリックで昇順
          click_link "Confirmation_status" # 2回目のクリックで降順

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
      it "親ユーザーIDで通知ユーザーの絞り込みができること" do
        fill_in "q_user_id_eq", with: "2"
        click_button "検索"

        within "tbody" do
          expect(page).to_not have_selector("td", text: "alice@example.com")
          expect(page).to have_selector("td", text: "bob@example.com")
          expect(page).to_not have_selector("td", text: "charlie@example.net")
        end
      end

      it "Eメールアドレスで通知ユーザーの絞り込みができること" do
        fill_in "q_email_cont", with: "alice"
        click_button "検索"

        within "tbody" do
          expect(page).to have_selector("td", text: "alice@example.com")
          expect(page).to_not have_selector("td", text: "bob@example.com")
          expect(page).to_not have_selector("td", text: "charlie@example.net")
        end
      end
    end

    describe "ソート・検索機能の組み合わせ" do
      it "通知ユーザーを検索で絞り込んだあとにソートできること" do
        fill_in "q_email_cont", with: ".com"
        click_button "検索"

        within "tbody" do
          rows = all("tr")
          expect(rows[0]).to have_selector("td", text: "alice@example.com")
          expect(rows[1]).to have_selector("td", text: "bob@example.com")
          expect(page).to_not have_selector("td", text: "charlie@example.net")
        end

        # Eメールアドレスの昇順でソート
        click_link "Email"
        within "tbody" do
          rows = all("tr")
          expect(rows[0]).to have_selector("td", text: "alice@example.com")
          expect(rows[1]).to have_selector("td", text: "bob@example.com")
          expect(page).to_not have_selector("td", text: "charlie@example.net")
        end

        # Eメールアドレスの降順でソート
        click_link "Email"
        within "tbody" do
          rows = all("tr")
          expect(rows[0]).to have_selector("td", text: "bob@example.com")
          expect(rows[1]).to have_selector("td", text: "alice@example.com")
          expect(page).to_not have_selector("td", text: "charlie@example.net")
        end
      end
    end
  end

  describe "通知ユーザー登録のフロー" do
    let(:user) { create(:user, :admin, id: 1) }

    before do
      sign_in_as(user)
      visit new_management_notification_target_user_path
    end

    context "正常系" do
      scenario "未認証状態の通知ユーザーを登録する" do
        expect do
          fill_in "親ユーザーID", with: user.id
          fill_in "ニックネーム", with: "テスト通知ユーザー"
          fill_in "Eメールアドレス", with: "registration-ntu@example.test"
          select "未認証", from: "notification_target_user[confirmation_status]"
          click_button "登録"
        end.to change { NotificationTargetUser.count }.by(1)

        new_nt_user = NotificationTargetUser.last
        expect(new_nt_user.unconfirmed?).to be_truthy

        expect(page).to have_content "通知ユーザーの登録が完了しました。"
        expect(current_path).to eq management_notification_target_users_path
      end

      scenario "認証完了状態の通知ユーザーを登録する" do
        expect do
          fill_in "親ユーザーID", with: user.id
          fill_in "ニックネーム", with: "テスト通知ユーザー"
          fill_in "Eメールアドレス", with: "registration-ntu@example.test"
          select "認証完了", from: "notification_target_user[confirmation_status]"
          click_button "登録"
        end.to change { NotificationTargetUser.count }.by(1)

        new_nt_user = NotificationTargetUser.last
        expect(new_nt_user.confirmed?).to be_truthy

        expect(page).to have_content "通知ユーザーの登録が完了しました。"
        expect(current_path).to eq management_notification_target_users_path
      end
    end

    context "異常系" do
      let(:valid_user_id) { user.id }
      let(:valid_name) { "テスト通知ユーザー" }
      let(:valid_email) { "registration-ntu@example.test" }

      scenario "必須フィールドが空の状態で通知ユーザー登録を試みる" do
        expect do
          click_button "登録"
        end.to_not change { NotificationTargetUser.count }

        expect(page).to have_content "登録されているユーザーIDを入力してください。"
        expect(page).to have_content "ニックネームを入力してください。"
        expect(page).to have_content "Eメールアドレスを入力してください。"
      end

      let(:invalid_user_id) { 999 }

      scenario "存在しないユーザーのIDを入力している状態で通知ユーザー登録を試みる" do
        expect do
          fill_in "親ユーザーID", with: invalid_user_id
          fill_in "ニックネーム", with: valid_name
          fill_in "Eメールアドレス", with: valid_email
          click_button "登録"
        end.to_not change { NotificationTargetUser.count }

        expect(page).to have_content "登録されているユーザーIDを入力してください。"
      end

      let(:over_length_name) { "a" * 21 }

      scenario "ニックネームの文字数がオーバーしている状態で通知ユーザー登録を試みる" do
        expect do
          fill_in "親ユーザーID", with: valid_user_id
          fill_in "ニックネーム", with: over_length_name
          fill_in "Eメールアドレス", with: valid_email
          click_button "登録"
        end.to_not change { NotificationTargetUser.count }

        expect(page).to have_content "ニックネームは#{NotificationTargetUser::MAX_LENGTH_NAME}文字以内で入力してください。"
      end

      let(:over_length_email) { "#{"a" * 244}@example.com" }

      scenario "メールアドレスの文字数がオーバーしている状態で通知ユーザー登録を試みる" do
        expect do
          fill_in "親ユーザーID", with: valid_user_id
          fill_in "ニックネーム", with: valid_name
          fill_in "Eメールアドレス", with: over_length_email
          click_button "登録"
        end.to_not change { NotificationTargetUser.count }

        expect(page).to have_content "Eメールアドレスは#{NotificationTargetUser::MAX_LENGTH_EMAIL}文字以内で入力してください。"
      end

      scenario "メールアドレスのフォーマットが正しくない状態で通知ユーザー登録を試みる" do
        expect do
          fill_in "親ユーザーID", with: valid_user_id
          fill_in "ニックネーム", with: valid_name
          fill_in "Eメールアドレス", with: "invalid-email"
          click_button "登録"
        end.to_not change { NotificationTargetUser.count }

        expect(page).to have_content "Eメールアドレスは不正な値です。"
      end
    end

    describe "ユーザーに紐づく通知ユーザーの登録制御のテスト" do
      context "異常系" do
        let(:user) { create(:user, :admin) }
        let!(:max_notification_target_users) { create_list(:notification_target_user, 3, user: user) }

        scenario "ユーザーに紐づく通知ユーザーが最大登録数に達した状態で同ユーザーの通知ユーザー登録を試みる" do
          expect do
            fill_in "親ユーザーID", with: user.id
            fill_in "ニックネーム", with: "テスト通知ユーザー"
            fill_in "Eメールアドレス", with: "registration-ntu@example.test"
            select "未認証", from: "notification_target_user[confirmation_status]"
            click_button "登録"
          end.to_not change { NotificationTargetUser.count }

          expect(page).to have_content "通知メールアドレスの登録数が最大数（3つ）に達しています。"
        end
      end
    end
  end

  describe "通知ユーザー削除のフロー" do
    let(:user) { create(:user, :admin) }
    let!(:delete_nt_user) { create(:notification_target_user, user: user) }

    before do
      sign_in_as(user)
      # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
      expect(page).to have_content "ログインしました。"
      visit management_notification_target_users_path
    end

    scenario "通知ユーザーを削除する", js: true do
      # 通知ユーザー一覧から削除対象の通知ユーザー削除ボタンをクリック
      within("tr", text: delete_nt_user.email) do
        find("i.delete-icon").click
      end

      # 通知ユーザー削除のconfirmモーダルを確認
      expect(page).to have_selector("#turbo-confirm-modal", visible: true)
      within "#turbo-confirm-modal" do
        expect(page).to have_selector("h1", visible: true, text: "通知ユーザー（ID: #{delete_nt_user.id}）の削除")
      end

      expect do
        within "#turbo-confirm-modal" do
          click_button "削除する"
        end

        expect(page).to have_content "通知ユーザーが削除されました。"
        expect(current_path).to eq management_notification_target_users_path
      end.to change { NotificationTargetUser.count }.by(-1)

      # 削除した通知ユーザーがDBに存在しないことを確認
      expect(NotificationTargetUser.where(id: delete_nt_user.id)).to_not exist
    end
  end
end
