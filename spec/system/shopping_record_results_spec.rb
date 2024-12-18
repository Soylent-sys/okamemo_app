require 'rails_helper'

# お買い物履歴機能関連のテスト
RSpec.describe "ShoppingRecordResults", type: :system do
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

  describe "ビューの要素" do
    describe "result_group" do
      let(:user) { create(:user) }
      let!(:master_user) { create(:user, :master_admin) }
      let(:category) { create(:category) }
      let!(:preset_item) { create(:item, user: master_user, category: category) }

      context "サインインしている場合" do
        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
          visit shopping_result_group_path
        end

        include_examples "ユーザー情報の表示テスト"

        # ナビゲーションのテスト用変数
        let(:navigation_content) { "お買い物履歴を見たい年月を選んでね。" }

        include_examples "ナビゲーションのテスト"

        it "ページタイトルが表示されること" do
          expect(page).to have_selector("h1", text: "お買い物履歴")
        end

        it "メインメニューに戻るリンクが存在すること" do
          expect(page).to have_link("メインメニュー にもどる", href: root_path)
        end

        it "メインメニューに戻るリンクをクリックしてrootページに遷移すること" do
          click_link "メインメニュー にもどる"

          expect(page).to have_http_status(:success)
          expect(current_path).to eq root_path
        end
      end

      context "サインインしていない場合" do
        before do
          visit shopping_result_group_path
        end

        include_examples "非ログイン状態で認可が必要なページにアクセスした時のリダイレクトテスト"
      end

      describe "お買い物履歴の有無で異なる箇所のテスト" do
        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
        end

        context "完了状態のお買い物が存在する場合" do
          let(:time_current) { Time.current }
          let(:one_month_ago) { time_current - 1.month }
          let(:closed_user_shopping_records) { create_list(:shopping_record, 2, :closed, user: user, updated_at: time_current) }
          let(:unclosed_other_month_user_shopping_record) { create(:shopping_record, user: user, updated_at: one_month_ago) }
          let!(:closed_user_shopping_buys) do
            closed_user_shopping_records.each do |record|
              create(
                :buy, :purchased,
                user: user, shopping_record: record,
                item_name: preset_item.name, item_hiragana: preset_item.hiragana
              )
            end
          end
          let!(:unclosed_other_month_user_shopping_buy) do
            create(:buy, user: user, shopping_record: unclosed_other_month_user_shopping_record,
                         item_name: preset_item.name, item_hiragana: preset_item.hiragana)
          end
          let(:other_user) { create(:user) }
          let(:closed_other_user_other_month_shopping_record) do
            create(:shopping_record, :closed, user: other_user, updated_at: one_month_ago)
          end
          let(:unclosed_other_user_other_month_shopping_record) do
            create(:shopping_record, user: other_user, updated_at: one_month_ago)
          end
          let!(:closed_other_user_other_month_shopping_buy) do
            create(
              :buy, :purchased,
              user: other_user, shopping_record: closed_other_user_other_month_shopping_record,
              item_name: preset_item.name, item_hiragana: preset_item.hiragana
            )
          end
          let!(:unclosed_other_user_other_month_shopping_buy) do
            create(:buy, user: other_user, shopping_record: unclosed_other_user_other_month_shopping_record,
                         item_name: preset_item.name, item_hiragana: preset_item.hiragana)
          end

          before do
            visit shopping_result_group_path
          end

          it "閲覧する年月を選択 の項目が表示されること" do
            expect(page).to have_selector("h2", text: "閲覧する年月を選択")
          end

          it "完了状態のお買い物の完了年月が表記されたお買い物履歴の月別の一覧画面へのリンクが存在すること" do
            shopping_closed_time = closed_user_shopping_records[0].updated_at
            link_text = shopping_closed_time.to_fs(:month_ja)
            link_path = shopping_result_path(shopping_closed_time.to_fs(:date_ym))

            expect(page).to have_link(link_text, href: link_path)
          end

          it "同月内に完了したお買い物が複数存在しても年月別のリンクは一つであること" do
            shopping_closed_time_1 = closed_user_shopping_records[0].updated_at
            shopping_closed_time_2 = closed_user_shopping_records[1].updated_at
            expect(shopping_closed_time_1).to eq shopping_closed_time_2
            link_text = shopping_closed_time_1.to_fs(:month_ja)
            link_path = shopping_result_path(shopping_closed_time_1.to_fs(:date_ym))

            expect(page).to have_link(link_text, href: link_path, count: 1)
          end

          it "お買い物履歴の年月別の一覧画面へのリンクをクリックすると年月別の一覧画面へ遷移すること" do
            shopping_closed_time = closed_user_shopping_records[0].updated_at
            link_text = shopping_closed_time.to_fs(:month_ja)
            link_path = shopping_result_path(shopping_closed_time.to_fs(:date_ym))

            click_link link_text

            expect(page).to have_http_status(:success)
            expect(current_path).to eq link_path
          end

          it "未完了状態のお買い物の更新年月が表記されたリンクが存在しないこと" do
            shopping_updated_time = unclosed_other_month_user_shopping_record.updated_at
            link_text = shopping_updated_time.to_fs(:month_ja)
            link_path = shopping_result_path(shopping_updated_time.to_fs(:date_ym))

            expect(page).to_not have_link(link_text, href: link_path)
          end

          it "別のユーザーのお買い物の完了年月が表記されたリンクが存在しないこと" do
            shopping_closed_time = closed_other_user_other_month_shopping_record.updated_at
            link_text_1 = shopping_closed_time.to_fs(:month_ja)
            link_path_1 = shopping_result_path(shopping_closed_time.to_fs(:date_ym))

            shopping_updated_time = unclosed_other_user_other_month_shopping_record.updated_at
            link_text_2 = shopping_updated_time.to_fs(:month_ja)
            link_path_2 = shopping_result_path(shopping_updated_time.to_fs(:date_ym))

            expect(page).to_not have_link(link_text_1, href: link_path_1)
            expect(page).to_not have_link(link_text_2, href: link_path_2)
          end
        end

        context "完了状態のお買い物が存在しない場合" do
          before do
            visit shopping_result_group_path
          end

          it "閲覧する年月を選択の項目が表示されないこと" do
            expect(page).to_not have_selector("h2", text: "閲覧する年月を選択")
          end

          it "お買い物履歴が存在しないメッセージが存在すること" do
            expect(page).to have_selector("h2", text: "お買い物履歴がありません")
          end
        end
      end

      describe "ページネーションのテスト" do
        let(:time_current) { Time.current }

        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
        end

        context "月を跨ぐお買い物履歴が10件以下の場合" do
          let(:closed_user_shopping_records) do
            create_list(
              :shopping_record, 10, :closed, :with_sequential_updated_at,
              start_date: time_current, user: user
            )
          end
          let!(:closed_user_shopping_buys) do
            closed_user_shopping_records.each do |record|
              create(
                :buy, :purchased,
                user: user, shopping_record: record,
                item_name: preset_item.name, item_hiragana: preset_item.hiragana
              )
            end
          end

          before do
            visit shopping_result_group_path
          end

          it "ページネーションのナビゲーションが存在しないこと" do
            expect(page).to_not have_selector("nav.pagy-bootstrap-nav")
          end
        end

        context "月を跨ぐお買い物履歴が10件を超える場合" do
          let(:closed_user_shopping_records) do
            create_list(
              :shopping_record, 11, :closed, :with_sequential_updated_at,
              start_date: time_current, user: user
            )
          end
          let!(:closed_user_shopping_buys) do
            closed_user_shopping_records.each do |record|
              create(
                :buy, :purchased,
                user: user, shopping_record: record,
                item_name: preset_item.name, item_hiragana: preset_item.hiragana
              )
            end
          end

          before do
            visit shopping_result_group_path
          end

          it "最初のページに10件の完了年月のリンクが存在すること" do
            closed_user_shopping_records.first(10).each do |record|
              expect(page).to have_link(record.updated_at.to_fs(:month_ja))
            end
          end

          it "最初のページに11件目の完了年月のリンクが存在しないこと" do
            eleventh_record = closed_user_shopping_records[10]
            expect(page).to_not have_link(eleventh_record.updated_at.to_fs(:month_ja))
          end

          it "ページネーションのナビゲーションが存在すること" do
            expect(page).to have_selector("nav.pagy-bootstrap-nav")
          end

          it "ページネーションの別のページへのリンクが存在すること" do
            within "nav.pagy-bootstrap-nav" do
              expect(page).to have_link("1", href: shopping_result_group_path(page: 1))
              expect(page).to have_link("2", href: shopping_result_group_path(page: 2))
              expect(page).to have_link("次", href: shopping_result_group_path(page: 2))
            end
          end

          it "最初のページの前ページへのリンクが非活性であること" do
            within "nav.pagy-bootstrap-nav" do
              expect(page).to have_link("前")
              expect(page).to have_selector("li.disabled", text: "前")
            end
          end

          context "2ページ目に移動した場合" do
            before do
              click_link "次"
              expect(URI.parse(current_url).request_uri).to eq shopping_result_group_path(page: 2)
            end

            it "11件目の完了年月のリンクが存在すること" do
              eleventh_record = closed_user_shopping_records[10]
              expect(page).to have_link(eleventh_record.updated_at.to_fs(:month_ja))
            end

            it "最初のページの10件の完了年月のリンクが存在しないこと" do
              closed_user_shopping_records.first(10).each do |record|
                expect(page).to_not have_link(record.updated_at.to_fs(:month_ja))
              end
            end

            it "ページネーションの別のページへのリンクが存在すること" do
              within "nav.pagy-bootstrap-nav" do
                expect(page).to have_link("前", href: shopping_result_group_path(page: 1))
                expect(page).to have_link("1", href: shopping_result_group_path(page: 1))
                expect(page).to have_link("2", href: shopping_result_group_path(page: 2))
              end
            end

            it "前ページへのリンクが活性状態であること" do
              within "nav.pagy-bootstrap-nav" do
                expect(page).to have_link("前", href: shopping_result_group_path(page: 1))
                expect(page).to_not have_selector("li.disabled", text: "前")
              end
            end

            it "次ページへのリンクが非活性であること" do
              within "nav.pagy-bootstrap-nav" do
                expect(page).to have_link("次")
                expect(page).to have_selector("li.disabled", text: "次")
              end
            end
          end
        end
      end
    end

    describe "result" do
      let(:user) { create(:user) }
      let!(:master_user) { create(:user, :master_admin) }
      let(:category) { create(:category) }
      let!(:preset_item) { create(:item, user: master_user, category: category) }
      let(:time_current) { Time.current }

      context "サインインしている場合" do
        # 一部テストでヘルパーメソッドを使用する
        include ShoppingRecordsHelper

        let(:closed_user_shopping_record) { create(:shopping_record, :closed, user: user, updated_at: time_current) }
        let(:unclosed_user_shopping_record) { create(:shopping_record, user: user, updated_at: time_current) }
        let!(:closed_user_shopping_buy) do
          create(
            :buy, :purchased,
            user: user, shopping_record: closed_user_shopping_record,
            item_name: preset_item.name, item_hiragana: preset_item.hiragana
          )
        end
        let!(:unclosed_user_shopping_buy) do
          create(:buy, user: user, shopping_record: unclosed_user_shopping_record,
                       item_name: preset_item.name, item_hiragana: preset_item.hiragana)
        end
        let(:other_user) { create(:user) }
        let(:closed_other_user_shopping_record) do
          create(:shopping_record, :closed, user: other_user, updated_at: time_current)
        end
        let(:unclosed_other_user_shopping_record) do
          create(:shopping_record, user: other_user, updated_at: time_current)
        end
        let!(:closed_other_user_shopping_buy) do
          create(
            :buy, :purchased,
            user: other_user, shopping_record: closed_other_user_shopping_record,
            item_name: preset_item.name, item_hiragana: preset_item.hiragana
          )
        end
        let!(:unclosed_other_user_shopping_buy) do
          create(:buy, user: other_user, shopping_record: unclosed_other_user_shopping_record,
                       item_name: preset_item.name, item_hiragana: preset_item.hiragana)
        end

        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
          visit shopping_result_path(date: time_current.to_fs(:date_ym))
        end

        include_examples "ユーザー情報の表示テスト"

        # ナビゲーションのテスト用変数
        let(:navigation_content) { "買い物結果を見たいお買い物の青色の「リスト」ボタンを押してね。" }

        include_examples "ナビゲーションのテスト"

        it "ページタイトルが表示されること" do
          expect(page).to have_selector("h1", text: "お買い物履歴")
        end

        it "年月選択に戻るリンクが存在すること" do
          expect(page).to have_link("年月選択 にもどる", href: shopping_result_group_path)
        end

        it "年月選択に戻るリンクをクリックして年月選択画面に遷移すること" do
          click_link "年月選択 にもどる"

          expect(page).to have_http_status(:success)
          expect(current_path).to eq shopping_result_group_path
        end

        it "年月履歴の一覧 の項目が表示されること" do
          expect(page).to have_selector("h2", text: "#{date_change_format_ja(time_current.to_fs(:date_ym))}の履歴一覧")
        end

        it "お買い物履歴のタイトルが表示されること" do
          expect(page).to have_selector("div.shopping-record-bg", text: closed_user_shopping_record.title)
        end

        it "お買い物履歴の完了年月日が表示されること" do
          within("div.shopping-record-bg", text: closed_user_shopping_record.title) do
            expect(page).to have_selector("h5", text: "完了： #{closed_user_shopping_record.updated_at.to_fs(:date_ymd_ja)}")
          end
        end

        it "お買い物履歴の詳細画面へのリンクが存在すること" do
          within("div.shopping-record-bg", text: closed_user_shopping_record.title) do
            expect(page).to have_link(href: shopping_results_path(closed_user_shopping_record.hashid))
          end
        end

        it "お買い物履歴の詳細画面へのリンクをクリックして詳細画面へ遷移すること" do
          within("div.shopping-record-bg", text: closed_user_shopping_record.title) do
            click_link(href: shopping_results_path(closed_user_shopping_record.hashid))
          end

          expect(page).to have_http_status(:success)
          expect(current_path).to eq shopping_results_path(closed_user_shopping_record.hashid)
        end

        it "お買い物履歴の削除ボタンが存在すること" do
          within("div.shopping-record-bg", text: closed_user_shopping_record.title) do
            expect(page).to have_selector("i.delete-icon")
          end
        end

        it "お買い物履歴削除ボタンをクリックするとモーダルが表示されること", js: true do
          expect(page).to have_selector("#turbo-confirm-modal", visible: false)

          within("div.shopping-record-bg", text: closed_user_shopping_record.title) do
            find("i.delete-icon").click
          end

          expect(page).to have_selector("#turbo-confirm-modal", visible: true)
        end

        it "お買い物履歴削除モーダルにタイトルが表示されること", js: true do
          within("div.shopping-record-bg", text: closed_user_shopping_record.title) do
            find("i.delete-icon").click
          end

          expect(page).to have_selector("#turbo-confirm-modal", visible: true)

          within "#turbo-confirm-modal" do
            expect(page).to have_selector("h1", visible: true, text: "お買い物履歴の削除")
          end
        end

        it "お買い物履歴削除モーダルのヘッダーにモーダルを閉じるボタンがあること", js: true do
          within("div.shopping-record-bg", text: closed_user_shopping_record.title) do
            find("i.delete-icon").click
          end

          expect(page).to have_selector("#turbo-confirm-modal", visible: true)

          within "#turbo-confirm-modal" do
            within ".modal-header" do
              expect(page).to have_selector("button.btn-close", visible: true)
            end
          end
        end

        it "お買い物履歴削除モーダルに削除ボタン・キャンセルボタンが表示されること", js: true do
          within("div.shopping-record-bg", text: closed_user_shopping_record.title) do
            find("i.delete-icon").click
          end

          expect(page).to have_selector("#turbo-confirm-modal", visible: true)

          within "#turbo-confirm-modal" do
            expect(page).to have_selector("button", visible: true, text: "削除する")
            expect(page).to have_selector("button", visible: true, text: "キャンセル")
          end
        end

        it "お買い物履歴削除モーダルのキャンセルボタンでお買い物削除を中止できること", js: true do
          within("div.shopping-record-bg", text: closed_user_shopping_record.title) do
            find("i.delete-icon").click
          end

          expect(page).to have_selector("#turbo-confirm-modal", visible: true)

          within "#turbo-confirm-modal" do
            click_button "キャンセル"
          end

          expect(page).to have_selector("#turbo-confirm-modal", visible: false)
        end

        it "お買い物履歴削除モーダルの外をクリックするとモーダルが閉じること", js: true do
          within("div.shopping-record-bg", text: closed_user_shopping_record.title) do
            find("i.delete-icon").click
          end

          expect(page).to have_selector("#turbo-confirm-modal", visible: true)

          # モーダルの外をクリック
          page.execute_script("document.querySelector('body').click();")

          expect(page).to have_selector("#turbo-confirm-modal", visible: false)
        end

        it "お買い物履歴削除ボタンからお買い物履歴が削除できること", js: true do
          within("div.shopping-record-bg", text: closed_user_shopping_record.title) do
            find("i.delete-icon").click
          end

          expect(page).to have_selector("#turbo-confirm-modal", visible: true)

          expect do
            within "#turbo-confirm-modal" do
              click_button "削除する"
            end

            within ".alert" do
              expect(page).to have_content "お買い物履歴が削除されました。"
            end

            expect(current_path).to eq shopping_result_group_path
          end.to change { ShoppingRecord.count }.by(-1)

          # お買い物履歴がDBに存在しないことを確認
          expect(ShoppingRecord.where(id: closed_user_shopping_record.id)).to_not exist
        end

        # ヘルプモーダルの基本機能テスト用変数
        let(:page_title) { "お買い物履歴" }

        include_examples "ヘルプモーダルの基本機能テスト"

        it "ヘルプモーダル内の主な項目が正しく表示されること" do
          within "#helpModal.modal" do
            expect(page).to have_selector("h3", text: "ボタンについて")
            expect(page).to have_selector("h4", text: "各ボタンの説明")
            expect(page).to have_selector("i.fa-rectangle-list")
            expect(page).to have_selector("h5", text: "詳細閲覧ボタン")
            expect(page).to have_selector("i.fa-trash-can")
            expect(page).to have_selector("h5", text: "削除ボタン")
          end
        end

        it "未完了のお買い物タイトルが表示されないこと" do
          expect(page).to_not have_selector("div.shopping-record-bg", text: unclosed_user_shopping_record.title)
        end

        it "別のユーザーのお買い物タイトルが表示されないこと" do
          expect(page).to_not have_selector("div.shopping-record-bg", text: closed_other_user_shopping_record.title)
          expect(page).to_not have_selector("div.shopping-record-bg", text: unclosed_other_user_shopping_record.title)
        end
      end

      context "サインインしていない場合" do
        before do
          visit shopping_result_path(date: time_current.to_fs(:date_ym))
        end

        include_examples "非ログイン状態で認可が必要なページにアクセスした時のリダイレクトテスト"
      end

      describe "クエリパラメータにお買い物履歴の無い年月を指定したときの制御" do
        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
          visit shopping_result_path(date: time_current.to_fs(:date_ym))
        end

        it "お買い物履歴の年月選択画面にリダイレクトすること" do
          expect(page).to have_content "指定した年月のお買い物履歴は存在しません。"
          expect(current_path).to eq shopping_result_group_path
        end
      end

      describe "お買い物履歴の件数で異なる箇所のテスト" do
        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
        end

        context "お買物履歴が1件の場合" do
          let(:closed_user_shopping_record) { create(:shopping_record, :closed, user: user, updated_at: time_current) }
          let!(:closed_user_shopping_buy) do
            create(
              :buy, :purchased,
              user: user, shopping_record: closed_user_shopping_record,
              item_name: preset_item.name, item_hiragana: preset_item.hiragana
            )
          end

          before do
            visit shopping_result_path(date: time_current.to_fs(:date_ym))
          end

          it "お買物履歴の新旧を示すガイドが表示されないこと" do
            expect(page).to_not have_selector("div.latest-oldest-icon")
          end
        end

        context "お買物履歴が2件以上の場合" do
          let(:closed_user_shopping_records) { create_list(:shopping_record, 2, :closed, user: user, updated_at: time_current) }
          let!(:closed_user_shopping_buys) do
            closed_user_shopping_records.each do |record|
              create(
                :buy, :purchased,
                user: user, shopping_record: record,
                item_name: preset_item.name, item_hiragana: preset_item.hiragana
              )
            end
          end

          before do
            visit shopping_result_path(date: time_current.to_fs(:date_ym))
          end

          it "お買物履歴の新旧を示すガイドが表示されること" do
            expect(page).to have_selector("div.latest-oldest-icon")
            within "div.latest-oldest-icon" do
              expect(page).to have_content "新"
              expect(page).to have_content "古"
            end
          end
        end
      end

      describe "ページネーションのテスト" do
        let(:closed_user_shopping_records) { create_list(:shopping_record, 10, :closed, user: user, updated_at: time_current) }
        let!(:closed_user_shopping_buys) do
          closed_user_shopping_records.each do |record|
            create(
              :buy, :purchased,
              user: user, shopping_record: record,
              item_name: preset_item.name, item_hiragana: preset_item.hiragana
            )
          end
        end

        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
        end

        context "お買い物履歴が10件以下の場合" do
          before do
            visit shopping_result_path(date: time_current.to_fs(:date_ym))
          end

          it "ページネーションのナビゲーションが存在しないこと" do
            expect(page).to_not have_selector("nav.pagy-bootstrap-nav")
          end
        end

        context "お買い物履歴が10件を超える場合" do
          let(:eleventh_closed_user_shopping_record) { create(:shopping_record, :closed, user: user, updated_at: time_current) }
          let!(:eleventh_closed_user_shopping_buy) do
            create(
              :buy, :purchased,
              user: user, shopping_record: eleventh_closed_user_shopping_record,
              item_name: preset_item.name, item_hiragana: preset_item.hiragana
            )
          end
          let(:params_date_ym) { time_current.to_fs(:date_ym) }

          before do
            visit shopping_result_path(date: params_date_ym)
          end

          it "最初のページに10件のお買い物履歴が存在すること" do
            closed_user_shopping_records.first(10).each do |record|
              expect(page).to have_selector("div.shopping-record-bg", text: record.title)
              within("div.shopping-record-bg", text: record.title) do
                expect(page).to have_link(href: shopping_results_path(record.hashid))
                expect(page).to have_selector("i.delete-icon")
              end
            end
          end

          it "最初のページに11件目のお買い物履歴が存在しないこと" do
            expect(page).to_not have_selector("div.shopping-record-bg", text: eleventh_closed_user_shopping_record.title)
          end

          it "ページネーションのナビゲーションが存在すること" do
            expect(page).to have_selector("nav.pagy-bootstrap-nav")
          end

          it "ページネーションの別のページへのリンクが存在すること" do
            within "nav.pagy-bootstrap-nav" do
              expect(page).to have_link("1", href: shopping_result_path(date: params_date_ym, page: 1))
              expect(page).to have_link("2", href: shopping_result_path(date: params_date_ym, page: 2))
              expect(page).to have_link("次", href: shopping_result_path(date: params_date_ym, page: 2))
            end
          end

          it "最初のページの前ページへのリンクが非活性であること" do
            within "nav.pagy-bootstrap-nav" do
              expect(page).to have_link("前")
              expect(page).to have_selector("li.disabled", text: "前")
            end
          end

          context "2ページ目に移動した場合" do
            before do
              click_link "次"
              expect(URI.parse(current_url).request_uri).to eq shopping_result_path(date: params_date_ym, page: 2)
            end

            it "11件目のお買い物履歴が存在すること" do
              expect(page).to have_selector("div.shopping-record-bg", text: eleventh_closed_user_shopping_record.title)
              within("div.shopping-record-bg", text: eleventh_closed_user_shopping_record.title) do
                expect(page).to have_link(href: shopping_results_path(eleventh_closed_user_shopping_record.hashid))
                expect(page).to have_selector("i.delete-icon")
              end
            end

            it "最初のページの10件のお買い物履歴が存在しないこと" do
              closed_user_shopping_records.first(10).each do |record|
                expect(page).to_not have_selector("div.shopping-record-bg", text: record.title)
              end
            end

            it "ページネーションの別のページへのリンクが存在すること" do
              within "nav.pagy-bootstrap-nav" do
                expect(page).to have_link("前", href: shopping_result_path(date: params_date_ym, page: 1))
                expect(page).to have_link("1", href: shopping_result_path(date: params_date_ym, page: 1))
                expect(page).to have_link("2", href: shopping_result_path(date: params_date_ym, page: 2))
              end
            end

            it "前ページへのリンクが活性状態であること" do
              within "nav.pagy-bootstrap-nav" do
                expect(page).to have_link("前", href: shopping_result_path(date: params_date_ym, page: 1))
                expect(page).to_not have_selector("li.disabled", text: "前")
              end
            end

            it "次ページへのリンクが非活性であること" do
              within "nav.pagy-bootstrap-nav" do
                expect(page).to have_link("次")
                expect(page).to have_selector("li.disabled", text: "次")
              end
            end
          end
        end
      end
    end

    describe "show" do
      let(:user) { create(:user) }
      let!(:master_user) { create(:user, :master_admin) }
      let(:category) { create(:category) }

      describe "共通項目のテスト" do
        let!(:preset_item) { create(:item, user: master_user, category: category) }
        let(:user_shopping_record) { create(:shopping_record, :closed, user: user) }
        let!(:buy) do
          create(
            :buy, :purchased,
            user: user, shopping_record: user_shopping_record,
            item_name: preset_item.name, item_hiragana: preset_item.hiragana
          )
        end

        context "サインインしている場合" do
          before do
            sign_in_as(user)
            # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
            expect(page).to have_content "ログインしました。"
            visit shopping_results_path(user_shopping_record.hashid)
          end

          include_examples "ユーザー情報の表示テスト"

          # ナビゲーションのテスト用変数
          let(:navigation_content) { "「#{user_shopping_record.title}」のお買い物結果を表示するよ！" }

          include_examples "ナビゲーションのテスト"

          it "月別のお買い物履歴一覧画面に遷移するリンクが存在すること" do
            expect(page).to have_link("履歴一覧 にもどる", href: shopping_result_path(user_shopping_record.updated_at.to_fs(:date_ym)))
          end

          it "月別のお買い物履歴一覧画面のリンクをクリックして履歴一覧画面に遷移すること" do
            click_link "履歴一覧 にもどる"

            expect(page).to have_http_status(:success)
            expect(current_path).to eq shopping_result_path(user_shopping_record.updated_at.to_fs(:date_ym))
          end

          it "ページタイトルが表示されること" do
            expect(page).to have_selector("h1", text: "お買い物履歴の詳細")
          end

          it "お買い物結果の項目が表示されること" do
            within ".confirm-window-text" do
              expect(page).to have_selector("h2", text: "お買い物結果")
            end
          end

          it "お買い物のタイトルが表示されること" do
            within ".confirm-window-text" do
              expect(page).to have_selector("h4", text: "お買い物タイトル")
              expect(page).to have_selector("span.h5", text: user_shopping_record.title)
            end
          end

          it "お買い物完了日が表示されること" do
            within ".confirm-window-text" do
              expect(page).to have_selector("h4", text: "お買い物完了日")
              expect(page).to have_selector("span.h5", text: user_shopping_record.updated_at.to_fs(:date_ymd_ja))
            end
          end

          it "買ったアイテムの項目が表示されること" do
            within ".confirm-window-text" do
              expect(page).to have_selector("h4", text: "買ったアイテム")
            end
          end

          it "買わなかったアイテムの項目が表示されること" do
            within ".confirm-window-text" do
              expect(page).to have_selector("h4", text: "買わなかったアイテム")
            end
          end

          it "お買い物場所の項目が表示されること" do
            within ".confirm-window-text" do
              expect(page).to have_selector("h4", text: "お買い物した場所")
            end
          end

          # ヘルプモーダルの基本機能テスト用変数
          let(:page_title) { "お買い物履歴の詳細" }

          include_examples "ヘルプモーダルの基本機能テスト"

          it "ヘルプモーダル内の主な項目が正しく表示されること" do
            within "#helpModal.modal" do
              expect(page).to have_selector("h3", text: "ボタンについて")
              expect(page).to have_selector("h4", text: "各ボタンの説明")
              expect(page).to have_selector("i.fa-location-dot")
              expect(page).to have_selector("h5", text: "マップ登録ボタン")
              expect(page).to have_selector("i.fa-pencil")
              expect(page).to have_selector("h5", text: "マップ編集ボタン")
              expect(page).to have_selector("i.fa-trash-can")
              expect(page).to have_selector("h5", text: "マップ削除ボタン")
            end
          end
        end

        context "サインインしていない場合" do
          before do
            visit shopping_results_path(user_shopping_record.hashid)
          end

          include_examples "非ログイン状態で認可が必要なページにアクセスした時のリダイレクトテスト"
        end
      end

      describe "お買い物のアイテムの購入状態により異なる箇所のテスト" do
        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
        end

        context "買ったアイテムと買わなかったアイテムがある場合" do
          let!(:preset_item_1) { create(:item, user: master_user, category: category) }
          let!(:preset_item_2) { create(:item, user: master_user, category: category) }
          let(:user_shopping_record) { create(:shopping_record, :closed, user: user) }
          let!(:purchased_buy) do
            create(
              :buy, :purchased,
              user: user, shopping_record: user_shopping_record,
              item_name: preset_item_1.name, item_hiragana: preset_item_1.hiragana
            )
          end
          let!(:unpurchased_buy) do
            create(:buy, user: user, shopping_record: user_shopping_record,
                         item_name: preset_item_2.name, item_hiragana: preset_item_2.hiragana)
          end

          before do
            visit shopping_results_path(user_shopping_record.hashid)
          end

          it "買ったアイテムの項目に購入アイテムが表示されること" do
            within(".confirm-window", text: "買ったアイテム") do
              expect(page).to have_selector("li", text: purchased_buy.item_name)
            end
          end

          it "買ったアイテムの項目に未購入アイテムが表示されないこと" do
            within(".confirm-window", text: "買ったアイテム") do
              expect(page).to_not have_selector("li", text: unpurchased_buy.item_name)
            end
          end

          it "買わなかったアイテムの項目に未購入アイテムが表示されること" do
            within(".confirm-window", text: "買わなかったアイテム") do
              expect(page).to have_selector("li", text: unpurchased_buy.item_name)
            end
          end

          it "買わなかったアイテムの項目に購入アイテムが表示されないこと" do
            within(".confirm-window", text: "買わなかったアイテム") do
              expect(page).to_not have_selector("li", text: purchased_buy.item_name)
            end
          end

          it "買ったアイテムの項目に「購入アイテムなし」が表示されないこと" do
            within(".confirm-window", text: "買ったアイテム") do
              expect(page).to_not have_selector("h5", text: "購入アイテムなし")
            end
          end

          it "買わなかったアイテムの項目に「未購入アイテムなし」が表示されないこと" do
            within(".confirm-window", text: "買わなかったアイテム") do
              expect(page).to_not have_selector("h5", text: "未購入アイテムなし")
            end
          end
        end

        context "買ったアイテムがない場合" do
          let!(:preset_item) { create(:item, user: master_user, category: category) }
          let(:user_shopping_record) { create(:shopping_record, :closed, user: user) }
          let!(:unpurchased_buy) do
            create(:buy, user: user, shopping_record: user_shopping_record,
                         item_name: preset_item.name, item_hiragana: preset_item.hiragana)
          end

          before do
            visit shopping_results_path(user_shopping_record.hashid)
          end

          it "買ったアイテムの項目に「購入アイテムなし」が表示されること" do
            within(".confirm-window", text: "買ったアイテム") do
              expect(page).to have_selector("h5", text: "購入アイテムなし")
            end
          end
        end

        context "買わなかったアイテムがない場合" do
          let!(:preset_item) { create(:item, user: master_user, category: category) }
          let(:user_shopping_record) { create(:shopping_record, :closed, user: user) }
          let!(:purchased_buy) do
            create(
              :buy, :purchased,
              user: user, shopping_record: user_shopping_record,
              item_name: preset_item.name, item_hiragana: preset_item.hiragana
            )
          end

          before do
            visit shopping_results_path(user_shopping_record.hashid)
          end

          it "買わなかったアイテムの項目に「未購入アイテムなし」が表示されること" do
            within(".confirm-window", text: "買わなかったアイテム") do
              expect(page).to have_selector("h5", text: "未購入アイテムなし")
            end
          end
        end
      end

      describe "ひらがなモードの設定により異なる箇所のテスト" do
        let!(:preset_item_1) { create(:item, user: master_user, category: category) }
        let!(:preset_item_2) { create(:item, user: master_user, category: category) }
        let(:user_shopping_record) { create(:shopping_record, :closed, user: user) }
        let!(:purchased_buy) do
          create(
            :buy, :purchased,
            user: user, shopping_record: user_shopping_record,
            item_name: preset_item_1.name, item_hiragana: preset_item_1.hiragana
          )
        end
        let!(:unpurchased_buy) do
          create(:buy, user: user, shopping_record: user_shopping_record,
                       item_name: preset_item_2.name, item_hiragana: preset_item_2.hiragana)
        end

        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
        end

        context "ひらがなモードOFF（デフォルト）の場合" do
          before do
            visit shopping_results_path(user_shopping_record.hashid)
          end

          it "買ったアイテムと買わなかったアイテムがアイテム名(item_name)で表示されること" do
            within(".confirm-window", text: "買ったアイテム") do
              expect(page).to have_selector("li", text: purchased_buy.item_name)
            end

            within(".confirm-window", text: "買わなかったアイテム") do
              expect(page).to have_selector("li", text: unpurchased_buy.item_name)
            end
          end

          it "買ったアイテムと買わなかったアイテムがひらがな（アイテム名）(item_hiragana)で表示されないこと" do
            within(".confirm-window", text: "買ったアイテム") do
              expect(page).to_not have_selector("li", text: purchased_buy.item_hiragana)
            end

            within(".confirm-window", text: "買わなかったアイテム") do
              expect(page).to_not have_selector("li", text: unpurchased_buy.item_hiragana)
            end
          end
        end

        context "ひらがなモードONの場合" do
          before do
            user.update(hiragana_view: true)
            visit shopping_results_path(user_shopping_record.hashid)
          end

          it "買ったアイテムと買わなかったアイテムがひらがな（アイテム名）(item_hiragana)で表示されること" do
            within(".confirm-window", text: "買ったアイテム") do
              expect(page).to have_selector("li", text: purchased_buy.item_hiragana)
            end

            within(".confirm-window", text: "買わなかったアイテム") do
              expect(page).to have_selector("li", text: unpurchased_buy.item_hiragana)
            end
          end

          it "買ったアイテムと買わなかったアイテムがアイテム名(item_name)で表示されないこと" do
            within(".confirm-window", text: "買ったアイテム") do
              expect(page).to_not have_selector("li", text: purchased_buy.item_name)
            end

            within(".confirm-window", text: "買わなかったアイテム") do
              expect(page).to_not have_selector("li", text: unpurchased_buy.item_name)
            end
          end
        end
      end

      describe "お買い物場所の登録有無により異なる箇所のテスト" do
        let!(:preset_item) { create(:item, user: master_user, category: category) }
        let(:user_shopping_record) { create(:shopping_record, :closed, user: user) }
        let!(:purchased_buy) do
          create(
            :buy, :purchased,
            user: user, shopping_record: user_shopping_record,
            item_name: preset_item.name, item_hiragana: preset_item.hiragana
          )
        end

        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
        end

        context "お買い物場所が登録されていない場合" do
          before do
            visit shopping_results_path(user_shopping_record.hashid)
          end

          it "お買い物した場所の項目内容が「登録なし」と表示されること" do
            within(".confirm-window", text: "お買い物した場所") do
              expect(page).to have_selector("h4", text: "登録なし")
            end
          end

          it "お買い物場所登録画面へのリンクが存在すること" do
            within(".confirm-window", text: "お買い物した場所") do
              expect(page).to have_selector("i.fa-location-dot")
              expect(page).to have_link(href: new_shopping_location_path(user_shopping_record.hashid))
            end
          end

          it "お買い物場所登録へのリンクをクリックしてお買い物場所登録画面へ遷移すること" do
            within(".confirm-window", text: "お買い物した場所") do
              click_link(href: new_shopping_location_path(user_shopping_record.hashid))
            end

            expect(page).to have_http_status(:success)
            expect(current_path).to eq new_shopping_location_path(user_shopping_record.hashid)
          end

          it "お買い物場所編集画面へのリンクが存在しないこと" do
            within(".confirm-window", text: "お買い物した場所") do
              expect(page).to_not have_selector("i.fa-pencil")
              expect(page).to_not have_link(href: edit_shopping_location_path(user_shopping_record.hashid))
            end
          end

          it "お買い物場所削除ボタンが存在しないこと" do
            within(".confirm-window", text: "お買い物した場所") do
              expect(page).to_not have_selector("i.fa-trash-can")
            end
          end

          it "Googleマップが表示される領域が存在しないこと" do
            within(".confirm-window", text: "お買い物した場所") do
              expect(page).to_not have_selector("div#map")
            end
          end
        end

        context "お買い物場所が登録されている場合" do
          let!(:user_shopping_location) do
            create(:shopping_location, shopping_record: user_shopping_record, latitude: 35.68956, longitude: 139.69167)
          end

          before do
            visit shopping_results_path(user_shopping_record.hashid)
          end

          it "Googleマップが表示される領域が存在すること" do
            within(".confirm-window", text: "お買い物した場所") do
              expect(page).to have_selector("div#map")
            end
          end

          it "お買い物した場所の項目内容に「登録なし」が表示されないこと" do
            within(".confirm-window", text: "お買い物した場所") do
              expect(page).to_not have_selector("h4", text: "登録なし")
            end
          end

          it "お買い物場所編集画面へのリンクが存在すること" do
            within(".confirm-window", text: "お買い物した場所") do
              expect(page).to have_selector("i.fa-pencil")
              expect(page).to have_link(href: edit_shopping_location_path(user_shopping_record.hashid))
            end
          end

          it "お買い物場所編集へのリンクをクリックしてお買い物場所編集画面へ遷移すること" do
            within(".confirm-window", text: "お買い物した場所") do
              click_link(href: edit_shopping_location_path(user_shopping_record.hashid))
            end

            expect(page).to have_http_status(:success)
            expect(current_path).to eq edit_shopping_location_path(user_shopping_record.hashid)
          end

          it "お買い物場所削除ボタンが存在すること" do
            within(".confirm-window", text: "お買い物した場所") do
              expect(page).to have_selector("i.fa-trash-can")
            end
          end

          it "お買い物場所削除ボタンをクリックするとモーダルが表示されること", js: true do
            expect(page).to have_selector("#turbo-confirm-modal", visible: false)

            within(".confirm-window", text: "お買い物した場所") do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)
          end

          it "お買い物場所削除モーダルにタイトルが表示されること", js: true do
            within(".confirm-window", text: "お買い物した場所") do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            within "#turbo-confirm-modal" do
              expect(page).to have_selector("h1", visible: true, text: "お買い物場所の削除")
            end
          end

          it "お買い物場所削除モーダルのヘッダーにモーダルを閉じるボタンがあること", js: true do
            within(".confirm-window", text: "お買い物した場所") do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            within "#turbo-confirm-modal" do
              within ".modal-header" do
                expect(page).to have_selector("button.btn-close", visible: true)
              end
            end
          end

          it "お買い物場所削除モーダルに削除ボタン・キャンセルボタンが表示されること", js: true do
            within(".confirm-window", text: "お買い物した場所") do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            within "#turbo-confirm-modal" do
              expect(page).to have_selector("button", visible: true, text: "削除する")
              expect(page).to have_selector("button", visible: true, text: "キャンセル")
            end
          end

          it "お買い物場所削除モーダルのキャンセルボタンでお買い物削除を中止できること", js: true do
            within(".confirm-window", text: "お買い物した場所") do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            within "#turbo-confirm-modal" do
              click_button "キャンセル"
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: false)
          end

          it "お買い物場所削除モーダルの外をクリックするとモーダルが閉じること", js: true do
            within(".confirm-window", text: "お買い物した場所") do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            # モーダルの外をクリック
            page.execute_script("document.querySelector('body').click();")

            expect(page).to have_selector("#turbo-confirm-modal", visible: false)
          end

          it "お買い物場所削除ボタンからお買い物場所が削除できること", js: true do
            within(".confirm-window", text: "お買い物した場所") do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            expect do
              within "#turbo-confirm-modal" do
                click_button "削除する"
              end

              within ".alert" do
                expect(page).to have_content "お買い物場所が削除されました。"
              end

              expect(current_path).to eq shopping_results_path(user_shopping_record.hashid)
            end.to change { ShoppingLocation.count }.by(-1)

            # お買い物場所がDBに存在しないことを確認
            expect(ShoppingLocation.where(id: user_shopping_record.shopping_location.id)).to_not exist
          end

          it "お買い物場所登録画面へのリンクが存在しないこと" do
            within(".confirm-window", text: "お買い物した場所") do
              expect(page).to_not have_selector("i.fa-location-dot")
              expect(page).to_not have_link(href: new_shopping_location_path(user_shopping_record.hashid))
            end
          end
        end
      end

      describe "Google Mapsに関連する箇所のテスト", js: true do
        let!(:preset_item) { create(:item, user: master_user, category: category) }
        let(:shopping_record) { create(:shopping_record, :closed, user: user) }
        let!(:purchased_buy) do
          create(
            :buy, :purchased,
            user: user, shopping_record: shopping_record,
            item_name: preset_item.name, item_hiragana: preset_item.hiragana
          )
        end
        let!(:shopping_location) do
          create(:shopping_location, shopping_record: shopping_record, latitude: 35.68956, longitude: 139.69167)
        end

        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"

          @google_maps_script_id = google_maps_mock_setup
          visit shopping_results_path(shopping_record.hashid)
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

  describe "お買い物履歴閲覧のフロー" do
    let(:user) { create(:user) }
    let!(:master_user) { create(:user, :master_admin) }
    let(:category) { create(:category) }
    let!(:item) { create(:item, user: master_user, category: category) }
    let(:shopping_record) { create(:shopping_record, :closed, user: user) }
    let!(:shopping_record_buy) do
      create(
        :buy, :purchased,
        user: user, shopping_record: shopping_record,
        item_name: item.name, item_hiragana: item.hiragana
      )
    end

    before do
      sign_in_as(user)
      # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
      expect(page).to have_content "ログインしました。"
      visit shopping_result_group_path
    end

    context "正常系" do
      # 一部ビューの表示箇所にヘルパーメソッドを使用する
      include ShoppingRecordsHelper

      scenario "ユーザーがお買い物履歴を閲覧する" do
        # 年月選択画面
        expect(page).to have_selector("h2", text: "閲覧する年月を選択")

        shopping_closed_time = shopping_record.updated_at
        link_text = shopping_closed_time.to_fs(:month_ja)
        link_path = shopping_result_path(shopping_closed_time.to_fs(:date_ym))
        expect(page).to have_link(link_text, href: link_path)
        click_link link_text

        # 履歴選択画面
        expect(page).to have_selector("h2", text: "#{date_change_format_ja(shopping_closed_time.to_fs(:date_ym))}の履歴一覧")

        within("div.shopping-record-bg", text: shopping_record.title) do
          click_link(href: shopping_results_path(shopping_record.hashid))
        end

        # 履歴詳細画面
        expect(page).to have_selector("h1", text: "お買い物履歴の詳細")

        # 履歴詳細の内容
        within(".confirm-window-text", text: "お買い物結果") do
          expect(page).to have_selector("h4", text: "お買い物タイトル")
          expect(page).to have_selector("span.h5", text: shopping_record.title)
          expect(page).to have_selector("h4", text: "お買い物完了日")
          expect(page).to have_selector("span.h5", text: shopping_closed_time.to_fs(:date_ymd_ja))
          within(".confirm-window", text: "買ったアイテム") do
            expect(page).to have_selector("li", text: shopping_record_buy.item_name)
          end
          within(".confirm-window", text: "買わなかったアイテム") do
            expect(page).to have_selector("h5", text: "未購入アイテムなし")
          end
          # マップ登録有無によるフローは別途shopping_locations_specで実施
          within(".confirm-window", text: "お買い物した場所") do
            expect(page).to have_selector("h4", text: "登録なし")
          end
        end
      end
    end

    context "異常系" do
      let(:unclosed_shopping_record) { create(:shopping_record, user: user) }
      let!(:unclosed_shopping_record_buy) do
        create(:buy, user: user, shopping_record: unclosed_shopping_record,
                     item_name: item.name, item_hiragana: item.hiragana)
      end
      let(:other_user) { create(:user) }
      let(:other_user_shopping_record) { create(:shopping_record, :closed, user: other_user) }
      let!(:other_user_shopping_record_buy) do
        create(:buy, user: other_user, shopping_record: other_user_shopping_record,
                     item_name: item.name, item_hiragana: item.hiragana)
      end

      scenario "未完了状態のお買い物のhashidでお買い物履歴へのアクセスを試みる" do
        visit shopping_results_path(unclosed_shopping_record.hashid)

        within ".alert" do
          expect(page).to have_content "指定されたお買い物履歴は存在しません。"
        end
        expect(current_path).to eq shopping_result_group_path
      end

      scenario "他のユーザーの完了状態のお買い物のhashidでお買い物履歴へのアクセスを試みる" do
        visit shopping_results_path(other_user_shopping_record.hashid)

        within ".alert" do
          expect(page).to have_content "指定されたお買い物履歴は存在しません。"
        end
        expect(current_path).to eq shopping_result_group_path
      end

      scenario "不正なhashidでお買い物履歴へのアクセスを試みる" do
        visit shopping_results_path("invalid_hashid")

        within ".alert" do
          expect(page).to have_content "指定されたお買い物履歴は存在しません。"
        end
        expect(current_path).to eq shopping_result_group_path
      end
    end
  end

  describe "お買い物履歴削除のフロー", js: true do
    let(:user) { create(:user) }
    let!(:master_user) { create(:user, :master_admin) }
    let(:category) { create(:category) }
    let!(:item) { create(:item, user: master_user, category: category) }
    let(:shopping_record) { create(:shopping_record, :closed, user: user) }
    let!(:shopping_record_buy) do
      create(
        :buy, :purchased,
        user: user, shopping_record: shopping_record,
        item_name: item.name, item_hiragana: item.hiragana
      )
    end

    before do
      sign_in_as(user)
      # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
      expect(page).to have_content "ログインしました。"
      visit shopping_result_group_path

      # 月別履歴一覧画面へ遷移する
      shopping_closed_time = shopping_record.updated_at
      link_text = shopping_closed_time.to_fs(:month_ja)
      click_link link_text
    end

    scenario "ユーザーがお買い物履歴を削除する" do
      within("div.shopping-record-bg", text: shopping_record.title) do
        find("i.delete-icon").click
      end

      expect(page).to have_selector("#turbo-confirm-modal", visible: true)

      expect do
        within "#turbo-confirm-modal" do
          click_button "削除する"
        end

        within ".alert" do
          expect(page).to have_content "お買い物履歴が削除されました。"
        end

        expect(current_path).to eq shopping_result_group_path
      end.to change { ShoppingRecord.count }.by(-1)

      # お買い物履歴がDBに存在しないことを確認
      expect(ShoppingRecord.where(id: shopping_record.id)).to_not exist
    end
  end
end
