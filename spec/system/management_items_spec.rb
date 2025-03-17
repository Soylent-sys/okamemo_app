require 'rails_helper'

RSpec.describe "ManagementItems", type: :system do
  shared_examples "サイドバーにあるリンクの背景色CSSのテスト" do
    it "表示中のページ（アイテム管理）のリンクに背景色のCSSが設定されていること" do
      within("ul.management-menu-list") do
        expect(page).to have_selector("li.bg-secondary-subtle", text: "アイテム管理")
      end
    end

    it "表示中のページ（アイテム管理）以外のリンクに背景色のCSSが設定されていないこと" do
      within("ul.management-menu-list") do
        # 通知ユーザー管理との部分一致を避けるため exact_text: true を使用する
        expect(page).to_not have_selector("li.bg-secondary-subtle", text: "ユーザー管理", exact_text: true)
        expect(page).to_not have_selector("li.bg-secondary-subtle", text: "通知ユーザー管理")
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
          visit management_items_path
        end

        include_examples "ユーザー情報の表示テスト"

        include_examples "管理ページのサイドバーメニューのテスト"

        it_behaves_like "サイドバーにあるリンクの背景色CSSのテスト"

        it "ページタイトルが表示されること" do
          within "div.management-main" do
            expect(page).to have_selector("h2", text: "アイテム管理")
          end
        end

        it "検索フォームが表示されること" do
          expect(page).to have_selector("form#item_search")
          expect(page).to have_field("q_user_id_eq", type: "search", placeholder: "User_ID")
          expect(page).to have_field("q_category_id_eq", type: "search", placeholder: "Category_ID")
          expect(page).to have_field("q_name_cont", type: "search", placeholder: "Name 部分一致")
          expect(page).to have_button "検索"
        end

        it "アイテム登録画面へのリンクが存在すること" do
          expect(page).to have_link("登録", href: new_management_item_path)
        end

        it "アイテム登録画面へのリンクをクリックしてアイテム登録画面へ遷移すること" do
          within "div.management-main" do
            click_link "登録"
          end

          expect(page).to have_http_status(:success)
          expect(current_path).to eq new_management_item_path
        end

        it "アイテム一覧テーブルの各見出しが表示されること" do
          within "thead" do
            expect(page).to have_selector("th", text: "ID")
            expect(page).to have_selector("th", text: "User_ID")
            expect(page).to have_selector("th", text: "Category_ID")
            expect(page).to have_selector("th", text: "Category_name(parent table)")
            expect(page).to have_selector("th", text: "Name")
            expect(page).to have_selector("th", text: "Hiragana")
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
          expect { visit management_items_path }.to raise_error(ActionController::RoutingError)
        end
      end

      context "サインインしていない場合" do
        it "404エラーになること" do
          expect { visit management_items_path }.to raise_error(ActionController::RoutingError)
        end
      end

      describe "各アイテムの情報表示・ボタンのテスト" do
        # それぞれidを固定してテーブルの情報表示テスト時に他カラムの値と重複が発生しないようにする
        let(:user) { create(:user, :admin, id: 111) }
        let(:other_user) { create(:user, id: 222) }
        # アイテムのcreate時にマスター管理ユーザーが必要
        let!(:master_user) { create(:user, :master_admin) }
        let(:category1) { create(:category, id: 333) }
        let(:category2) { create(:category, id: 444) }
        let!(:item1) { create(:item, id: 555, user: user, category: category1) }
        let!(:item2) { create(:item, id: 666, user: other_user, category: category2) }

        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
          visit management_items_path
        end

        it "アイテム毎にID、親ユーザーID、親カテゴリーID、アイテム名、アイテムひらがな名、作成・更新日時が表示されること" do
          within("tr", text: item1.name) do
            expect(page).to have_selector("td", text: item1.id, exact_text: true)
            expect(page).to have_selector("td", text: item1.user_id, exact_text: true)
            expect(page).to have_selector("td", text: item1.category_id, exact_text: true)
            expect(page).to have_selector("td", text: item1.category.name)
            expect(page).to have_selector("td", text: item1.name)
            expect(page).to have_selector("td", text: item1.hiragana)
            expect(page).to have_selector("td", text: item1.created_at.to_fs(:date_time))
            expect(page).to have_selector("td", text: item1.updated_at.to_fs(:date_time))
          end

          within("tr", text: item2.name) do
            expect(page).to have_selector("td", text: item2.id, exact_text: true)
            expect(page).to have_selector("td", text: item2.user_id, exact_text: true)
            expect(page).to have_selector("td", text: item2.category_id, exact_text: true)
            expect(page).to have_selector("td", text: item2.category.name)
            expect(page).to have_selector("td", text: item2.name)
            expect(page).to have_selector("td", text: item2.hiragana)
            expect(page).to have_selector("td", text: item2.created_at.to_fs(:date_time))
            expect(page).to have_selector("td", text: item2.updated_at.to_fs(:date_time))
          end
        end

        it "アイテム毎に更新画面へのリンクが存在すること" do
          within("tr", text: item1.name) do
            expect(page).to have_selector("i.edit-icon")
            expect(page).to have_link(href: edit_management_item_path(item1.id))
          end

          within("tr", text: item2.name) do
            expect(page).to have_selector("i.edit-icon")
            expect(page).to have_link(href: edit_management_item_path(item2.id))
          end
        end

        it "アイテムの更新画面へのリンクをクリックして該当アイテムの更新画面へ遷移すること" do
          within("tr", text: item1.name) do
            click_link(href: edit_management_item_path(item1.id))
          end

          expect(page).to have_http_status(:success)
          expect(current_path).to eq edit_management_item_path(item1.id)
        end

        it "アイテム毎の行に削除ボタンが存在すること" do
          within("tr", text: item1.name) do
            expect(page).to have_selector("i.delete-icon")
          end

          within("tr", text: item2.name) do
            expect(page).to have_selector("i.delete-icon")
          end
        end

        it "アイテム削除ボタンをクリックするとモーダルが表示されること", js: true do
          expect(page).to have_selector("#turbo-confirm-modal", visible: false)

          within("tr", text: item1.name) do
            find("i.delete-icon").click
          end

          expect(page).to have_selector("#turbo-confirm-modal", visible: true)
        end

        it "アイテム削除モーダルにタイトルが表示されること", js: true do
          within("tr", text: item1.name) do
            find("i.delete-icon").click
          end

          expect(page).to have_selector("#turbo-confirm-modal", visible: true)

          within "#turbo-confirm-modal" do
            expect(page).to have_selector("h1", visible: true, text: "アイテム（ID: #{item1.id}）の削除")
          end
        end

        it "アイテム削除モーダルのヘッダーにモーダルを閉じるボタンがあること", js: true do
          within("tr", text: item1.name) do
            find("i.delete-icon").click
          end

          expect(page).to have_selector("#turbo-confirm-modal", visible: true)

          within "#turbo-confirm-modal" do
            within ".modal-header" do
              expect(page).to have_selector("button.btn-close", visible: true)
            end
          end
        end

        it "アイテム削除モーダルに削除ボタン・キャンセルボタンが表示されること", js: true do
          within("tr", text: item1.name) do
            find("i.delete-icon").click
          end

          expect(page).to have_selector("#turbo-confirm-modal", visible: true)

          within "#turbo-confirm-modal" do
            expect(page).to have_selector("button", visible: true, text: "削除する")
            expect(page).to have_selector("button", visible: true, text: "キャンセル")
          end
        end

        it "アイテム削除モーダルのキャンセルボタンでお買い物削除を中止できること", js: true do
          within("tr", text: item1.name) do
            find("i.delete-icon").click
          end

          expect(page).to have_selector("#turbo-confirm-modal", visible: true)

          within "#turbo-confirm-modal" do
            click_button "キャンセル"
          end

          expect(page).to have_selector("#turbo-confirm-modal", visible: false)
        end

        it "アイテム削除モーダルの外をクリックするとモーダルが閉じること", js: true do
          within("tr", text: item1.name) do
            find("i.delete-icon").click
          end

          expect(page).to have_selector("#turbo-confirm-modal", visible: true)

          # モーダルの外をクリック
          page.execute_script("document.querySelector('body').click();")

          expect(page).to have_selector("#turbo-confirm-modal", visible: false)
        end
      end

      describe "ページネーションのテスト" do
        let(:user) { create(:user, :admin) }
        # アイテムのcreate時にマスター管理ユーザーが必要
        let!(:master_user) { create(:user, :master_admin) }
        let(:category) { create(:category) }
        let!(:items) { create_list(:item, 50, user: user, category: category) }
        let(:one_pagenation_max_size) { 50 }

        context "表示対象のアイテム件数が50件以下の場合" do
          before do
            # アイテムの件数が50件であることを確認
            expect(Item.count).to eq(one_pagenation_max_size)

            sign_in_as(user)
            visit management_items_path
          end

          it "ページネーションのナビゲーションが存在しないこと" do
            expect(page).to_not have_selector("nav.pagy-nav")
          end
        end

        context "表示対象のアイテム件数が50件を超える場合" do
          let!(:item_51st) { create(:item, user: user, category: category) } # アイテムを51件にする
          let(:one_pagenation_over_size) { 51 }

          before do
            # アイテムの件数が51件であることを確認
            expect(Item.count).to eq(one_pagenation_over_size)

            sign_in_as(user)
            visit management_items_path
          end

          it "最初のページに50件のアイテムが表示されること" do
            items.each do |item|
              expect(page).to have_selector("tr", text: item.name)
            end
          end

          it "最初のページに51件目のアイテムが表示されないこと" do
            expect(page).to_not have_selector("tr", text: item_51st.name)
          end

          it "ページネーションのナビゲーションが存在すること" do
            expect(page).to have_selector("nav.pagy-nav")
          end

          it "ページネーションの別のページへのリンクが存在すること" do
            within "nav.pagy-nav" do
              expect(page).to have_link("2", href: management_items_path(page: 2))
              expect(page).to have_link("次", href: management_items_path(page: 2))
            end
          end

          it "1ページ目（現在のページ）のリンクが存在しないこと" do
            within "nav.pagy-nav" do
              expect(page).to_not have_link("1", href: management_items_path(page: 1))
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
              expect(URI.parse(current_url).request_uri).to eq management_items_path(page: 2)
            end

            it "51件目のアイテムが表示されること" do
              expect(page).to have_selector("tr", text: item_51st.name)
            end

            it "最初のページの50件のアイテムが表示されないこと" do
              items.each do |item|
                expect(page).to_not have_selector("tr", text: item.name)
              end
            end

            it "ページネーションの別のページへのリンクが存在すること" do
              within "nav.pagy-nav" do
                expect(page).to have_link("前", href: management_items_path(page: 1))
                expect(page).to have_link("1", href: management_items_path(page: 1))
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
                expect(page).to_not have_link("2", href: management_items_path(page: 2))
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
        # アイテムのcreate時にマスター管理ユーザーが必要
        let!(:master_user) { create(:user, :master_admin) }
        let!(:category) { create(:category) }

        context "初期状態の場合" do
          # アイテムを100件にする（表示件数がページネーションに関係しないことを確認するため50件以上に設定する）
          let!(:items) { create_list(:item, 100, user: user, category: category) }
          let(:item_count) { 100 }

          before do
            sign_in_as(user)
            visit management_items_path
          end

          it "初期状態では登録済みアイテムの件数が表示されること" do
            expect(Item.count).to eq item_count
            expect(page).to have_selector("h5", text: "件数： #{item_count} 件")
          end
        end

        context "検索機能で絞り込む場合" do
          let!(:other_category) { create(:category) }
          # categoryのアイテム10個とother_categoryのアイテム5個で計15件のアイテムを作成する
          let!(:category_items) { create_list(:item, 10, user: user, category: category) }
          let!(:other_user_nt_users) { create_list(:item, 5, user: user, category: other_category) }
          let(:all_item_count) { 15 }
          let(:category_item_count) { 10 }

          before do
            sign_in_as(user)
            visit management_items_path
          end

          it "検索による絞り込み後の通知ユーザー件数が表示されること" do
            # 初期状態のアイテム件数表示を確認
            expect(Item.count).to eq all_item_count
            expect(page).to have_selector("h5", text: "件数： #{all_item_count} 件")

            # カテゴリーIDによる検索
            fill_in "q_category_id_eq", with: category.id
            click_button "検索"

            # 絞り込み後のアイテム件数表示を確認
            expect(page).to have_selector("h5", text: "件数： #{category_item_count} 件")
          end
        end
      end

      describe "モバイルデバイス時の警告表示のテスト" do
        let(:user) { create(:user, :admin) }

        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
          visit management_items_path
        end

        include_examples "管理画面のモバイルデバイス非対応警告のテスト"
      end
    end

    describe "new" do
      context "管理ユーザーの場合" do
        let(:user) { create(:user, :admin) }
        # ユーザー管理ページへのアクセス・アイテムの登録時にマスター管理ユーザーが必要
        let!(:master_user) { create(:user, :master_admin) }
        # 登録フォームのカテゴリーのセレクトボックスで選択可能なカテゴリーを準備
        let!(:categories) { create_list(:category, 3) }

        before do
          sign_in_as(user)
          visit new_management_item_path
        end

        include_examples "ユーザー情報の表示テスト"

        include_examples "管理ページのサイドバーメニューのテスト"

        it_behaves_like "サイドバーにあるリンクの背景色CSSのテスト"

        it "ページタイトルが表示されること" do
          within "div.management-main" do
            expect(page).to have_selector("h2", text: "アイテム登録")
          end
        end

        it "戻るリンクが表示されること" do
          expect(page).to have_link "戻る"
        end

        it "アイテム登録フォームが表示されること" do
          within("form", text: "登録情報の入力") do
            expect(page).to have_selector("h2", text: "登録情報の入力")
            expect(page).to have_field("親ユーザーID")
            expect(page).to have_select("item[category_id]", options: ["カテゴリーを選択", categories.map(&:name)].flatten)
            expect(page).to have_field("アイテム名")
            expect(page).to have_field("ひらがな（アイテム名）")
            expect(page).to have_button("登録")
          end
        end
      end

      context "管理ユーザー以外の場合" do
        let(:user) { create(:user) }

        before do
          sign_in_as(user)
        end

        it "404エラーになること" do
          expect { visit new_management_item_path }.to raise_error(ActionController::RoutingError)
        end
      end

      context "サインインしていない場合" do
        it "404エラーになること" do
          expect { visit new_management_item_path }.to raise_error(ActionController::RoutingError)
        end
      end

      describe "戻るリンクのテスト" do
        let(:user) { create(:user, :admin) }
        # アイテムのcreate時にマスター管理ユーザーが必要
        let!(:master_user) { create(:user, :master_admin) }
        let(:category) { create(:category) }
        # アイテムを50件にする
        let!(:items) { create_list(:item, 50, user: user, category: category) }
        # アイテムを51件にする
        let!(:item_51st) { create(:item, user: user, category: category) }
        # 戻るリンクのテストに必要な変数を定義
        let(:test_index_page_path) { management_items_path }
        let(:test_index_page2_path) { management_items_path(page: 2) }
        let(:test_page_path) { new_management_item_path }
        let(:td_text) { item_51st.name }

        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
        end

        include_examples "back_linkによる戻るリンクのテスト"
      end

      describe "モバイルデバイス時の警告表示のテスト" do
        let(:user) { create(:user, :admin) }

        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
          visit new_management_item_path
        end

        include_examples "管理画面のモバイルデバイス非対応警告のテスト"
      end
    end

    describe "edit" do
      context "管理ユーザーの場合" do
        let(:user) { create(:user, :admin) }
        # ユーザー管理ページへのアクセス・アイテムの登録時にマスター管理ユーザーが必要
        let!(:master_user) { create(:user, :master_admin) }
        let(:category) { create(:category) }
        let!(:other_category) { create(:category) }
        let!(:item) { create(:item, user: user, category: category) }

        before do
          sign_in_as(user)
          visit edit_management_item_path(item.id)
        end

        include_examples "ユーザー情報の表示テスト"

        include_examples "管理ページのサイドバーメニューのテスト"

        it_behaves_like "サイドバーにあるリンクの背景色CSSのテスト"

        it "ページタイトルが表示されること" do
          within "div.management-main" do
            expect(page).to have_selector("h2", text: "アイテム編集")
          end
        end

        it "戻るリンクが表示されること" do
          expect(page).to have_link "戻る"
        end

        it "編集対象アイテムのIDが表示されること" do
          within("tr", text: "アイテムID") do
            expect(page).to have_content item.id
          end
        end

        it "編集対象アイテムの親ユーザーIDが表示されること" do
          within("tr", text: "親ユーザーID") do
            expect(page).to have_content item.user.id
          end
        end

        it "アイテム登録フォームが表示されること" do
          within("form", text: "編集情報の入力") do
            expect(page).to have_selector("h2", text: "編集情報の入力")
            expect(page).to have_select("item[category_id]", options: [category.name, other_category.name])
            expect(page).to have_field("アイテム名")
            expect(page).to have_field("ひらがな（アイテム名）")
            expect(page).to have_button("更新")
          end
        end
      end

      context "管理ユーザー以外の場合" do
        let(:user) { create(:user) }
        # アイテムのcreate時にマスター管理ユーザーが必要
        let!(:master_user) { create(:user, :master_admin) }
        let(:category) { create(:category) }
        let!(:item) { create(:item, user: user, category: category) }

        before do
          sign_in_as(user)
        end

        it "404エラーになること" do
          expect { visit edit_management_item_path(item.id) }.to raise_error(ActionController::RoutingError)
        end
      end

      context "サインインしていない場合" do
        let(:user) { create(:user) }
        # アイテムのcreate時にマスター管理ユーザーが必要
        let!(:master_user) { create(:user, :master_admin) }
        let(:category) { create(:category) }
        let!(:item) { create(:item, user: user, category: category) }

        it "404エラーになること" do
          expect { visit edit_management_item_path(item.id) }.to raise_error(ActionController::RoutingError)
        end
      end

      describe "戻るリンクのテスト" do
        let(:user) { create(:user, :admin) }
        # アイテムのcreate時にマスター管理ユーザーが必要
        let!(:master_user) { create(:user, :master_admin) }
        let(:category) { create(:category) }
        # アイテムを50件にする
        let!(:items) { create_list(:item, 50, user: user, category: category) }
        # アイテムを51件にする
        let!(:item_51st) { create(:item, user: user, category: category) }
        # 戻るリンクのテストに必要な変数を定義
        let(:test_index_page_path) { management_items_path }
        let(:test_index_page2_path) { management_items_path(page: 2) }
        let(:test_page_path) { edit_management_item_path(item_51st.id) }
        let(:td_text) { item_51st.name }

        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
        end

        include_examples "back_linkによる戻るリンクのテスト"
      end

      describe "モバイルデバイス時の警告表示のテスト" do
        let(:user) { create(:user, :admin) }
        # アイテムのcreate時にマスター管理ユーザーが必要
        let!(:master_user) { create(:user, :master_admin) }
        let(:category) { create(:category) }
        let!(:item) { create(:item, user: user, category: category) }

        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
          visit edit_management_item_path(item.id)
        end

        include_examples "管理画面のモバイルデバイス非対応警告のテスト"
      end
    end
  end

  describe "アイテム一覧のソート・検索機能のテスト" do
    # アイテムの登録時にマスター管理ユーザーが必要
    let!(:master_user) { create(:user, :master_admin) }

    describe "ソート機能" do
      context "共通項目のテスト" do
        let(:user) { create(:user, :admin) }
        let(:category) { create(:category) }
        let!(:item1) { create(:item, id: 1, user: user, category: category, name: "apple") }
        let!(:item2) { create(:item, id: 2, user: user, category: category, name: "broccoli") }
        let!(:item3) { create(:item, id: 3, user: user, category: category, name: "carrot") }

        before do
          sign_in_as(user)
          visit management_items_path
        end

        it "デフォルトではIDの昇順になっていること" do
          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "apple")
            expect(rows[1]).to have_selector("td", text: "broccoli")
            expect(rows[2]).to have_selector("td", text: "carrot")
          end
        end

        include_examples "ソート順による見出しのCSSのテスト"
      end

      context "IDでソートする場合" do
        let(:user) { create(:user, :admin) }
        let(:category) { create(:category) }
        let!(:item1) { create(:item, id: 1, user: user, category: category, name: "apple") }
        let!(:item2) { create(:item, id: 2, user: user, category: category, name: "broccoli") }
        let!(:item3) { create(:item, id: 3, user: user, category: category, name: "carrot") }

        before do
          sign_in_as(user)
          visit management_items_path
        end

        it "IDの昇順でソートされること" do
          # IDの見出しでテスト（User_ID、Category_IDの見出しと重複しないようにwithinとfindで指定）
          within find("th", text: "ID", match: :first) do
            click_link "ID"
          end

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "apple")
            expect(rows[1]).to have_selector("td", text: "broccoli")
            expect(rows[2]).to have_selector("td", text: "carrot")
          end
        end

        it "IDの降順でソートされること" do
          within find("th", text: "ID", match: :first) do
            click_link "ID" # 1回目のクリックで昇順
            click_link "ID" # 2回目のクリックで降順
          end

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "carrot")
            expect(rows[1]).to have_selector("td", text: "broccoli")
            expect(rows[2]).to have_selector("td", text: "apple")
          end
        end
      end

      context "親ユーザーID（User_ID）でソートする場合" do
        let(:user1) { create(:user, :admin, id: 1) }
        let(:user2) { create(:user, id: 2) }
        let(:user3) { create(:user, id: 3) }
        let(:category) { create(:category) }
        let!(:item1) { create(:item, user: user1, category: category, name: "apple") }
        let!(:item2) { create(:item, user: user2, category: category, name: "broccoli") }
        let!(:item3) { create(:item, user: user3, category: category, name: "carrot") }

        before do
          sign_in_as(user1)
          visit management_items_path
        end

        it "親ユーザーID（User_ID）の昇順でソートされること" do
          within find("th", text: "User_ID") do
            click_link "User_ID"
          end

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "apple")
            expect(rows[1]).to have_selector("td", text: "broccoli")
            expect(rows[2]).to have_selector("td", text: "carrot")
          end
        end

        it "親ユーザーID（User_ID）の降順でソートされること" do
          within find("th", text: "User_ID") do
            click_link "User_ID" # 1回目のクリックで昇順
            click_link "User_ID" # 2回目のクリックで降順
          end

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "carrot")
            expect(rows[1]).to have_selector("td", text: "broccoli")
            expect(rows[2]).to have_selector("td", text: "apple")
          end
        end
      end

      context "カテゴリーID（Category_ID）でソートする場合" do
        let(:user) { create(:user, :admin) }
        let(:category1) { create(:category, id: 1) }
        let(:category2) { create(:category, id: 2) }
        let(:category3) { create(:category, id: 3) }
        let!(:item1) { create(:item, user: user, category: category1, name: "apple") }
        let!(:item2) { create(:item, user: user, category: category2, name: "broccoli") }
        let!(:item3) { create(:item, user: user, category: category3, name: "carrot") }

        before do
          sign_in_as(user)
          visit management_items_path
        end

        it "カテゴリーID（Category_ID）の昇順でソートされること" do
          within find("th", text: "Category_ID") do
            click_link "Category_ID"
          end

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "apple")
            expect(rows[1]).to have_selector("td", text: "broccoli")
            expect(rows[2]).to have_selector("td", text: "carrot")
          end
        end

        it "カテゴリーID（Category_ID）の降順でソートされること" do
          within find("th", text: "Category_ID") do
            click_link "Category_ID" # 1回目のクリックで昇順
            click_link "Category_ID" # 2回目のクリックで降順
          end

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "carrot")
            expect(rows[1]).to have_selector("td", text: "broccoli")
            expect(rows[2]).to have_selector("td", text: "apple")
          end
        end
      end

      context "カテゴリー名（Category_name）でソートする場合" do
        let(:user) { create(:user, :admin) }
        let(:category1) { create(:category, name: "Aカテゴリ") }
        let(:category2) { create(:category, name: "Bカテゴリ") }
        let(:category3) { create(:category, name: "Cカテゴリ") }
        let!(:item1) { create(:item, user: user, category: category1, name: "apple") }
        let!(:item2) { create(:item, user: user, category: category2, name: "broccoli") }
        let!(:item3) { create(:item, user: user, category: category3, name: "carrot") }

        before do
          sign_in_as(user)
          visit management_items_path
        end

        it "カテゴリー名の昇順でソートされること" do
          within find("th", text: "Category_name(parent table)") do
            click_link "Category_name(parent table)"
          end

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "apple")
            expect(rows[1]).to have_selector("td", text: "broccoli")
            expect(rows[2]).to have_selector("td", text: "carrot")
          end
        end

        it "カテゴリー名の降順でソートされること" do
          within find("th", text: "Category_name(parent table)") do
            click_link "Category_name(parent table)" # 1回目のクリックで昇順
            click_link "Category_name(parent table)" # 2回目のクリックで降順
          end

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "carrot")
            expect(rows[1]).to have_selector("td", text: "broccoli")
            expect(rows[2]).to have_selector("td", text: "apple")
          end
        end
      end

      context "アイテム名（Name）でソートする場合" do
        let(:user) { create(:user, :admin) }
        let(:category) { create(:category) }
        let!(:item1) { create(:item, user: user, category: category, name: "apple") }
        let!(:item2) { create(:item, user: user, category: category, name: "broccoli") }
        let!(:item3) { create(:item, user: user, category: category, name: "carrot") }

        before do
          sign_in_as(user)
          visit management_items_path
        end

        it "アイテム名の昇順でソートされること" do
          within find("th", text: "Name") do
            click_link "Name"
          end

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "apple")
            expect(rows[1]).to have_selector("td", text: "broccoli")
            expect(rows[2]).to have_selector("td", text: "carrot")
          end
        end

        it "アイテム名の降順でソートされること" do
          within find("th", text: "Name") do
            click_link "Name" # 1回目のクリックで昇順
            click_link "Name" # 2回目のクリックで降順
          end

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "carrot")
            expect(rows[1]).to have_selector("td", text: "broccoli")
            expect(rows[2]).to have_selector("td", text: "apple")
          end
        end
      end

      context "アイテムひらがな名（Hiragana）でソートする場合" do
        let(:user) { create(:user, :admin) }
        let(:category) { create(:category) }
        let!(:item1) { create(:item, user: user, category: category, hiragana: "あすぱら") }
        let!(:item2) { create(:item, user: user, category: category, hiragana: "いちじく") }
        let!(:item3) { create(:item, user: user, category: category, hiragana: "うど") }

        before do
          sign_in_as(user)
          visit management_items_path
        end

        it "アイテムひらがな名の昇順でソートされること" do
          within find("th", text: "Hiragana") do
            click_link "Hiragana"
          end

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "あすぱら")
            expect(rows[1]).to have_selector("td", text: "いちじく")
            expect(rows[2]).to have_selector("td", text: "うど")
          end
        end

        it "アイテムひらがな名の降順でソートされること" do
          within find("th", text: "Hiragana") do
            click_link "Hiragana" # 1回目のクリックで昇順
            click_link "Hiragana" # 2回目のクリックで降順
          end

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "うど")
            expect(rows[1]).to have_selector("td", text: "いちじく")
            expect(rows[2]).to have_selector("td", text: "あすぱら")
          end
        end
      end

      context "作成日時(Created_at)でソートする場合" do
        let(:user) { create(:user, :admin) }
        let(:category) { create(:category) }
        let!(:item1) { create(:item, user: user, category: category, name: "apple", created_at: 1.day.ago) }
        let!(:item2) { create(:item, user: user, category: category, name: "broccoli", created_at: 2.day.ago) }
        let!(:item3) { create(:item, user: user, category: category, name: "carrot", created_at: 3.day.ago) }

        before do
          sign_in_as(user)
          visit management_items_path
        end

        it "作成日時の昇順でソートされること" do
          within find("th", text: "Created_at") do
            click_link "Created_at"
          end

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "carrot")
            expect(rows[1]).to have_selector("td", text: "broccoli")
            expect(rows[2]).to have_selector("td", text: "apple")
          end
        end

        it "作成日時の降順でソートされること" do
          within find("th", text: "Created_at") do
            click_link "Created_at" # 1回目のクリックで昇順
            click_link "Created_at" # 2回目のクリックで降順
          end

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "apple")
            expect(rows[1]).to have_selector("td", text: "broccoli")
            expect(rows[2]).to have_selector("td", text: "carrot")
          end
        end
      end

      context "更新日時(Updated_at)でソートする場合" do
        let(:user) { create(:user, :admin) }
        let(:category) { create(:category) }
        let!(:item1) { create(:item, user: user, category: category, name: "apple", updated_at: 1.day.ago) }
        let!(:item2) { create(:item, user: user, category: category, name: "broccoli", updated_at: 2.day.ago) }
        let!(:item3) { create(:item, user: user, category: category, name: "carrot", updated_at: 3.day.ago) }

        before do
          sign_in_as(user)
          visit management_items_path
        end

        it "更新日時の昇順でソートされること" do
          within find("th", text: "Updated_at") do
            click_link "Updated_at"
          end

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "carrot")
            expect(rows[1]).to have_selector("td", text: "broccoli")
            expect(rows[2]).to have_selector("td", text: "apple")
          end
        end

        it "更新日時の降順でソートされること" do
          within find("th", text: "Updated_at") do
            click_link "Updated_at" # 1回目のクリックで昇順
            click_link "Updated_at" # 2回目のクリックで降順
          end

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "apple")
            expect(rows[1]).to have_selector("td", text: "broccoli")
            expect(rows[2]).to have_selector("td", text: "carrot")
          end
        end
      end
    end

    describe "検索機能" do
      let(:user1) { create(:user, :admin, id: 1) }
      let(:user2) { create(:user, id: 2) }
      let(:category1) { create(:category, id: 1) }
      let(:category2) { create(:category, id: 2) }
      let!(:item1) { create(:item, user: user1, category: category1, name: "apple") }
      let!(:item2) { create(:item, user: user1, category: category2, name: "apple juice") }
      let!(:item3) { create(:item, user: user2, category: category1, name: "broccoli") }

      before do
        sign_in_as(user1)
        visit management_items_path
      end

      it "親ユーザーIDでアイテムの絞り込みができること" do
        fill_in "q_user_id_eq", with: "1"
        click_button "検索"

        within "tbody" do
          expect(page).to have_selector("td", text: "apple")
          expect(page).to have_selector("td", text: "apple juice")
          expect(page).to_not have_selector("td", text: "broccoli")
        end
      end

      it "カテゴリーIDでアイテムの絞り込みができること" do
        fill_in "q_category_id_eq", with: "1"
        click_button "検索"

        within "tbody" do
          expect(page).to have_selector("td", text: "apple")
          expect(page).to_not have_selector("td", text: "apple juice")
          expect(page).to have_selector("td", text: "broccoli")
        end
      end

      it "アイテム名でアイテムの絞り込みができること" do
        fill_in "q_name_cont", with: "apple"
        click_button "検索"

        within "tbody" do
          expect(page).to have_selector("td", text: "apple")
          expect(page).to have_selector("td", text: "apple juice")
          expect(page).to_not have_selector("td", text: "broccoli")
        end
      end
    end

    describe "ソート・検索機能の組み合わせ" do
      let(:user) { create(:user, :admin) }
      let(:category) { create(:category) }
      let!(:item1) { create(:item, user: user, category: category, name: "apple") }
      let!(:item2) { create(:item, user: user, category: category, name: "apple juice") }
      let!(:item3) { create(:item, user: user, category: category, name: "broccoli") }

      before do
        sign_in_as(user)
        visit management_items_path
      end

      it "アイテムを検索で絞り込んだあとにソートできること" do
        fill_in "q_name_cont", with: "apple"
        click_button "検索"

        within "tbody" do
          rows = all("tr")
          expect(rows[0]).to have_selector("td", text: "apple")
          expect(rows[1]).to have_selector("td", text: "apple juice")
          expect(page).to_not have_selector("td", text: "broccoli")
        end

        # アイテム名の昇順でソート
        click_link "Name"
        within "tbody" do
          rows = all("tr")
          expect(rows[0]).to have_selector("td", text: "apple")
          expect(rows[1]).to have_selector("td", text: "apple juice")
          expect(page).to_not have_selector("td", text: "broccoli")
        end

        # アイテム名の降順でソート
        click_link "Name"
        within "tbody" do
          rows = all("tr")
          expect(rows[0]).to have_selector("td", text: "apple juice")
          expect(rows[1]).to have_selector("td", text: "apple")
          expect(page).to_not have_selector("td", text: "broccoli")
        end
      end
    end
  end

  describe "アイテム登録のフロー" do
    # アイテムの登録・バリデーション時にマスター管理ユーザーが必要
    let!(:master_user) { create(:user, :master_admin, id: 1) }
    let(:user) { create(:user, :admin, id: 2) }
    let!(:category) { create(:category) }

    describe "親ユーザーの区分で共通のフロー" do
      before do
        sign_in_as(user)
        visit new_management_item_path
      end

      context "正常系" do
        scenario "アイテムを登録する" do
          expect do
            fill_in "親ユーザーID", with: user.id
            select category.name, from: "item[category_id]"
            # アイテム名、ひらがな（アイテム名）のフィールドはラベル文字列だと重複して扱われるためidを指定
            fill_in "item_name", with: "テストアイテム1"
            fill_in "item_hiragana", with: "てすとあいてむ1"
            click_button "登録"
          end.to change { Item.count }.by(1)

          expect(page).to have_content "アイテムの登録が完了しました。"
          expect(current_path).to eq management_items_path
        end
      end

      context "異常系" do
        let(:valid_name) { "テストアイテム1" }
        let(:valid_hiragana) { "てすとあいてむ1" }
        let!(:exist_item) { create(:item, user: user, category: category, name: "既存アイテム", hiragana: "きぞんあいてむ") }
        let!(:preset_item) { create(:item, user: master_user, category: category, name: "デフォルトアイテム", hiragana: "でふぉるとあいてむ") }

        scenario "必須フィールドが空・未選択の状態でアイテム登録を試みる" do
          expect do
            click_button "登録"
          end.to_not change { Item.count }

          expect(page).to have_content "登録されているユーザーIDを入力してください。"
          expect(page).to have_content "カテゴリーを入力してください。"
          expect(page).to have_content "アイテム名を入力してください。"
          expect(page).to have_content "ひらがな（アイテム名）を入力してください。"
        end

        let(:invalid_user_id) { 999 }

        scenario "親ユーザーのIDに存在していないIDを入力してアイテム登録を試みる" do
          expect do
            fill_in "親ユーザーID", with: invalid_user_id
            select category.name, from: "item[category_id]"
            # アイテム名、ひらがな（アイテム名）のフィールドはラベル文字列だと重複して扱われるためidを指定
            fill_in "item_name", with: valid_name
            fill_in "item_hiragana", with: valid_hiragana
            click_button "登録"
          end.to_not change { Item.count }

          expect(page).to have_content "登録されているユーザーIDを入力してください。"
        end

        let(:over_length_name) { "a" * 21 }

        scenario "アイテム名の文字数がオーバーしている状態でアイテム登録を試みる" do
          expect do
            fill_in "親ユーザーID", with: user.id
            select category.name, from: "item[category_id]"
            # アイテム名、ひらがな（アイテム名）のフィールドはラベル文字列だと重複して扱われるためidを指定
            fill_in "item_name", with: over_length_name
            fill_in "item_hiragana", with: valid_hiragana
            click_button "登録"
          end.to_not change { Item.count }

          expect(page).to have_content "アイテム名は#{Item::MAX_LENGTH_NAME}文字以内で入力してください。"
        end

        let(:over_length_hiragana) { "あ" * 21 }

        scenario "ひらがな（アイテム名）の文字数がオーバーしている状態でアイテム登録を試みる" do
          expect do
            fill_in "親ユーザーID", with: user.id
            select category.name, from: "item[category_id]"
            # アイテム名、ひらがな（アイテム名）のフィールドはラベル文字列だと重複して扱われるためidを指定
            fill_in "item_name", with: valid_name
            fill_in "item_hiragana", with: over_length_hiragana
            click_button "登録"
          end.to_not change { Item.count }

          expect(page).to have_content "ひらがな（アイテム名）は#{Item::MAX_LENGTH_HIRAGANA}文字以内で入力してください。"
        end

        let(:invalid_hiragana) { "テストアイテム壱" }

        scenario "ひらがな（アイテム名）を平仮名と半角数字以外で入力している状態でアイテム登録を試みる" do
          expect do
            fill_in "親ユーザーID", with: user.id
            select category.name, from: "item[category_id]"
            # アイテム名、ひらがな（アイテム名）のフィールドはラベル文字列だと重複して扱われるためidを指定
            fill_in "item_name", with: valid_name
            fill_in "item_hiragana", with: invalid_hiragana
            click_button "登録"
          end.to_not change { Item.count }

          expect(page).to have_content "ひらがな（アイテム名）の項目は平仮名・半角数字のみ使用してください。"
        end

        scenario "登録済みのアイテムと同じカテゴリー、アイテム名で登録を試みる" do
          expect do
            fill_in "親ユーザーID", with: user.id
            select exist_item.category.name, from: "item[category_id]"
            # アイテム名、ひらがな（アイテム名）のフィールドはラベル文字列だと重複して扱われるためidを指定
            fill_in "item_name", with: exist_item.name
            fill_in "item_hiragana", with: valid_hiragana
            click_button "登録"
          end.to_not change { Item.count }

          expect(page).to have_content "アイテム名は同じカテゴリーの中で二つ以上登録できません。"
        end

        scenario "登録済みのアイテムと同じカテゴリー、ひらがな（アイテム名）で登録を試みる" do
          expect do
            fill_in "親ユーザーID", with: user.id
            select exist_item.category.name, from: "item[category_id]"
            # アイテム名、ひらがな（アイテム名）のフィールドはラベル文字列だと重複して扱われるためidを指定
            fill_in "item_name", with: valid_name
            fill_in "item_hiragana", with: exist_item.hiragana
            click_button "登録"
          end.to_not change { Item.count }

          expect(page).to have_content "ひらがな（アイテム名）は同じカテゴリーの中で二つ以上登録できません。"
        end

        scenario "デフォルトアイテム（マスター管理ユーザーの登録アイテム）と同じカテゴリー、アイテム名で登録を試みる" do
          expect do
            fill_in "親ユーザーID", with: user.id
            select preset_item.category.name, from: "item[category_id]"
            # アイテム名、ひらがな（アイテム名）のフィールドはラベル文字列だと重複して扱われるためidを指定
            fill_in "item_name", with: preset_item.name
            fill_in "item_hiragana", with: valid_hiragana
            click_button "登録"
          end.to_not change { Item.count }

          expect(page).to have_content "アイテム名が同じカテゴリーに存在するデフォルトアイテムと重複しています。"
        end

        scenario "デフォルトアイテム（マスター管理ユーザーの登録アイテム）と同じカテゴリー、ひらがな（アイテム名）で登録を試みる" do
          expect do
            fill_in "親ユーザーID", with: user.id
            select preset_item.category.name, from: "item[category_id]"
            # アイテム名、ひらがな（アイテム名）のフィールドはラベル文字列だと重複して扱われるためidを指定
            fill_in "item_name", with: valid_name
            fill_in "item_hiragana", with: preset_item.hiragana
            click_button "登録"
          end.to_not change { Item.count }

          expect(page).to have_content "ひらがな（アイテム名）が同じカテゴリーに存在するデフォルトアイテムと重複しています。"
        end
      end
    end

    describe "親ユーザーの区分で異なるフロー" do
      context "親ユーザーが一般・管理ユーザーの場合" do
        let!(:max_user_items) { create_list(:item, 150, user: user, category: category) }

        before do
          sign_in_as(user)
          visit new_management_item_path
        end

        context "異常系" do
          scenario "アイテムの最大登録数に達した状態で登録を試みる" do
            expect do
              fill_in "親ユーザーID", with: user.id
              select category.name, from: "item[category_id]"
              # アイテム名、ひらがな（アイテム名）のフィールドはラベル文字列だと重複して扱われるためidを指定
              fill_in "item_name", with: "テストアイテム"
              fill_in "item_hiragana", with: "てすとあいてむ"
              click_button "登録"
            end.to_not change { Item.count }

            expect(page).to have_content "登録できるアイテムは#{Item::ITEM_MAXIMUM_COUNT}個までです。新しく登録する場合は登録済みアイテムを削除してください。"
          end
        end
      end

      context "親ユーザーがマスター管理ユーザーの場合" do
        let(:general_user_item_maximum_count) { 150 }
        let!(:master_user_items) { create_list(:item, general_user_item_maximum_count, user: master_user, category: category) }

        before do
          sign_in_as(user)
          visit new_management_item_path
        end

        context "正常系" do
          scenario "マスター管理ユーザーにはアイテム最大登録数を超えてアイテム登録ができる" do
            expect do
              fill_in "親ユーザーID", with: master_user.id
              select category.name, from: "item[category_id]"
              # アイテム名、ひらがな（アイテム名）のフィールドはラベル文字列だと重複して扱われるためidを指定
              fill_in "item_name", with: "テストアイテム"
              fill_in "item_hiragana", with: "てすとあいてむ"
              click_button "登録"
            end.to change { Item.count }.by(1)

            expect(page).to have_content "アイテムの登録が完了しました。"
            expect(current_path).to eq management_items_path
          end
        end
      end

      context "親ユーザーがゲストユーザーの場合" do
        let(:guest_user) { User.guest }
        let!(:max_guest_user_items) { create_list(:item, 10, user: guest_user, category: category) }

        before do
          sign_in_as(user)
          visit new_management_item_path
        end

        context "異常系" do
          scenario "ゲストユーザーのアイテムの最大登録数に達した状態で登録を試みる" do
            expect do
              fill_in "親ユーザーID", with: guest_user.id
              select category.name, from: "item[category_id]"
              # アイテム名、ひらがな（アイテム名）のフィールドはラベル文字列だと重複して扱われるためidを指定
              fill_in "item_name", with: "テストアイテム"
              fill_in "item_hiragana", with: "てすとあいてむ"
              click_button "登録"
            end.to_not change { Item.count }

            expect(page).to have_content "ゲストユーザーが登録できるアイテムは#{Item::GUEST_ITEM_MAXIMUM_COUNT}個までです。新しく登録する場合は登録済みアイテムを削除してください。"
          end
        end
      end
    end
  end

  describe "アイテム更新のフロー" do
    let(:user) { create(:user, :admin) }
    # アイテムの登録・バリデーション時にマスター管理ユーザーが必要
    let!(:master_user) { create(:user, :master_admin) }
    let(:category1) { create(:category) }
    let!(:category2) { create(:category) }
    let!(:edit_item) { create(:item, user: user, category: category1, name: "編集アイテム1", hiragana: "へんしゅうあいてむ1") }

    context "正常系" do
      let(:new_name) { "新しいアイテム名" }
      let(:new_hiragana) { "あたらしいひらがな" }

      before do
        sign_in_as(user)
        visit edit_management_item_path(edit_item.id)
      end

      scenario "カテゴリーを更新する" do
        expect do
          select category2.name, from: "item[category_id]"
          click_button "更新"
        end.to change { edit_item.reload.category_id }.from(category1.id).to(category2.id)

        expect(page).to have_content "アイテムの更新が完了しました。"
        expect(current_path).to eq management_items_path
      end

      scenario "アイテム名を更新する" do
        before_name = edit_item.name
        expect do
          # アイテム名、ひらがな（アイテム名）のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "item_name", with: new_name
          click_button "更新"
        end.to change { edit_item.reload.name }.from(before_name).to(new_name)

        expect(page).to have_content "アイテムの更新が完了しました。"
        expect(current_path).to eq management_items_path
      end

      scenario "ひらがな（アイテム名）を更新する" do
        before_hiragana = edit_item.hiragana
        expect do
          # アイテム名、ひらがな（アイテム名）のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "item_hiragana", with: new_hiragana
          click_button "更新"
        end.to change { edit_item.reload.hiragana }.from(before_hiragana).to(new_hiragana)

        expect(page).to have_content "アイテムの更新が完了しました。"
        expect(current_path).to eq management_items_path
      end
    end

    context "異常系" do
      let!(:exist_item) { create(:item, user: user, category: category1, name: "既存アイテム", hiragana: "きぞんあいてむ") }
      let!(:preset_item) { create(:item, user: master_user, category: category1, name: "デフォルトアイテム", hiragana: "でふぉるとあいてむ") }

      before do
        sign_in_as(user)
        visit edit_management_item_path(edit_item.id)
      end

      scenario "アイテム名のフィールドが空の状態でアイテム更新を試みる" do
        expect do
          # アイテム名、ひらがな（アイテム名）のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "item_name", with: ""
          click_button "更新"
        end.to_not change { Item.count }

        expect(page).to have_content "アイテム名を入力してください。"
      end

      let(:over_length_name) { "a" * 21 }

      scenario "アイテム名の文字数がオーバーしている状態でアイテム更新を試みる" do
        expect do
          # アイテム名、ひらがな（アイテム名）のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "item_name", with: over_length_name
          click_button "更新"
        end.to_not change { Item.count }

        expect(page).to have_content "アイテム名は#{Item::MAX_LENGTH_NAME}文字以内で入力してください。"
      end

      scenario "ひらがな（アイテム名）のフィールドが空の状態でアイテム更新を試みる" do
        expect do
          # アイテム名、ひらがな（アイテム名）のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "item_hiragana", with: ""
          click_button "更新"
        end.to_not change { Item.count }

        expect(page).to have_content "ひらがな（アイテム名）を入力してください。"
      end

      let(:over_length_hiragana) { "あ" * 21 }

      scenario "ひらがな（アイテム名）の文字数がオーバーしている状態でアイテム更新を試みる" do
        expect do
          # アイテム名、ひらがな（アイテム名）のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "item_hiragana", with: over_length_hiragana
          click_button "更新"
        end.to_not change { Item.count }

        expect(page).to have_content "ひらがな（アイテム名）は#{Item::MAX_LENGTH_HIRAGANA}文字以内で入力してください。"
      end

      let(:invalid_hiragana) { "テストアイテム壱" }

      scenario "ひらがな（アイテム名）を平仮名と半角数字以外で入力している状態でアイテム更新を試みる" do
        expect do
          # アイテム名、ひらがな（アイテム名）のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "item_hiragana", with: invalid_hiragana
          click_button "更新"
        end.to_not change { Item.count }

        expect(page).to have_content "ひらがな（アイテム名）の項目は平仮名・半角数字のみ使用してください。"
      end

      scenario "登録済みのアイテムと同じカテゴリー、アイテム名で更新を試みる" do
        expect do
          select exist_item.category.name, from: "item[category_id]"
          # アイテム名、ひらがな（アイテム名）のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "item_name", with: exist_item.name
          click_button "更新"
        end.to_not change { Item.count }

        expect(page).to have_content "アイテム名は同じカテゴリーの中で二つ以上登録できません。"
      end

      scenario "登録済みのアイテムと同じカテゴリー、ひらがな（アイテム名）で更新を試みる" do
        expect do
          select exist_item.category.name, from: "item[category_id]"
          # アイテム名、ひらがな（アイテム名）のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "item_hiragana", with: exist_item.hiragana
          click_button "更新"
        end.to_not change { Item.count }

        expect(page).to have_content "ひらがな（アイテム名）は同じカテゴリーの中で二つ以上登録できません。"
      end

      scenario "デフォルトアイテム（マスター管理ユーザーの登録アイテム）と同じカテゴリー、アイテム名で更新を試みる" do
        expect do
          select preset_item.category.name, from: "item[category_id]"
          # アイテム名、ひらがな（アイテム名）のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "item_name", with: preset_item.name
          click_button "更新"
        end.to_not change { Item.count }

        expect(page).to have_content "アイテム名が同じカテゴリーに存在するデフォルトアイテムと重複しています。"
      end

      scenario "デフォルトアイテム（マスター管理ユーザーの登録アイテム）と同じカテゴリー、ひらがな（アイテム名）で更新を試みる" do
        expect do
          select preset_item.category.name, from: "item[category_id]"
          # アイテム名、ひらがな（アイテム名）のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "item_hiragana", with: preset_item.hiragana
          click_button "更新"
        end.to_not change { Item.count }

        expect(page).to have_content "ひらがな（アイテム名）が同じカテゴリーに存在するデフォルトアイテムと重複しています。"
      end
    end
  end

  describe "アイテム削除のフロー" do
    let(:user) { create(:user, :admin) }
    # アイテムの登録時にマスター管理ユーザーが必要
    let!(:master_user) { create(:user, :master_admin) }
    let(:category) { create(:category) }
    let!(:delete_item) { create(:item, user: user, category: category) }

    before do
      sign_in_as(user)
      # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
      expect(page).to have_content "ログインしました。"
      visit management_items_path
    end

    scenario "アイテムを削除する", js: true do
      # アイテム一覧から削除対象のアイテム削除ボタンをクリック
      within("tr", text: delete_item.name) do
        find("i.delete-icon").click
      end

      # アイテム削除のconfirmモーダルを確認
      expect(page).to have_selector("#turbo-confirm-modal", visible: true)
      within "#turbo-confirm-modal" do
        expect(page).to have_selector("h1", visible: true, text: "アイテム（ID: #{delete_item.id}）の削除")
      end

      expect do
        within "#turbo-confirm-modal" do
          click_button "削除する"
        end

        expect(page).to have_content "アイテムの削除が完了しました。"
        expect(current_path).to eq management_items_path
      end.to change { Item.count }.by(-1)

      # 削除したアイテムがDBに存在しないことを確認
      expect(Item.where(id: delete_item.id)).to_not exist
    end
  end
end
