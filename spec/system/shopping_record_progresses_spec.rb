require 'rails_helper'

# お買い物モード機能関連のテスト
RSpec.describe "ShoppingRecordProgresses", type: :system do
  describe "ビューの要素" do
    describe "index" do
      let(:user) { create(:user) }

      context "サインインしている場合" do
        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
          visit shopping_index_path
        end

        include_examples "ユーザー情報の表示テスト"

        # ナビゲーションのテスト用変数
        let(:navigation_content) { "ここはお買い物モードを始める画面だよ！" }

        include_examples "ナビゲーションのテスト"

        it "ページタイトルが表示されること" do
          expect(page).to have_selector("h1", text: "お買い物モード")
        end

        it "メインメニューに戻るリンクが存在すること" do
          expect(page).to have_link("メインメニュー にもどる", href: root_path)
        end

        it "メインメニューに戻るリンクをクリックしてrootページに遷移すること" do
          click_link "メインメニュー にもどる"

          expect(page).to have_http_status(:success)
          expect(current_path).to eq root_path
        end

        # ヘルプモーダルの基本機能テスト用変数
        let(:page_title) { "お買い物モード" }

        include_examples "ヘルプモーダルの基本機能テスト"

        it "ヘルプモーダル内の主な項目が正しく表示されること" do
          within "#helpModal.modal" do
            expect(page).to have_selector("h3", text: "ボタンについて")
            expect(page).to have_selector("h4", text: "各ボタンの説明")
            expect(page).to have_selector("i.fa-cart-shopping")
            expect(page).to have_selector("h5", text: "お買い物開始ボタン")
            expect(page).to have_selector("i.fa-trash-can")
            expect(page).to have_selector("h5", text: "削除ボタン")
          end
        end
      end

      context "サインインしていない場合" do
        before do
          visit shopping_index_path
        end

        include_examples "非ログイン状態で認可が必要なページにアクセスした時のリダイレクトテスト"
      end

      describe "お買い物登録の有無で異なる箇所のテスト" do
        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
        end

        context "未完了のお買い物が存在する場合" do
          let!(:master_user) { create(:user, :master_admin) }
          let(:category) { create(:category) }
          let!(:preset_item) { create(:item, user: master_user, category: category) }
          let(:unclosed_user_shopping_records) { create_list(:shopping_record, 2, user: user) }
          let(:closed_user_shopping_record) { create(:shopping_record, :closed, user: user) }
          let!(:unclosed_user_shopping_buys) do
            unclosed_user_shopping_records.each do |record|
              create(:buy, user: user, shopping_record: record,
                           item_name: preset_item.name, item_hiragana: preset_item.hiragana)
            end
          end
          let!(:closed_user_shopping_buy) do
            create(
              :buy, :purchased,
              user: user, shopping_record: closed_user_shopping_record,
              item_name: preset_item.name, item_hiragana: preset_item.hiragana
            )
          end
          let(:other_user) { create(:user) }
          let(:unclosed_other_user_shopping_record) { create(:shopping_record, user: other_user) }
          let(:closed_other_user_shopping_record) { create(:shopping_record, :closed, user: other_user) }
          let!(:unclosed_other_user_shopping_buy) do
            create(:buy, user: other_user, shopping_record: unclosed_other_user_shopping_record,
                         item_name: preset_item.name, item_hiragana: preset_item.hiragana)
          end
          let!(:closed_other_user_shopping_buy) do
            create(
              :buy, :purchased,
              user: other_user, shopping_record: closed_other_user_shopping_record,
              item_name: preset_item.name, item_hiragana: preset_item.hiragana
            )
          end

          before do
            visit shopping_index_path
          end

          it "お買い物選択の項目が表示されること" do
            expect(page).to have_selector("h2", text: "お買い物選択")
          end

          it "未完了状態のお買い物のタイトルが表示されること" do
            unclosed_user_shopping_records.each do |record|
              expect(page).to have_selector("h4", text: record.title)
            end
          end

          it "別のユーザーのお買い物のタイトルが表示されないこと" do
            expect(page).to_not have_selector("h4", text: unclosed_other_user_shopping_record.title)
            expect(page).to_not have_selector("h4", text: closed_other_user_shopping_record.title)
          end

          it "完了状態のお買い物のタイトルが表示されないこと" do
            expect(page).to_not have_selector("h4", text: closed_user_shopping_record.title)
          end

          it "表示中の各お買い物にお買い物画面へ遷移するリンクが存在すること" do
            unclosed_user_shopping_records.each do |record|
              within("div.shopping-record-bg", text: record.title) do
                have_link(href: shopping_progress_path(record.hashid))
              end
            end
          end

          it "お買い物画面へのリンクをクリックしてお買い物画面へ遷移できること" do
            within("div.shopping-record-bg", text: unclosed_user_shopping_records[0].title) do
              click_link(href: shopping_progress_path(unclosed_user_shopping_records[0].hashid))
            end

            expect(page).to have_http_status(:success)
            expect(current_path).to eq shopping_progress_path(unclosed_user_shopping_records[0].hashid)
          end

          it "表示中の各お買い物にお買い物削除ボタンが存在すること" do
            unclosed_user_shopping_records.each do |record|
              within("div.shopping-record-bg", text: record.title) do
                expect(page).to have_selector("i.delete-icon")
              end
            end
          end

          it "お買い物削除ボタンをクリックするとモーダルが表示されること", js: true do
            expect(page).to have_selector("#turbo-confirm-modal", visible: false)

            within("div.shopping-record-bg", text: unclosed_user_shopping_records[0].title) do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)
          end

          it "お買い物削除モーダルにタイトルが表示されること", js: true do
            within("div.shopping-record-bg", text: unclosed_user_shopping_records[0].title) do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            within "#turbo-confirm-modal" do
              expect(page).to have_selector("h1", visible: true, text: "お買い物の削除")
            end
          end

          it "お買い物削除モーダルのヘッダーにモーダルを閉じるボタンがあること", js: true do
            within("div.shopping-record-bg", text: unclosed_user_shopping_records[0].title) do
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
            within("div.shopping-record-bg", text: unclosed_user_shopping_records[0].title) do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            within "#turbo-confirm-modal" do
              expect(page).to have_selector("button", visible: true, text: "削除する")
              expect(page).to have_selector("button", visible: true, text: "キャンセル")
            end
          end

          it "お買い物削除モーダルのキャンセルボタンでお買い物削除を中止できること", js: true do
            within("div.shopping-record-bg", text: unclosed_user_shopping_records[0].title) do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            within "#turbo-confirm-modal" do
              click_button "キャンセル"
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: false)
          end

          it "お買い物削除モーダルの外をクリックするとモーダルが閉じること", js: true do
            within("div.shopping-record-bg", text: unclosed_user_shopping_records[0].title) do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            # モーダルの外をクリック
            page.execute_script("document.querySelector('body').click();")

            expect(page).to have_selector("#turbo-confirm-modal", visible: false)
          end

          it "お買い物削除ボタンからお買い物が削除できること", js: true do
            within("div.shopping-record-bg", text: unclosed_user_shopping_records[0].title) do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            expect do
              within "#turbo-confirm-modal" do
                click_button "削除する"
              end

              within ".alert" do
                expect(page).to have_content "お買い物が削除されました。"
              end

              expect(current_path).to eq shopping_index_path
            end.to change { ShoppingRecord.count }.by(-1)

            # お買い物がDBに存在しないことを確認
            expect(ShoppingRecord.where(id: unclosed_user_shopping_records[0].id)).to_not exist
          end
        end

        context "未完了のお買い物が存在しない場合" do
          before do
            visit shopping_index_path
          end

          it "お買い物選択の項目が表示されないこと" do
            expect(page).to_not have_selector("h2", text: "お買い物選択")
          end

          it "お買い物が登録されていないメッセージが存在すること" do
            expect(page).to have_selector("h2", text: "お買い物は登録されていません")
          end
        end
      end
    end

    describe "edit" do
      let(:user) { create(:user) }
      let!(:master_user) { create(:user, :master_admin) }
      let(:category) { create(:category) }
      let!(:preset_item1) { create(:item, user: master_user, category: category) }
      let!(:preset_item2) { create(:item, user: master_user, category: category) }
      let(:user_shopping_record) { create(:shopping_record, user: user) }
      let!(:buy1) do
        create(:buy, user: user, shopping_record: user_shopping_record,
                     item_name: preset_item1.name, item_hiragana: preset_item1.hiragana)
      end
      let!(:buy2) do
        create(:buy, user: user, shopping_record: user_shopping_record,
                     item_name: preset_item2.name, item_hiragana: preset_item2.hiragana)
      end

      context "サインインしている場合" do
        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
          visit shopping_progress_path(user_shopping_record.hashid)
        end

        include_examples "ユーザー情報の表示テスト"

        # ナビゲーションのテスト用変数
        let(:navigation_content) { "お買い物を始めるよ！" }

        include_examples "ナビゲーションのテスト"

        it "ページタイトルが表示されること" do
          expect(page).to have_selector("h1", text: "お買い物モード")
        end

        it "お買い物リストが正しく表示されていること" do
          expect(page).to have_selector("h2", text: "#{user_shopping_record.title}買うものリスト")
        end

        it "お買い物に紐付く購入アイテム数がお買い物リストに表示されること" do
          expect(page).to have_selector("div.buy-item-space", count: user_shopping_record.buys.count)
          expect(page).to have_selector("div.buy-item-space", text: buy1.item_name)
          expect(page).to have_selector("div.buy-item-space", text: buy2.item_name)
        end

        it "お買い物リストのアイテムをチェックできること" do
          within("div.buy-item-space", text: buy1.item_name) do
            check buy1.item_name

            expect(find_field(buy1.item_name)).to be_checked
          end
        end

        it "お買い物完了のボタンが存在すること" do
          expect(page).to have_button("お買い物完了")
        end

        it "お買い物を中止するリンクが存在すること" do
          expect(page).to have_link("中止", href: shopping_index_path)
        end

        it "お買い物中止のリンクをクリックしてお買い物一覧画面に遷移すること" do
          click_link "中止"

          expect(page).to have_http_status(:success)
          expect(current_path).to eq shopping_index_path
        end

        # ヘルプモーダルの基本機能テスト用変数
        let(:page_title) { "お買い物モード" }

        include_examples "ヘルプモーダルの基本機能テスト"

        it "ヘルプモーダル内の主な項目が正しく表示されること" do
          within "#helpModal.modal" do
            expect(page).to have_selector("h3", text: "お買い物モードの進め方")
            expect(page).to have_selector("h5", text: "① お買い物リストのアイテムにチェックしながら買い物する")
            expect(page).to have_selector("h5", text: "② 買い物が終わったらお買い物完了のボタンを押す")
            expect(page).to have_selector("h3", text: "ボタンについて")
            expect(page).to have_selector("h4", text: "各ボタンの説明")
            expect(page).to have_selector("div.help-buy-item-space", text: "アイテム名")
            expect(page).to have_selector("h5", text: "アイテムボタン")
            expect(page).to have_selector("div.btn", text: "お買い物完了")
            expect(page).to have_selector("h5", text: "お買い物完了ボタン")
            expect(page).to have_selector("div.btn", text: "中止")
            expect(page).to have_selector("h5", text: "お買い物中止ボタン")
          end
        end
      end

      context "サインインしていない場合" do
        before do
          visit shopping_progress_path(user_shopping_record.hashid)
        end

        include_examples "非ログイン状態で認可が必要なページにアクセスした時のリダイレクトテスト"
      end

      describe "ひらがなモードの設定により異なる箇所のテスト" do
        context "ひらがなモードOFF（デフォルト）の場合" do
          before do
            expect(user.hiragana_view).to be_falsey
            sign_in_as(user)
            # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
            expect(page).to have_content "ログインしました。"
            visit shopping_progress_path(user_shopping_record.hashid)
          end

          it "お買い物リストのアイテムがアイテム名(item_name)で表示されること" do
            expect(page).to have_selector("div.buy-item-space", text: buy1.item_name)
            expect(page).to have_selector("div.buy-item-space", text: buy2.item_name)
          end

          it "お買い物リストのアイテムがひらがな（アイテム名）(item_hiragana)で表示されないこと" do
            expect(page).to_not have_selector("div.buy-item-space", text: buy1.item_hiragana)
            expect(page).to_not have_selector("div.buy-item-space", text: buy2.item_hiragana)
          end
        end

        context "ひらがなモードONの場合" do
          before do
            user.update(hiragana_view: true)
            sign_in_as(user)
            # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
            expect(page).to have_content "ログインしました。"
            visit shopping_progress_path(user_shopping_record.hashid)
          end

          it "お買い物リストのアイテムがひらがな（アイテム名）(item_hiragana)で表示されること" do
            expect(page).to have_selector("div.buy-item-space", text: buy1.item_hiragana)
            expect(page).to have_selector("div.buy-item-space", text: buy2.item_hiragana)
          end

          it "お買い物リストのアイテムがアイテム名(item_name)で表示されないこと" do
            expect(page).to_not have_selector("div.buy-item-space", text: buy1.item_name)
            expect(page).to_not have_selector("div.buy-item-space", text: buy2.item_name)
          end
        end
      end
    end

    describe "edit_confirm", js: true do
      let(:user) { create(:user) }
      let!(:master_user) { create(:user, :master_admin) }
      let(:category) { create(:category) }
      let!(:preset_item1) { create(:item, user: master_user, category: category) }
      let!(:preset_item2) { create(:item, user: master_user, category: category) }
      let(:user_shopping_record) { create(:shopping_record, user: user) }
      let!(:buy1) do
        create(:buy, user: user, shopping_record: user_shopping_record,
                     item_name: preset_item1.name, item_hiragana: preset_item1.hiragana)
      end
      let!(:buy2) do
        create(:buy, user: user, shopping_record: user_shopping_record,
                     item_name: preset_item2.name, item_hiragana: preset_item2.hiragana)
      end

      before do
        sign_in_as(user)
        # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
        expect(page).to have_content "ログインしました。"
        visit shopping_progress_path(user_shopping_record.hashid)
      end

      describe "共通項目のテスト" do
        before do
          click_button "お買い物完了"
        end

        include_examples "ユーザー情報の表示テスト"

        # ナビゲーションのテスト用変数
        let(:navigation_content) { "お買い物結果を確認するよ！" }

        include_examples "ナビゲーションのテスト"

        it "ページタイトルが表示されること" do
          expect(page).to have_selector("h1", text: "お買い物モード")
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

        it "お買い物hashidが入力されたhiddenフィールドが存在すること（お買い物更新用）" do
          hashid = user_shopping_record.hashid

          expect(find_field("confirm_shopping_record_form_shopping_record_hashid", type: "hidden").value).to eq hashid
        end

        it "お買い物hashidが入力されたhiddenフィールドが存在すること（もどるボタン用）" do
          hashid = user_shopping_record.hashid

          expect(find_field("back_shopping_record_form_shopping_record_hashid", type: "hidden").value).to eq hashid
        end

        it "OK!ボタンが存在すること" do
          expect(page).to have_button("OK!")
        end

        it "もどるボタンが存在すること" do
          expect(page).to have_button("もどる")
        end

        it "もどるボタンをクリックするとお買い物リストのページに遷移すること" do
          click_button("もどる")

          # postによるrender処理のためcurrent_pathではなく該当ページの要素で遷移を確認
          expect(page).to have_selector("h2", text: "#{user_shopping_record.title}\n買うものリスト")
          expect(page).to have_button("お買い物完了")
        end
      end

      describe "お買い物リストのアイテムのチェックにより異なる箇所のテスト" do
        context "買った（チェックした）アイテムと買わなかった（チェックしなかった）アイテムがある場合" do
          before do
            within("div.buy-item-space", text: buy1.item_name) do
              check buy1.item_name
              expect(find_field(buy1.item_name)).to be_checked
            end
            within("div.buy-item-space", text: buy2.item_name) do
              expect(find_field(buy2.item_name)).to_not be_checked
            end
            click_button "お買い物完了"
          end

          it "買ったアイテムの項目にチェックしたアイテムが表示されること" do
            within(".confirm-window", text: "買ったアイテム") do
              expect(page).to have_selector("li", text: buy1.item_name)
            end
          end

          it "買ったアイテムの項目にチェックしなかったアイテムが表示されないこと" do
            within(".confirm-window", text: "買ったアイテム") do
              expect(page).to_not have_selector("li", text: buy2.item_name)
            end
          end

          it "買わなかったアイテムの項目にチェックしなかったアイテムが表示されること" do
            within(".confirm-window", text: "買わなかったアイテム") do
              expect(page).to have_selector("li", text: buy2.item_name)
            end
          end

          it "買わなかったアイテムの項目にチェックしたアイテムが表示されないこと" do
            within(".confirm-window", text: "買わなかったアイテム") do
              expect(page).to_not have_selector("li", text: buy1.item_name)
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

          it "買ったアイテムに紐付く購入情報のhashidが入力されたhiddenフィールドが存在すること（OK!ボタン用）" do
            expect(find_field("confirm_shopping_record_form_hashids_#{buy1.hashid}", type: "hidden").value).to eq buy1.hashid
          end

          it "買わなかったアイテムに紐付く購入情報のhiddenフィールドが存在しないこと（OK!ボタン用）" do
            expect(page).to have_no_field("confirm_shopping_record_form_hashids_#{buy2.hashid}", type: "hidden")
          end

          it "買ったアイテムに紐付く購入情報のhashidが入力されたhiddenフィールドが存在すること（もどるボタン用）" do
            expect(find_field("back_shopping_record_form_hashids_#{buy1.hashid}", type: "hidden").value).to eq buy1.hashid
          end

          it "買わなかったアイテムに紐付く購入情報のhiddenフィールドが存在しないこと（もどるボタン用）" do
            expect(page).to have_no_field("confirm_shopping_record_form_hashids_#{buy2.hashid}", type: "hidden")
          end
        end

        context "買った（チェックした）アイテムがない場合" do
          before do
            click_button "お買い物完了"
          end

          it "買ったアイテムの項目に「購入アイテムなし」が表示されること" do
            within(".confirm-window", text: "買ったアイテム") do
              expect(page).to have_selector("h5", text: "購入アイテムなし")
            end
          end

          it "買わなかったアイテムに紐付く購入情報のhiddenフィールドが存在しないこと（OK!ボタン用）" do
            expect(page).to have_no_field("confirm_shopping_record_form_hashids_#{buy1.hashid}", type: "hidden")
            expect(page).to have_no_field("confirm_shopping_record_form_hashids_#{buy2.hashid}", type: "hidden")
          end

          it "買わなかったアイテムに紐付く購入情報のhiddenフィールドが存在しないこと（もどるボタン用）" do
            expect(page).to have_no_field("confirm_shopping_record_form_hashids_#{buy1.hashid}", type: "hidden")
            expect(page).to have_no_field("confirm_shopping_record_form_hashids_#{buy2.hashid}", type: "hidden")
          end
        end

        context "買わなかった（チェックしなかった）アイテムがない場合" do
          before do
            within("div.buy-item-space", text: buy1.item_name) do
              check buy1.item_name
            end
            within("div.buy-item-space", text: buy2.item_name) do
              check buy2.item_name
            end
            expect(page).to_not have_css("input[type='checkbox']:not(:checked)")
            click_button "お買い物完了"
          end

          it "買わなかったアイテムの項目に「未購入アイテムなし」が表示されること" do
            within(".confirm-window", text: "買わなかったアイテム") do
              expect(page).to have_selector("h5", text: "未購入アイテムなし")
            end
          end

          it "買ったアイテムに紐付く購入情報のhashidが入力されたhiddenフィールドが存在すること（OK!ボタン用）" do
            expect(find_field("confirm_shopping_record_form_hashids_#{buy1.hashid}", type: "hidden").value).to eq buy1.hashid
            expect(find_field("confirm_shopping_record_form_hashids_#{buy2.hashid}", type: "hidden").value).to eq buy2.hashid
          end

          it "買ったアイテムに紐付く購入情報のhashidが入力されたhiddenフィールドが存在すること（もどるボタン用）" do
            expect(find_field("back_shopping_record_form_hashids_#{buy1.hashid}", type: "hidden").value).to eq buy1.hashid
            expect(find_field("back_shopping_record_form_hashids_#{buy2.hashid}", type: "hidden").value).to eq buy2.hashid
          end
        end
      end

      describe "ひらがなモードの設定により異なる箇所のテスト" do
        context "ひらがなモードOFF（デフォルト）の場合" do
          before do
            expect(user.hiragana_view).to be_falsey
            within("div.buy-item-space", text: buy1.item_name) do
              check buy1.item_name
              expect(find_field(buy1.item_name)).to be_checked
            end
            within("div.buy-item-space", text: buy2.item_name) do
              expect(find_field(buy2.item_name)).to_not be_checked
            end
            click_button "お買い物完了"
          end

          it "買ったアイテムと買わなかったアイテムがアイテム名(item_name)で表示されること" do
            within(".confirm-window", text: "買ったアイテム") do
              expect(page).to have_selector("li", text: buy1.item_name)
            end

            within(".confirm-window", text: "買わなかったアイテム") do
              expect(page).to have_selector("li", text: buy2.item_name)
            end
          end

          it "買ったアイテムと買わなかったアイテムがひらがな（アイテム名）(item_hiragana)で表示されないこと" do
            within(".confirm-window", text: "買ったアイテム") do
              expect(page).to_not have_selector("li", text: buy1.item_hiragana)
            end

            within(".confirm-window", text: "買わなかったアイテム") do
              expect(page).to_not have_selector("li", text: buy2.item_hiragana)
            end
          end
        end

        context "ひらがなモードONの場合" do
          before do
            within("div.buy-item-space", text: buy1.item_name) do
              check buy1.item_name
              expect(find_field(buy1.item_name)).to be_checked
            end
            within("div.buy-item-space", text: buy2.item_name) do
              expect(find_field(buy2.item_name)).to_not be_checked
            end
            user.update(hiragana_view: true)
            click_button "お買い物完了"
          end

          it "買ったアイテムと買わなかったアイテムがひらがな（アイテム名）(item_hiragana)で表示されること" do
            within(".confirm-window", text: "買ったアイテム") do
              expect(page).to have_selector("li", text: buy1.item_hiragana)
            end

            within(".confirm-window", text: "買わなかったアイテム") do
              expect(page).to have_selector("li", text: buy2.item_hiragana)
            end
          end

          it "買ったアイテムと買わなかったアイテムがアイテム名(item_name)で表示されないこと" do
            within(".confirm-window", text: "買ったアイテム") do
              expect(page).to_not have_selector("li", text: buy1.item_name)
            end

            within(".confirm-window", text: "買わなかったアイテム") do
              expect(page).to_not have_selector("li", text: buy2.item_name)
            end
          end
        end
      end
    end

    describe "choose", js: true do
      let(:user) { create(:user) }
      let!(:master_user) { create(:user, :master_admin) }
      let(:category) { create(:category) }
      let!(:preset_item) { create(:item, user: master_user, category: category) }
      let(:user_shopping_record) { create(:shopping_record, user: user) }
      let!(:buy) do
        create(:buy, user: user, shopping_record: user_shopping_record,
                     item_name: preset_item.name, item_hiragana: preset_item.hiragana)
      end

      before do
        sign_in_as(user)
        # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
        expect(page).to have_content "ログインしました。"
        visit shopping_progress_path(user_shopping_record.hashid)
        # アイテムをチェックせずお買い物内容確認画面へ
        click_button "お買い物完了"
        # お買い物を完了させお買い物場所保存選択画面へ
        click_button "OK!"
        expect(page).to have_content "お買い物が完了しました。"
      end

      # この時点のrequest.pathは/shopping_records/:hashidであり
      # shared_examplesの"ユーザー情報の表示テスト"では期待した結果にならないため
      # ここでは別途ユーザー情報のテストを用意する
      it "状態を示すユーザー情報が表示されていること" do
        within ".position-user-info" do
          expect(page).to have_selector("h6", text: "#{user.name} さん　ログイン中！")
        end
      end

      # ナビゲーションのテスト用変数
      let(:navigation_content) { "おつかれさま！お買い物が完了したよ。" }

      include_examples "ナビゲーションのテスト"

      it "ページタイトルが表示されること" do
        expect(page).to have_selector("h1", text: "お買い物モード")
      end

      it "お買物場所の記録の項目が表示されること" do
        expect(page).to have_selector("h2", text: "お買い物場所の記録")
      end

      it "お買物場所の登録画面へ遷移するリンクが存在すること" do
        expect(page).to have_link("する", href: new_shopping_location_path(user_shopping_record.hashid))
      end

      it "お買物場所の登録画面へのリンクをクリックしてお買物場所の登録画面へ遷移すること" do
        click_link "する"

        expect(page).to have_selector("h1", text: "お買い物場所の記録")
        expect(current_path).to eq new_shopping_location_path(user_shopping_record.hashid)
      end

      it "メインメニューへ遷移するリンクが存在すること" do
        expect(page).to have_link("しない", href: root_path)
      end

      it "メインメニュー(root)へのリンクをクリックしてrootページへ遷移すること" do
        click_link "しない"

        expect(page).to have_selector("h1", text: "メインメニュー")
        expect(current_path).to eq root_path
      end
    end
  end

  describe "お買い物モードのフロー" do
    let(:user) { create(:user) }
    let!(:master_user) { create(:user, :master_admin) }
    let(:category) { create(:category) }
    let!(:item1) { create(:item, user: master_user, category: category) }
    let!(:item2) { create(:item, user: master_user, category: category) }
    let(:shopping_record) { create(:shopping_record, user: user) }
    let!(:shopping_record_buy1) do
      create(:buy, user: user, shopping_record: shopping_record,
                   item_name: item1.name, item_hiragana: item1.hiragana)
    end
    let!(:shopping_record_buy2) do
      create(:buy, user: user, shopping_record: shopping_record,
                   item_name: item2.name, item_hiragana: item2.hiragana)
    end

    before do
      sign_in_as(user)
      # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
      expect(page).to have_content "ログインしました。"
    end

    context "正常系", js: true do
      before do
        # お買い物一覧画面からお買い物を選択してお買い物モード画面へ遷移する
        visit shopping_index_path

        within("div.shopping-record-bg", text: shopping_record.title) do
          click_link(href: shopping_progress_path(shopping_record.hashid))
        end

        expect(page).to have_selector("h2", text: "#{shopping_record.title}\n買うものリスト")
      end

      scenario "ユーザーがアイテムを全てチェックして未完了のお買い物を完了させる" do
        check shopping_record_buy1.item_name
        check shopping_record_buy2.item_name
        click_button "お買い物完了"

        within ".confirm-window-text" do
          expect(page).to have_selector("h2", text: "お買い物結果")
        end
        within(".confirm-window", text: "買ったアイテム") do
          expect(page).to have_selector("li", text: shopping_record_buy1.item_name)
          expect(page).to have_selector("li", text: shopping_record_buy2.item_name)
        end
        within(".confirm-window", text: "買わなかったアイテム") do
          expect(page).to have_selector("h5", text: "未購入アイテムなし")
          expect(page).to_not have_selector("li")
        end

        # お買い物の完了と紐付く購入記録の購入状態の更新を確認
        expect do
          click_button "OK!"
          expect(page).to have_content "お買い物が完了しました。"
        end.to change { shopping_record.reload.closed }.from(false).to(true).
          and change { shopping_record_buy1.reload.purchased }.from(false).to(true).
          and change { shopping_record_buy2.reload.purchased }.from(false).to(true)
      end

      scenario "ユーザーがアイテムを一部チェックして未完了のお買い物を完了させる" do
        check shopping_record_buy1.item_name
        click_button "お買い物完了"

        within ".confirm-window-text" do
          expect(page).to have_selector("h2", text: "お買い物結果")
        end
        within(".confirm-window", text: "買ったアイテム") do
          expect(page).to have_selector("li", text: shopping_record_buy1.item_name)
        end
        within(".confirm-window", text: "買わなかったアイテム") do
          expect(page).to have_selector("li", text: shopping_record_buy2.item_name)
        end

        # お買い物の完了と紐付く購入記録の購入状態の更新を確認
        expect do
          click_button "OK!"
          expect(page).to have_content "お買い物が完了しました。"
        end.to change { shopping_record.reload.closed }.from(false).to(true).
          and change { shopping_record_buy1.reload.purchased }.from(false).to(true)
        expect(shopping_record_buy2.reload.purchased).to be_falsey
      end

      scenario "ユーザーがアイテムをチェックせずに未完了のお買い物を完了させる" do
        click_button "お買い物完了"

        within ".confirm-window-text" do
          expect(page).to have_selector("h2", text: "お買い物結果")
        end
        within(".confirm-window", text: "買ったアイテム") do
          expect(page).to have_selector("h5", text: "購入アイテムなし")
        end
        within(".confirm-window", text: "買わなかったアイテム") do
          expect(page).to have_selector("li", text: shopping_record_buy1.item_name)
          expect(page).to have_selector("li", text: shopping_record_buy2.item_name)
        end

        # お買い物の完了と紐付く購入記録の購入状態が更新されないことを確認
        expect do
          click_button "OK!"
          expect(page).to have_content "お買い物が完了しました。"
        end.to change { shopping_record.reload.closed }.from(false).to(true)
        expect(shopping_record_buy1.reload.purchased).to be_falsey
        expect(shopping_record_buy2.reload.purchased).to be_falsey
      end
    end

    context "異常系" do
      let(:closed_shopping_record) { create(:shopping_record, :closed, user: user) }
      let!(:closed_shopping_record_buy) do
        create(:buy, user: user, shopping_record: closed_shopping_record,
                     item_name: item1.name, item_hiragana: item1.hiragana)
      end
      let(:other_user) { create(:user) }
      let(:other_user_shopping_record) { create(:shopping_record, user: other_user) }
      let!(:other_user_shopping_record_buy) do
        create(:buy, user: other_user, shopping_record: other_user_shopping_record,
                     item_name: item1.name, item_hiragana: item1.hiragana)
      end

      scenario "完了状態のお買い物のhashidでお買い物モードへのアクセスを試みる" do
        visit shopping_progress_path(closed_shopping_record.hashid)

        within ".alert" do
          expect(page).to have_content "指定されたお買い物は終了しています。"
        end
        expect(current_path).to eq shopping_index_path
      end

      scenario "他のユーザーのお買い物のhashidでお買い物モードへのアクセスを試みる" do
        visit shopping_progress_path(other_user_shopping_record.hashid)

        within ".alert" do
          expect(page).to have_content "指定されたお買い物は存在しません。"
        end
        expect(current_path).to eq shopping_index_path
      end

      scenario "不正なhashidでお買い物モードへのアクセスを試みる" do
        visit shopping_progress_path("invalid_hashid")

        within ".alert" do
          expect(page).to have_content "指定されたお買い物は存在しません。"
        end
        expect(current_path).to eq shopping_index_path
      end
    end

    describe "お買い物結果のメール通知のテスト", js: true do
      # 非同期のメール送信を即時実行するために必要
      include ActiveJob::TestHelper

      let!(:confirmed_notification_target_user) { create(:notification_target_user, user: user) }
      let!(:unconfirmed_notification_target_user) { create(:notification_target_user, :unconfirmed, user: user) }
      let(:one_send_mail) { 1 }

      before do
        # お買い物完了手前まで処理
        visit shopping_index_path

        within("div.shopping-record-bg", text: shopping_record.title) do
          click_link(href: shopping_progress_path(shopping_record.hashid))
        end

        expect(page).to have_selector("h2", text: "#{shopping_record.title}\n買うものリスト")
        check shopping_record_buy1.item_name
        click_button "お買い物完了"

        within ".confirm-window-text" do
          expect(page).to have_selector("h2", text: "お買い物結果")
        end
      end

      it "アクティベート済みの通知対象ユーザーに通知メールが送信されること" do
        # 非同期のメール送信を即時実行する
        perform_enqueued_jobs do
          click_button "OK!"
          expect(page).to have_content "お買い物が完了しました。"
        end

        # 通知メール送信回数の確認
        expect(ActionMailer::Base.deliveries.count).to eq one_send_mail

        # 通知メールの内容確認
        mail = ActionMailer::Base.deliveries.last
        expect(mail.to).to include confirmed_notification_target_user.email
        expect(mail.subject).to eq "【お知らせ】#{user.name}さんがお買い物しました！"
        expect(mail.body.encoded).to include confirmed_notification_target_user.name
        expect(mail.body.encoded).to include confirmed_notification_target_user.email
        expect(mail.body.encoded).to include user.name
        expect(mail.body.encoded).to include shopping_record_buy1.item_name, shopping_record_buy2.item_name
      end
    end
  end

  describe "お買い物削除のフロー" do
    let(:user) { create(:user) }
    let!(:master_user) { create(:user, :master_admin) }
    let(:category) { create(:category) }
    let!(:item) { create(:item, user: master_user, category: category) }
    let(:shopping_record) { create(:shopping_record, user: user) }
    let!(:shopping_record_buy) do
      create(:buy, user: user, shopping_record: shopping_record,
                   item_name: item.name, item_hiragana: item.hiragana)
    end

    before do
      sign_in_as(user)
      # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
      expect(page).to have_content "ログインしました。"
      visit shopping_index_path
    end

    scenario "ユーザーがお買い物を削除する", js: true do
      expect(page).to have_selector("h2", text: "お買い物選択")
      expect(page).to have_selector("h4", text: shopping_record.title)

      within("div.shopping-record-bg", text: shopping_record.title) do
        find("i.delete-icon").click
      end

      expect do
        within "#turbo-confirm-modal" do
          click_button "削除する"
        end

        within ".alert" do
          expect(page).to have_content "お買い物が削除されました。"
        end

        expect(current_path).to eq shopping_index_path
      end.to change { ShoppingRecord.count }.by(-1)

      # お買い物がDBに存在しないことを確認
      expect(ShoppingRecord.where(id: shopping_record.id)).to_not exist
    end
  end
end
