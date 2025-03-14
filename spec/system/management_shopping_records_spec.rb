require 'rails_helper'

RSpec.describe "ManagementShoppingRecords", type: :system do
  # Google Maps API のモックヘルパーメソッド
  def google_maps_mock_setup
    page.driver.browser.execute_cdp('Page.addScriptToEvaluateOnNewDocument', source: <<~JS)
      window.google = {
        maps: {
          importLibrary: async function (libraryName) {
            switch (libraryName) {
              case "maps":
                return {
                  Map: class MapMock {
                    constructor(element, options) {
                      this.center = options.center;
                      this.zoom = options.zoom;
                      this.element = element;
                    }
                    getCenter() {
                      return this.center;
                    }
                  }
                };
              case "marker":
                return {
                  Marker: class MarkerMock {
                    constructor({ position }) {
                      this.position = position;
                    }
                    getPosition() {
                      return this.position;
                    }
                  },
                  Animation: { DROP: "DROP" }
                };
              default:
                throw new Error(`Unknown library: ${libraryName}`);
            }
          }
        }
      };
    JS
  end

  shared_examples "サイドバーにあるリンクの背景色CSSのテスト" do
    it "表示中のページ（お買い物管理）のリンクに背景色のCSSが設定されていること" do
      within("ul.management-menu-list") do
        expect(page).to have_selector("li.bg-secondary-subtle", text: "お買い物管理")
      end
    end

    it "表示中のページ（お買い物管理）以外のリンクに背景色のCSSが設定されていないこと" do
      within("ul.management-menu-list") do
        # 通知ユーザー管理との部分一致を避けるため exact_text: true を使用する
        expect(page).to_not have_selector("li.bg-secondary-subtle", text: "ユーザー管理", exact_text: true)
        expect(page).to_not have_selector("li.bg-secondary-subtle", text: "通知ユーザー管理")
        expect(page).to_not have_selector("li.bg-secondary-subtle", text: "アイテム管理")
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
          visit management_shopping_records_path
        end

        include_examples "ユーザー情報の表示テスト"

        include_examples "管理ページのサイドバーメニューのテスト"

        it_behaves_like "サイドバーにあるリンクの背景色CSSのテスト"

        it "ページタイトルが表示されること" do
          within "div.management-main" do
            expect(page).to have_selector("h2", text: "お買い物管理")
          end
        end

        it "検索フォームが表示されること" do
          expect(page).to have_selector("form#shopping_record_search")
          expect(page).to have_field("q_user_id_eq", type: "search", placeholder: "User_ID")
          expect(page).to have_field("q_title_cont", type: "search", placeholder: "Title 部分一致")
          expect(page).to have_button "検索"
        end

        it "お買い物一覧テーブルの各見出しが表示されること" do
          within "thead" do
            expect(page).to have_selector("th", text: "ID")
            expect(page).to have_selector("th", text: "User_ID")
            expect(page).to have_selector("th", text: "Title")
            expect(page).to have_selector("th", text: "Closed")
            expect(page).to have_selector("th", text: "Map（child table present?）")
            expect(page).to have_selector("th", text: "Created_at")
            expect(page).to have_selector("th", text: "Updated_at")
            expect(page).to have_selector("th", text: "詳細")
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
          expect { visit management_shopping_records_path }.to raise_error(ActionController::RoutingError)
        end
      end

      context "サインインしていない場合" do
        it "404エラーになること" do
          expect { visit management_shopping_records_path }.to raise_error(ActionController::RoutingError)
        end
      end

      describe "お買い物の情報表示・ボタンのテスト" do
        let(:user) { create(:user, :admin) }
        # アイテムのcreate時にマスター管理ユーザーが必要
        let!(:master_user) { create(:user, :master_admin) }

        describe "お買い物の状態で共通のテスト" do
          let(:other_user) { create(:user) }
          let!(:user_shopping_record) { create(:shopping_record, user: user, title: "テストお買い物1") }
          let!(:other_user_shopping_record) { create(:shopping_record, user: other_user, title: "テストお買い物2") }

          before do
            sign_in_as(user)
            # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
            expect(page).to have_content "ログインしました。"
            visit management_shopping_records_path
          end

          it "お買い物毎にID、親ユーザーID、タイトル、作成・更新日時が表示されること" do
            within("tr", text: user_shopping_record.title) do
              expect(page).to have_selector("td", text: user_shopping_record.id)
              expect(page).to have_selector("td", text: user_shopping_record.user_id)
              expect(page).to have_selector("td", text: user_shopping_record.title)
              expect(page).to have_selector("td", text: user_shopping_record.created_at.to_fs(:date_time))
              expect(page).to have_selector("td", text: user_shopping_record.updated_at.to_fs(:date_time))
            end

            within("tr", text: other_user_shopping_record.title) do
              expect(page).to have_selector("td", text: other_user_shopping_record.id)
              expect(page).to have_selector("td", text: other_user_shopping_record.user_id)
              expect(page).to have_selector("td", text: other_user_shopping_record.title)
              expect(page).to have_selector("td", text: other_user_shopping_record.created_at.to_fs(:date_time))
              expect(page).to have_selector("td", text: other_user_shopping_record.updated_at.to_fs(:date_time))
            end
          end

          it "お買い物毎に詳細画面へのリンクが存在すること" do
            within("tr", text: user_shopping_record.title) do
              expect(page).to have_selector("i.show-icon")
              expect(page).to have_link(href: management_shopping_record_path(user_shopping_record.id))
            end

            within("tr", text: other_user_shopping_record.title) do
              expect(page).to have_selector("i.show-icon")
              expect(page).to have_link(href: management_shopping_record_path(other_user_shopping_record.id))
            end
          end

          it "お買い物の詳細画面へのリンクをクリックして該当のお買い物詳細画面へ遷移すること" do
            within("tr", text: user_shopping_record.title) do
              click_link(href: management_shopping_record_path(user_shopping_record.id))
            end

            expect(page).to have_http_status(:success)
            expect(current_path).to eq management_shopping_record_path(user_shopping_record.id)
          end

          it "お買い物毎の行に削除ボタンが存在すること" do
            within("tr", text: user_shopping_record.title) do
              expect(page).to have_selector("i.delete-icon")
            end

            within("tr", text: other_user_shopping_record.title) do
              expect(page).to have_selector("i.delete-icon")
            end
          end

          it "お買い物削除ボタンをクリックするとモーダルが表示されること", js: true do
            expect(page).to have_selector("#turbo-confirm-modal", visible: false)

            within("tr", text: user_shopping_record.title) do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)
          end

          it "お買い物削除モーダルにタイトルが表示されること", js: true do
            within("tr", text: user_shopping_record.title) do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            within "#turbo-confirm-modal" do
              expect(page).to have_selector("h1", visible: true, text: "お買い物（ID: #{user_shopping_record.id}）の削除")
            end
          end

          it "お買い物削除モーダルのヘッダーにモーダルを閉じるボタンがあること", js: true do
            within("tr", text: user_shopping_record.title) do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            within "#turbo-confirm-modal" do
              within ".modal-header" do
                expect(page).to have_selector("button.btn-close", visible: true)
              end
            end
          end

          it "お買い物削除モーダルに削除ボタン・キャンセルボタンが表示されること", js: true do
            within("tr", text: user_shopping_record.title) do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            within "#turbo-confirm-modal" do
              expect(page).to have_selector("button", visible: true, text: "削除する")
              expect(page).to have_selector("button", visible: true, text: "キャンセル")
            end
          end

          it "お買い物削除モーダルのキャンセルボタンでお買い物削除を中止できること", js: true do
            within("tr", text: user_shopping_record.title) do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            within "#turbo-confirm-modal" do
              click_button "キャンセル"
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: false)
          end

          it "お買い物削除モーダルの外をクリックするとモーダルが閉じること", js: true do
            within("tr", text: user_shopping_record.title) do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            # モーダルの外をクリック
            page.execute_script("document.querySelector('body').click();")

            expect(page).to have_selector("#turbo-confirm-modal", visible: false)
          end
        end

        describe "一覧に表示されるお買い物の状態で異なる箇所のテスト" do
          context "未完了のお買い物の場合" do
            let!(:unclosed_shopping_record) { create(:shopping_record, user: user, closed: false) }

            before do
              sign_in_as(user)
              visit management_shopping_records_path
            end

            it "'未完了'の表示が存在すること" do
              within("tr", text: unclosed_shopping_record.title) do
                expect(page).to have_selector("td", text: "未完了")
              end
            end

            it "'完了'の表示が存在しないこと" do
              within("tr", text: unclosed_shopping_record.title) do
                expect(page).to_not have_selector("td", text: "完了", exact_text: true)
              end
            end
          end

          context "完了済みのお買い物の場合" do
            let!(:closed_shopping_record) { create(:shopping_record, user: user, closed: true) }

            before do
              sign_in_as(user)
              visit management_shopping_records_path
            end

            it "'完了'の表示が存在すること" do
              within("tr", text: closed_shopping_record.title) do
                expect(page).to have_selector("td", text: "完了")
              end
            end

            it "'未完了'の表示が存在しないこと" do
              within("tr", text: closed_shopping_record.title) do
                expect(page).to_not have_selector("td", text: "未完了")
              end
            end
          end

          context "お買い物場所（shopping_location）が未登録の場合" do
            let!(:shopping_record) { create(:shopping_record, :closed, user: user) }

            before do
              sign_in_as(user)
              visit management_shopping_records_path
            end

            it "'未登録'の表示が存在すること" do
              # 対象のお買い物にお買い物場所が存在しないことを確認
              expect(shopping_record.shopping_location.present?).to be_falsey

              within("tr", text: shopping_record.title) do
                expect(page).to have_selector("td", text: "未登録")
              end
            end

            it "'登録済み'の表示が存在しないこと" do
              # 対象のお買い物にお買い物場所が存在しないことを確認
              expect(shopping_record.shopping_location.present?).to be_falsey

              within("tr", text: shopping_record.title) do
                expect(page).to_not have_selector("td", text: "登録済み")
              end
            end
          end

          context "お買い物場所（shopping_location）が登録されている場合" do
            let(:shopping_record) { create(:shopping_record, :closed, user: user) }
            let!(:shopping_location) { create(:shopping_location, shopping_record: shopping_record) }

            before do
              sign_in_as(user)
              visit management_shopping_records_path
            end

            it "'登録済み'の表示が存在すること" do
              # 対象のお買い物にお買い物場所が存在することを確認
              expect(shopping_record.shopping_location.present?).to be_truthy

              within("tr", text: shopping_record.title) do
                expect(page).to have_selector("td", text: "登録済み")
              end
            end

            it "'未登録'の表示が存在しないこと" do
              # 対象のお買い物にお買い物場所が存在することを確認
              expect(shopping_record.shopping_location.present?).to be_truthy

              within("tr", text: shopping_record.title) do
                expect(page).to_not have_selector("td", text: "未登録")
              end
            end
          end
        end
      end

      describe "ページネーションのテスト" do
        let(:user) { create(:user, :admin) }
        # 登録制限のない「完了状態のお買い物」を使用する
        let!(:shopping_records) { create_list(:shopping_record, 50, :closed, user: user) }
        let(:one_pagenation_max_size) { 50 }

        context "表示対象のお買い物件数が50件以下の場合" do
          before do
            # お買い物の件数が50件であることを確認
            expect(ShoppingRecord.count).to eq(one_pagenation_max_size)

            sign_in_as(user)
            visit management_shopping_records_path
          end

          it "ページネーションのナビゲーションが存在しないこと" do
            expect(page).to_not have_selector("nav.pagy-nav")
          end
        end

        context "表示対象のお買い物件数が50件を超える場合" do
          let!(:shopping_record_51st) { create(:shopping_record, user: user) } # お買い物を51件にする
          let(:one_pagenation_over_size) { 51 }

          before do
            # お買い物の件数が51件であることを確認
            expect(ShoppingRecord.count).to eq(one_pagenation_over_size)

            sign_in_as(user)
            visit management_shopping_records_path
          end

          it "最初のページに50件のお買い物が表示されること" do
            shopping_records.each do |shopping_record|
              expect(page).to have_selector("tr", text: shopping_record.title)
            end
          end

          it "最初のページに51件目のお買い物が表示されないこと" do
            expect(page).to_not have_selector("tr", text: shopping_record_51st.title)
          end

          it "ページネーションのナビゲーションが存在すること" do
            expect(page).to have_selector("nav.pagy-nav")
          end

          it "ページネーションの別のページへのリンクが存在すること" do
            within "nav.pagy-nav" do
              expect(page).to have_link("2", href: management_shopping_records_path(page: 2))
              expect(page).to have_link("次", href: management_shopping_records_path(page: 2))
            end
          end

          it "1ページ目（現在のページ）のリンクが存在しないこと" do
            within "nav.pagy-nav" do
              expect(page).to_not have_link("1", href: management_shopping_records_path(page: 1))
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
              expect(URI.parse(current_url).request_uri).to eq management_shopping_records_path(page: 2)
            end

            it "51件目のお買い物が表示されること" do
              expect(page).to have_selector("tr", text: shopping_record_51st.title)
            end

            it "最初のページの50件のお買い物が表示されないこと" do
              shopping_records.each do |shopping_record|
                expect(page).to_not have_selector("tr", text: shopping_record.title)
              end
            end

            it "ページネーションの別のページへのリンクが存在すること" do
              within "nav.pagy-nav" do
                expect(page).to have_link("前", href: management_shopping_records_path(page: 1))
                expect(page).to have_link("1", href: management_shopping_records_path(page: 1))
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
                expect(page).to_not have_link("2", href: management_shopping_records_path(page: 2))
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
          # お買い物を100件にする（表示件数がページネーションに関係しないことを確認するため50件以上に設定する）
          # 登録制限のない「完了状態のお買い物」を使用する
          let!(:shopping_records) { create_list(:shopping_record, 100, :closed, user: user) }
          let(:shopping_record_count) { 100 }

          before do
            sign_in_as(user)
            visit management_shopping_records_path
          end

          it "初期状態では登録済みお買い物の件数が表示されること" do
            expect(ShoppingRecord.count).to eq shopping_record_count
            expect(page).to have_selector("h5", text: "件数： #{shopping_record_count} 件")
          end
        end

        context "検索機能で絞り込む場合" do
          let(:other_user) { create(:user) }
          # 2ユーザーそれぞれで未完了のお買い物を5件ずつ計10件のお買い物を作成する
          let!(:user_shopping_records) { create_list(:shopping_record, 5, user: user) }
          let!(:other_user_shopping_records) { create_list(:shopping_record, 5, user: other_user) }
          let(:all_shopping_record_count) { 10 }
          let(:user_shopping_record_count) { 5 }

          before do
            sign_in_as(user)
            visit management_shopping_records_path
          end

          it "検索による絞り込み後の通知ユーザー件数が表示されること" do
            # 初期状態のお買い物件数表示を確認
            expect(ShoppingRecord.count).to eq all_shopping_record_count
            expect(page).to have_selector("h5", text: "件数： #{all_shopping_record_count} 件")

            # 親ユーザーIDによる検索
            fill_in "q_user_id_eq", with: user.id
            click_button "検索"

            # 絞り込み後のお買い物件数表示を確認
            expect(page).to have_selector("h5", text: "件数： #{user_shopping_record_count} 件")
          end
        end
      end
    end

    describe "show" do
      context "管理ユーザーの場合" do
        let(:user) { create(:user, :admin) }

        context "お買い物の状態で共通のテスト" do
          # ユーザー管理ページにアクセスするときにマスター管理ユーザーが必要
          let!(:master_user) { create(:user, :master_admin) }
          # 購入実績のある購入記録を使用するため実際の運用と合わせ完了済みのお買い物を想定してデータを作成
          let(:shopping_record) { create(:shopping_record, user: user, title: "テストお買い物", closed: true) }
          let!(:purchased_buy) do
            create(:buy, user: user, shopping_record: shopping_record, item_name: "肉", item_hiragana: "にく", purchased: true)
          end
          let!(:unpurchased_buy) do
            create(:buy, user: user, shopping_record: shopping_record, item_name: "野菜", item_hiragana: "やさい", purchased: false)
          end

          before do
            sign_in_as(user)
            visit management_shopping_record_path(shopping_record.id)
          end

          include_examples "ユーザー情報の表示テスト"

          include_examples "管理ページのサイドバーメニューのテスト"

          it_behaves_like "サイドバーにあるリンクの背景色CSSのテスト"

          it "ページタイトルが表示されること" do
            within "div.management-main" do
              expect(page).to have_selector("h2", text: "お買い物詳細")
            end
          end

          it "戻るリンクが表示されること" do
            expect(page).to have_link "戻る"
          end

          it "お買い物のID情報が表示されること" do
            within("div.confirm-window", text: "お買い物ID（ID）") do
              expect(page).to have_content shopping_record.id
            end
          end

          it "お買い物を登録した親ユーザーのID情報が表示されること" do
            within("div.confirm-window", text: "登録ユーザーID（User_id）") do
              expect(page).to have_content shopping_record.user.id
            end
          end

          it "お買い物のタイトル情報が表示されること" do
            within("div.confirm-window", text: "お買い物タイトル（Title）") do
              expect(page).to have_content shopping_record.title
            end
          end

          it "お買い物の登録日時（created_at）情報が表示されること" do
            within("div.confirm-window", text: "登録日時（Created_at）") do
              expect(page).to have_content shopping_record.created_at.to_fs(:date_time)
            end
          end

          it "お買い物の完了日時（updated_at）情報が表示されること" do
            within("div.confirm-window", text: "完了日時（Updated_at）") do
              expect(page).to have_content shopping_record.updated_at.to_fs(:date_time)
            end
          end

          it "お買い物に紐づく購入記録（アイテム名（アイテムひらがな名）〈購入有無〉）の情報が表示されること" do
            within("div.confirm-window", text: "アイテム") do
              within("li", text: purchased_buy.item_name) do
                expect(page).to have_content "肉"
                expect(page).to have_content "（にく）"
                expect(page).to have_content "〈購入〉"
                expect(page).to_not have_content "〈未購入〉"
              end

              within("li", text: unpurchased_buy.item_name) do
                expect(page).to have_content "野菜"
                expect(page).to have_content "（やさい）"
                expect(page).to have_content "〈未購入〉"
                expect(page).to_not have_content "〈購入〉"
              end
            end
          end
        end

        context "お買い物が未完了の場合" do
          let(:shopping_record) { create(:shopping_record, user: user, closed: false) }

          before do
            sign_in_as(user)
            visit management_shopping_record_path(shopping_record.id)
          end

          it "お買い物状態（Closed）情報に'未完了'が表示されること" do
            within("div.confirm-window", text: "お買い物状態（Closed）") do
              expect(page).to have_content "未完了"
            end
          end

          it "お買い物状態（Closed）情報に'完了'が表示されないこと" do
            within("div.confirm-window", text: "お買い物状態（Closed）") do
              expect(page).to_not have_content("完了", exact: true)
            end
          end
        end

        context "お買い物が完了済みの場合" do
          let(:shopping_record) { create(:shopping_record, user: user, closed: true) }

          before do
            sign_in_as(user)
            visit management_shopping_record_path(shopping_record.id)
          end

          it "お買い物状態（Closed）情報に'完了'が表示されること" do
            within("div.confirm-window", text: "お買い物状態（Closed）") do
              expect(page).to have_content "完了"
            end
          end

          it "お買い物状態（Closed）情報に'未完了'が表示されないこと" do
            within("div.confirm-window", text: "お買い物状態（Closed）") do
              expect(page).to_not have_content "未完了"
            end
          end
        end

        context "お買い物に紐づくお買い物場所が存在しない場合" do
          let(:shopping_record) { create(:shopping_record, user: user) }

          before do
            sign_in_as(user)
            visit management_shopping_record_path(shopping_record.id)
          end

          it "お買い物した場所の情報に'登録なし'が表示されること" do
            within("div.confirm-window", text: "お買い物した場所") do
              expect(page).to have_content "登録なし"
            end
          end

          it "Googleマップが表示される領域が存在しないこと" do
            within("div.confirm-window", text: "お買い物した場所") do
              expect(page).to_not have_selector("div#map")
            end
          end
        end

        context "お買い物に紐づくお買い物場所が存在する場合" do
          # お買い物場所の登録はお買い物完了後のため実際の運用に合わせて完了状態のお買い物を作成
          let(:shopping_record) { create(:shopping_record, user: user, closed: true) }
          let!(:shopping_location) { create(:shopping_location, shopping_record: shopping_record) }

          before do
            sign_in_as(user)
            visit management_shopping_record_path(shopping_record.id)
          end

          it "Googleマップが表示される領域が存在すること" do
            within("div.confirm-window", text: "お買い物した場所") do
              expect(page).to have_selector("div#map")
            end
          end

          it "お買い物した場所の情報に'登録なし'が表示されないこと" do
            within("div.confirm-window", text: "お買い物した場所") do
              expect(page).to_not have_content "登録なし"
            end
          end
        end
      end

      context "管理ユーザー以外の場合" do
        let(:user) { create(:user) }
        let!(:shopping_record) { create(:shopping_record, user: user) }

        before do
          sign_in_as(user)
        end

        it "404エラーになること" do
          expect { visit management_shopping_record_path(shopping_record.id) }.to raise_error(ActionController::RoutingError)
        end
      end

      context "サインインしていない場合" do
        let(:user) { create(:user) }
        let!(:shopping_record) { create(:shopping_record, user: user) }

        it "404エラーになること" do
          expect { visit management_shopping_record_path(shopping_record.id) }.to raise_error(ActionController::RoutingError)
        end
      end

      describe "戻るリンクのテスト" do
        let(:user) { create(:user, :admin) }
        # 登録制限のない「完了状態のお買い物」を作成しお買い物を50件にする
        let!(:shopping_records) { create_list(:shopping_record, 50, :closed, user: user) }
        # お買い物を51件にする
        let!(:shopping_record_51st) { create(:shopping_record, user: user) }
        # 戻るリンクのテストに必要な変数を定義
        let(:test_index_page_path) { management_shopping_records_path }
        let(:test_index_page2_path) { management_shopping_records_path(page: 2) }
        let(:test_page_path) { management_shopping_record_path(shopping_record_51st.id) }
        let(:td_text) { shopping_record_51st.title }

        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
        end

        include_examples "back_linkによる戻るリンクのテスト"
      end

      describe "Google Mapsに関連する箇所のテスト", js: true do
        let(:user) { create(:user, :admin) }
        let!(:shopping_record) { create(:shopping_record, user: user) }
        let!(:shopping_location) do
          create(:shopping_location, shopping_record: shopping_record, latitude: 35.68956, longitude: 139.69167)
        end

        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"

          @google_maps_script_id = google_maps_mock_setup
          visit management_shopping_record_path(shopping_record.id)
        end

        after do
          # テスト終了時にモックスクリプトを削除
          remove_script(@google_maps_script_id)
        end

        it "JavaScript(gon)で設定されたGoogleマップの緯度(lat)・経度(lng)が正しいこと" do
          lat = page.evaluate_script("gon.lat")
          lng = page.evaluate_script("gon.lng")
          expect(lat).to eq shopping_location.latitude
          expect(lng).to eq shopping_location.longitude
        end

        it "登録済みのお買い物の緯度・経度でマップが初期化されること" do
          # Map モックの初期化確認
          expect(page.evaluate_script("window.test.gMap")).not_to be_nil

          # 初期化時の中心座標が正しいか確認（DB上のshopping_locationの緯度・経度を想定）
          center = page.evaluate_script("window.test.gMap.getCenter()")
          expect(center).to eq({ "lat" => shopping_location.latitude, "lng" => shopping_location.longitude })
        end

        it "マーカーが正しい位置に設定されること" do
          # Marker モックの初期化確認
          expect(page.evaluate_script("window.test.marker")).not_to be_nil

          # MerkerのpositionにはDB上のshopping_locationの緯度・経度の値を使用する
          marker_position = page.evaluate_script("window.test.marker.getPosition()")
          expect(marker_position).to eq({ "lat" => shopping_location.latitude, "lng" => shopping_location.longitude })
        end
      end
    end
  end

  describe "お買い物一覧のソート・検索機能のテスト" do
    describe "ソート機能" do
      context "共通項目のテスト" do
        let(:user) { create(:user, :admin) }
        let!(:shopping_record1) { create(:shopping_record, id: 1, user: user, title: "テストお買い物1") }
        let!(:shopping_record2) { create(:shopping_record, id: 2, user: user, title: "テストお買い物2") }
        let!(:shopping_record3) { create(:shopping_record, id: 3, user: user, title: "テストお買い物3") }

        before do
          sign_in_as(user)
          visit management_shopping_records_path
        end

        it "デフォルトではIDの昇順になっていること" do
          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "テストお買い物1")
            expect(rows[1]).to have_selector("td", text: "テストお買い物2")
            expect(rows[2]).to have_selector("td", text: "テストお買い物3")
          end
        end

        include_examples "ソート順による見出しのCSSのテスト"
      end

      context "IDでソートする場合" do
        let(:user) { create(:user, :admin) }
        let!(:shopping_record1) { create(:shopping_record, id: 1, user: user, title: "テストお買い物1") }
        let!(:shopping_record2) { create(:shopping_record, id: 2, user: user, title: "テストお買い物2") }
        let!(:shopping_record3) { create(:shopping_record, id: 3, user: user, title: "テストお買い物3") }

        before do
          sign_in_as(user)
          visit management_shopping_records_path
        end

        it "IDの昇順でソートされること" do
          # IDの見出しでテスト（User_IDの見出しと重複しないようにwithinとfindで指定）
          within find("th", text: "ID", match: :first) do
            click_link "ID"
          end

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "テストお買い物1")
            expect(rows[1]).to have_selector("td", text: "テストお買い物2")
            expect(rows[2]).to have_selector("td", text: "テストお買い物3")
          end
        end

        it "IDの降順でソートされること" do
          within find("th", text: "ID", match: :first) do
            click_link "ID" # 1回目のクリックで昇順
            click_link "ID" # 2回目のクリックで降順
          end

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "テストお買い物3")
            expect(rows[1]).to have_selector("td", text: "テストお買い物2")
            expect(rows[2]).to have_selector("td", text: "テストお買い物1")
          end
        end
      end

      context "親ユーザーID（User_ID）でソートする場合" do
        let(:user1) { create(:user, :admin) }
        let(:user2) { create(:user) }
        let(:user3) { create(:user) }
        let!(:shopping_record1) { create(:shopping_record, user: user1, title: "テストお買い物1") }
        let!(:shopping_record2) { create(:shopping_record, user: user2, title: "テストお買い物2") }
        let!(:shopping_record3) { create(:shopping_record, user: user3, title: "テストお買い物3") }

        before do
          sign_in_as(user1)
          visit management_shopping_records_path
        end

        it "親ユーザーID（User_ID）の昇順でソートされること" do
          click_link "User_ID"

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "テストお買い物1")
            expect(rows[1]).to have_selector("td", text: "テストお買い物2")
            expect(rows[2]).to have_selector("td", text: "テストお買い物3")
          end
        end

        it "親ユーザーID（User_ID）の降順でソートされること" do
          click_link "User_ID" # 1回目のクリックで昇順
          click_link "User_ID" # 2回目のクリックで降順

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "テストお買い物3")
            expect(rows[1]).to have_selector("td", text: "テストお買い物2")
            expect(rows[2]).to have_selector("td", text: "テストお買い物1")
          end
        end
      end

      context "タイトルでソートする場合" do
        let(:user) { create(:user, :admin) }
        let!(:shopping_record1) { create(:shopping_record, user: user, title: "テストお買い物1") }
        let!(:shopping_record2) { create(:shopping_record, user: user, title: "テストお買い物2") }
        let!(:shopping_record3) { create(:shopping_record, user: user, title: "テストお買い物3") }

        before do
          sign_in_as(user)
          visit management_shopping_records_path
        end

        it "タイトルの昇順でソートされること" do
          click_link "Title"

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "テストお買い物1")
            expect(rows[1]).to have_selector("td", text: "テストお買い物2")
            expect(rows[2]).to have_selector("td", text: "テストお買い物3")
          end
        end

        it "タイトルの降順でソートされること" do
          click_link "Title" # 1回目のクリックで昇順
          click_link "Title" # 2回目のクリックで降順

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "テストお買い物3")
            expect(rows[1]).to have_selector("td", text: "テストお買い物2")
            expect(rows[2]).to have_selector("td", text: "テストお買い物1")
          end
        end
      end

      context "完了状態（Closed）でソートする場合" do
        let(:user) { create(:user, :admin) }
        let!(:shopping_record1) { create(:shopping_record, user: user, closed: true, title: "テストお買い物1") }
        let!(:shopping_record2) { create(:shopping_record, user: user, closed: false, title: "テストお買い物2") }
        let!(:shopping_record3) { create(:shopping_record, user: user, closed: false, title: "テストお買い物3") }

        before do
          sign_in_as(user)
          visit management_shopping_records_path
        end

        it "未完了、完了の順でソートされること" do
          click_link "Closed"

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "テストお買い物2")
            expect(rows[1]).to have_selector("td", text: "テストお買い物3")
            expect(rows[2]).to have_selector("td", text: "テストお買い物1")
          end
        end

        it "完了、未完了の順でソートされること" do
          click_link "Closed" # 1回目のクリックで昇順
          click_link "Closed" # 2回目のクリックで降順

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "テストお買い物1")
            expect(rows[1]).to have_selector("td", text: "テストお買い物2")
            expect(rows[2]).to have_selector("td", text: "テストお買い物3")
          end
        end
      end

      context "お買い物場所の有無（Map（child table present?））でソートする場合" do
        let(:user) { create(:user, :admin) }
        let(:shopping_record1) { create(:shopping_record, user: user, closed: true, title: "テストお買い物1") }
        let!(:shopping_record2) { create(:shopping_record, user: user, closed: true, title: "テストお買い物2") }
        let!(:shopping_record3) { create(:shopping_record, user: user, closed: true, title: "テストお買い物3") }
        let!(:shopping_location) { create(:shopping_location, shopping_record: shopping_record1) }

        before do
          sign_in_as(user)
          visit management_shopping_records_path
        end

        it "未登録、登録済みの順でソートされること" do
          click_link "Map（child table present?）"

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "テストお買い物2")
            expect(rows[1]).to have_selector("td", text: "テストお買い物3")
            expect(rows[2]).to have_selector("td", text: "テストお買い物1")
          end
        end

        it "登録済み、未登録の順でソートされること" do
          click_link "Map（child table present?）" # 1回目のクリックで昇順
          click_link "Map（child table present?）" # 2回目のクリックで降順

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "テストお買い物1")
            expect(rows[1]).to have_selector("td", text: "テストお買い物2")
            expect(rows[2]).to have_selector("td", text: "テストお買い物3")
          end
        end
      end

      context "作成日時(Created_at)でソートする場合" do
        let(:user) { create(:user, :admin) }
        let!(:shopping_record1) { create(:shopping_record, user: user, title: "テストお買い物1", created_at: 1.day.ago) }
        let!(:shopping_record2) { create(:shopping_record, user: user, title: "テストお買い物2", created_at: 2.day.ago) }
        let!(:shopping_record3) { create(:shopping_record, user: user, title: "テストお買い物3", created_at: 3.day.ago) }

        before do
          sign_in_as(user)
          visit management_shopping_records_path
        end

        it "作成日時の昇順でソートされること" do
          within find("th", text: "Created_at") do
            click_link "Created_at"
          end

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "テストお買い物3")
            expect(rows[1]).to have_selector("td", text: "テストお買い物2")
            expect(rows[2]).to have_selector("td", text: "テストお買い物1")
          end
        end

        it "作成日時の降順でソートされること" do
          within find("th", text: "Created_at") do
            click_link "Created_at" # 1回目のクリックで昇順
            click_link "Created_at" # 2回目のクリックで降順
          end

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "テストお買い物1")
            expect(rows[1]).to have_selector("td", text: "テストお買い物2")
            expect(rows[2]).to have_selector("td", text: "テストお買い物3")
          end
        end
      end

      context "更新日時(Updated_at)でソートする場合" do
        let(:user) { create(:user, :admin) }
        let!(:shopping_record1) { create(:shopping_record, user: user, title: "テストお買い物1", updated_at: 1.day.ago) }
        let!(:shopping_record2) { create(:shopping_record, user: user, title: "テストお買い物2", updated_at: 2.day.ago) }
        let!(:shopping_record3) { create(:shopping_record, user: user, title: "テストお買い物3", updated_at: 3.day.ago) }

        before do
          sign_in_as(user)
          visit management_shopping_records_path
        end

        it "更新日時の昇順でソートされること" do
          within find("th", text: "Updated_at") do
            click_link "Updated_at"
          end

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "テストお買い物3")
            expect(rows[1]).to have_selector("td", text: "テストお買い物2")
            expect(rows[2]).to have_selector("td", text: "テストお買い物1")
          end
        end

        it "更新日時の降順でソートされること" do
          within find("th", text: "Updated_at") do
            click_link "Updated_at" # 1回目のクリックで昇順
            click_link "Updated_at" # 2回目のクリックで降順
          end

          within "tbody" do
            rows = all("tr")
            expect(rows[0]).to have_selector("td", text: "テストお買い物1")
            expect(rows[1]).to have_selector("td", text: "テストお買い物2")
            expect(rows[2]).to have_selector("td", text: "テストお買い物3")
          end
        end
      end
    end

    describe "検索機能" do
      let(:user1) { create(:user, :admin, id: 1) }
      let(:user2) { create(:user, id: 2) }
      let!(:shopping_record1) { create(:shopping_record, user: user1, title: "テストショッピング1") }
      let!(:shopping_record2) { create(:shopping_record, user: user2, title: "テストショッピング2") }
      let!(:shopping_record3) { create(:shopping_record, user: user2, title: "テストお買い物") }

      before do
        sign_in_as(user1)
        visit management_shopping_records_path
      end

      it "親ユーザーIDでお買い物の絞り込みができること" do
        fill_in "q_user_id_eq", with: "2"
        click_button "検索"

        within "tbody" do
          expect(page).to_not have_selector("td", text: "テストショッピング1")
          expect(page).to have_selector("td", text: "テストショッピング2")
          expect(page).to have_selector("td", text: "テストお買い物")
        end
      end

      it "タイトルでお買い物の絞り込みができること" do
        fill_in "q_title_cont", with: "ショッピング"
        click_button "検索"

        within "tbody" do
          expect(page).to have_selector("td", text: "テストショッピング1")
          expect(page).to have_selector("td", text: "テストショッピング2")
          expect(page).to_not have_selector("td", text: "テストお買い物")
        end
      end
    end

    describe "ソート・検索機能の組み合わせ" do
      let(:user1) { create(:user, :admin, id: 1) }
      let(:user2) { create(:user, id: 2) }
      let!(:shopping_record1) { create(:shopping_record, user: user1, title: "テストショッピング1") }
      let!(:shopping_record2) { create(:shopping_record, user: user1, title: "テストショッピング2") }
      let!(:shopping_record3) { create(:shopping_record, user: user2, title: "テストショッピング3") }

      before do
        sign_in_as(user1)
        visit management_shopping_records_path
      end

      it "お買い物を検索で絞り込んだあとにソートできること" do
        fill_in "q_user_id_eq", with: "1"
        click_button "検索"

        within "tbody" do
          rows = all("tr")
          expect(rows[0]).to have_selector("td", text: "テストショッピング1")
          expect(rows[1]).to have_selector("td", text: "テストショッピング2")
          expect(page).to_not have_selector("td", text: "テストショッピング3")
        end

        # タイトルの昇順でソート
        click_link "Title"
        within "tbody" do
          rows = all("tr")
          expect(rows[0]).to have_selector("td", text: "テストショッピング1")
          expect(rows[1]).to have_selector("td", text: "テストショッピング2")
          expect(page).to_not have_selector("td", text: "テストショッピング3")
        end

        # タイトルの降順でソート
        click_link "Title"
        within "tbody" do
          rows = all("tr")
          expect(rows[0]).to have_selector("td", text: "テストショッピング2")
          expect(rows[1]).to have_selector("td", text: "テストショッピング1")
          expect(page).to_not have_selector("td", text: "テストショッピング3")
        end
      end
    end
  end

  describe "お買い物削除のフロー" do
    let(:user) { create(:user, :admin) }
    let!(:delete_shopping_record) { create(:shopping_record, user: user) }

    before do
      sign_in_as(user)
      # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
      expect(page).to have_content "ログインしました。"
      visit management_shopping_records_path
    end

    scenario "お買い物を削除する", js: true do
      # アイテム一覧から削除対象のアイテム削除ボタンをクリック
      within("tr", text: delete_shopping_record.title) do
        find("i.delete-icon").click
      end

      # アイテム削除のconfirmモーダルを確認
      expect(page).to have_selector("#turbo-confirm-modal", visible: true)
      within "#turbo-confirm-modal" do
        expect(page).to have_selector("h1", visible: true, text: "お買い物（ID: #{delete_shopping_record.id}）の削除")
      end

      expect do
        within "#turbo-confirm-modal" do
          click_button "削除する"
        end

        expect(page).to have_content "お買い物の削除が完了しました。"
        expect(current_path).to eq management_shopping_records_path
      end.to change { ShoppingRecord.count }.by(-1)

      # 削除したアイテムがDBに存在しないことを確認
      expect(ShoppingRecord.where(id: delete_shopping_record.id)).to_not exist
    end
  end
end
