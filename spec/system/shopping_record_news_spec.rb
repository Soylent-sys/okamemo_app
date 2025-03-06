require 'rails_helper'

# お買い物登録機能関連のテスト
RSpec.describe "ShoppingRecordNews", type: :system do
  describe "ビューの要素" do
    describe "new" do
      context "サインインしている場合" do
        let(:user) { create(:user) }
        let!(:master_user) { create(:user, :master_admin) }
        let(:category1) { create(:category, id: 1) }
        let(:category2) { create(:category, id: 2) }
        let(:category3) { create(:category, id: 3) }
        let!(:no_item_category) { create(:category, id: 4) }
        let!(:c1_preset_item1) { create(:item, user: master_user, category: category1) }
        let!(:c1_preset_item2) { create(:item, user: master_user, category: category1) }
        let!(:c1_preset_item3) { create(:item, user: master_user, category: category1) }
        let!(:c1_preset_item4) { create(:item, user: master_user, category: category1) }
        let!(:c1_preset_item5) { create(:item, user: master_user, category: category1) }
        let!(:c1_user_item) { create(:item, user: user, category: category1) }
        let!(:c2_user_item) { create(:item, user: user, category: category2) }
        let!(:c3_preset_items) { create_list(:item, 20, user: master_user, category: category3) }
        let(:other_user) { create(:user) }
        let!(:other_user_item) { create(:item, user: other_user, category: category1) }
        # 最終購入日の表示形式の区切りとなる購入履歴を追加
        let!(:time_current) { Time.current }
        let(:user_shopping_records) { create_list(:shopping_record, 6, :closed, user: user) }
        let!(:buy_today) do
          create(
            :buy, :purchased,
            user: user, shopping_record: user_shopping_records[0],
            item_name: c1_preset_item1.name, item_hiragana: c1_preset_item1.hiragana,
            created_at: time_current - 1.month, updated_at: time_current
          )
        end
        let!(:buy_yesterday) do
          create(
            :buy, :purchased,
            user: user, shopping_record: user_shopping_records[1],
            item_name: c1_preset_item2.name, item_hiragana: c1_preset_item2.hiragana,
            created_at: time_current - 1.month, updated_at: time_current - 1.day
          )
        end
        let!(:buy_day_before_yesterday) do
          create(
            :buy, :purchased,
            user: user, shopping_record: user_shopping_records[2],
            item_name: c1_preset_item3.name, item_hiragana: c1_preset_item3.hiragana,
            created_at: time_current - 1.month, updated_at: time_current - 2.day
          )
        end
        let!(:buy_six_days_ago) do
          create(
            :buy, :purchased,
            user: user, shopping_record: user_shopping_records[3],
            item_name: c1_preset_item4.name, item_hiragana: c1_preset_item4.hiragana,
            created_at: time_current - 1.month, updated_at: time_current - 6.day
          )
        end
        let!(:buy_seven_days_ago) do
          create(
            :buy, :purchased,
            user: user, shopping_record: user_shopping_records[4],
            item_name: c1_preset_item5.name, item_hiragana: c1_preset_item5.hiragana,
            created_at: time_current - 1.month, updated_at: time_current - 7.day
          )
        end
        # buy_todayと同じアイテムのより古い購入履歴を追加
        let!(:buy_same_item) do
          create(
            :buy, :purchased,
            user: user, shopping_record: user_shopping_records[5],
            item_name: c1_preset_item1.name, item_hiragana: c1_preset_item1.hiragana,
            created_at: time_current - 1.month, updated_at: time_current - 1.day
          )
        end
        # YAMLファイルからヘルプモーダルのカテゴリー説明内容を読み込む
        let(:categories_help) { YAML.safe_load_file(Rails.root.join("spec/fixtures/categories_help.yml")) }

        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
          visit shopping_new_path
        end

        include_examples "ユーザー情報の表示テスト"

        # ナビゲーションのテスト用変数
        let(:navigation_content) { "ここは買い物登録する画面だよ！" }

        include_examples "ナビゲーションのテスト"

        it "ページタイトルが表示されること" do
          expect(page).to have_selector("h1", text: "お買い物の登録")
        end

        it "メインメニューに戻るリンクが存在すること" do
          expect(page).to have_link("メインメニュー にもどる", href: root_path)
        end

        it "メインメニューに戻るリンクをクリックしてrootページに遷移すること" do
          click_link "メインメニュー にもどる"

          expect(page).to have_http_status(:success)
          expect(current_path).to eq root_path
        end

        it "タイトルを入力するフォームが存在すること" do
          expect(page).to have_selector("h3", text: "タイトルを入力")
          expect(page).to have_field("タイトル")
        end

        it "タイトルフィールドに初期値が入力されていること" do
          expect(page).to have_field("タイトル", with: "#{Date.today.to_fs(:date_ja)}のお買い物")
        end

        it "アイテムチェックフォームのタイトルが存在すること" do
          expect(page).to have_selector("h3", text: "買うものにチェック")
        end

        it "カテゴリーの項目が表示されること" do
          expect(page).to have_selector("h4", text: "カテゴリー")
        end

        it "アイテムの項目が表示されること" do
          expect(page).to have_selector("h4", text: "アイテム")
        end

        it "カテゴリー項目に全てのカテゴリーが表示されること" do
          expect(page).to have_button(category1.name)
          expect(page).to have_button(category2.name)
          expect(page).to have_button(category3.name)
          expect(page).to have_button(no_item_category.name)
        end

        it "初期状態では表示カテゴリーの中で一番若いidのカテゴリーが選択されていること" do
          expect(page).to have_selector("button.active", text: category1.name)
          expect(page).to_not have_selector("button.active", text: category2.name)
          expect(page).to_not have_selector("button.active", text: category3.name)
          expect(page).to_not have_selector("button.active", text: no_item_category.name)
        end

        it "選択しているカテゴリーのデフォルトアイテムを含むアイテムが表示されること", js: true do
          # 初期状態で選択されているカテゴリーとそのカテゴリーに属するアイテムの表示を確認
          expect(page).to have_selector("button.active", text: category1.name)
          expect(page).to have_selector(".item-name-space-shopping", text: c1_preset_item1.name, visible: true)
          expect(page).to have_selector(".item-name-space-shopping", text: c1_preset_item2.name, visible: true)
          expect(page).to have_selector(".item-name-space-shopping", text: c1_preset_item3.name, visible: true)
          expect(page).to have_selector(".item-name-space-shopping", text: c1_preset_item4.name, visible: true)
          expect(page).to have_selector(".item-name-space-shopping", text: c1_preset_item5.name, visible: true)
          expect(page).to have_selector(".item-name-space-shopping", text: c1_user_item.name, visible: true)

          click_button category2.name

          expect(page).to have_selector("button.active", text: category2.name)
          expect(c2_user_item.category).to eq category2
          expect(page).to have_selector(".item-name-space-shopping", text: c2_user_item.name, visible: true)
        end

        it "選択しているカテゴリーで別のユーザーが登録したアイテムが表示されないこと", js: true do
          expect(page).to have_selector("button.active", text: category1.name)

          expect(other_user_item.category).to eq category1
          expect(page).to_not have_selector(".item-name-space-shopping", text: other_user_item.name)
        end

        it "選択していないカテゴリーのアイテムが表示されないこと", js: true do
          click_button category2.name
          expect(page).to have_selector("button.active", text: category2.name)

          # category1のアイテムの非表示を確認
          expect(page).to have_selector(".item-name-space-shopping", text: c1_preset_item1.name, visible: false)
          expect(page).to have_selector(".item-name-space-shopping", text: c1_preset_item2.name, visible: false)
          expect(page).to have_selector(".item-name-space-shopping", text: c1_preset_item3.name, visible: false)
          expect(page).to have_selector(".item-name-space-shopping", text: c1_preset_item4.name, visible: false)
          expect(page).to have_selector(".item-name-space-shopping", text: c1_preset_item5.name, visible: false)
          expect(page).to have_selector(".item-name-space-shopping", text: c1_user_item.name, visible: false)
        end

        it "選択しているカテゴリーに登録アイテムが無ければアイテムが表示されないこと", js: true do
          click_button no_item_category.name
          expect(page).to have_selector("button.active", text: no_item_category.name)

          expect(page).to_not have_selector(".item-name-space-shopping")
        end

        it "購入履歴の無いアイテムに「購入記録なし」の表示があること" do
          expect(user.buys.purchased.where(item_name: c1_user_item.name)).to_not exist

          expect(page).to have_selector("button.active", text: category1.name)

          within("div.item-space", text: c1_user_item.name) do
            expect(page).to have_content "購入記録なし"
          end
        end

        it "本日中に購入履歴があるアイテムに「今日購入してます」の表示があること" do
          expect(user.buys.purchased.where(item_name: c1_preset_item1.name)).to exist

          expect(page).to have_selector("button.active", text: category1.name)

          within("div.item-space", text: c1_preset_item1.name) do
            expect(page).to have_content "今日購入してます"
          end
        end

        it "1日前に購入履歴があるアイテムに「昨日購入してます」の表示があること" do
          expect(user.buys.purchased.where(item_name: c1_preset_item2.name)).to exist

          expect(page).to have_selector("button.active", text: category1.name)

          within("div.item-space", text: c1_preset_item2.name) do
            expect(page).to have_content "昨日購入してます"
          end
        end

        it "2日前に購入履歴があるアイテムに「2日前に購入」の表示があること" do
          expect(user.buys.purchased.where(item_name: c1_preset_item3.name)).to exist

          expect(page).to have_selector("button.active", text: category1.name)

          within("div.item-space", text: c1_preset_item3.name) do
            expect(page).to have_content "2日前に購入"
          end
        end

        it "6日前に購入履歴があるアイテムに「6日前に購入」の表示があること" do
          expect(user.buys.purchased.where(item_name: c1_preset_item4.name)).to exist

          expect(page).to have_selector("button.active", text: category1.name)

          within("div.item-space", text: c1_preset_item4.name) do
            expect(page).to have_content "6日前に購入"
          end
        end

        it "7日以上前に購入履歴があるアイテムに購入した年月日の表示があること" do
          expect(user.buys.purchased.where(item_name: c1_preset_item5.name)).to exist

          expect(page).to have_selector("button.active", text: category1.name)

          within("div.item-space", text: c1_preset_item5.name) do
            expect(page).to have_content "#{buy_seven_days_ago.updated_at.to_fs(:date_ymd)} 購入"
          end
        end

        let(:two_records) { 2 }

        it "同じアイテムの購入履歴が複数存在するときは最新の購入日がアイテムに表示されること" do
          # ユーザーの同アイテムの購入履歴が複数存在することを確認
          expect(user.buys.purchased.where(item_name: c1_preset_item1.name).count).to eq two_records
          expect(buy_today.item_name).to eq buy_same_item.item_name
          # 最新の購入履歴を確認
          expect(buy_today.updated_at).to be > buy_same_item.updated_at

          expect(page).to have_selector("button.active", text: category1.name)

          within("div.item-space", text: c1_preset_item1.name) do
            expect(page).to have_content "今日購入してます"
          end
        end

        it "登録内容の確認ボタンが存在すること" do
          expect(page).to have_button("登録内容の確認")
        end

        it "リセットボタンが存在すること" do
          expect(page).to have_button("リセット")
        end

        it "表示されているアイテムをチェックできること" do
          expect(page).to have_selector("button.active", text: category1.name)
          expect(page).to have_selector(".item-name-space-shopping", text: c1_preset_item1.name, visible: true)

          within("div.item-space", text: c1_preset_item1.name) do
            check c1_preset_item1.name

            expect(find_field(c1_preset_item1.name)).to be_checked
          end
        end

        it "アイテムをチェックするとアイテムのチェック数を示すポップアップが表示されること", js: true do
          expect(page).to have_selector("button.active", text: category1.name)
          expect(page).to have_selector(".item-name-space-shopping", text: c1_preset_item1.name, visible: true)
          expect(page).to have_selector(".item-name-space-shopping", text: c1_preset_item2.name, visible: true)

          within("div.item-space", text: c1_preset_item1.name) do
            check c1_preset_item1.name
            expect(find_field(c1_preset_item1.name)).to be_checked
          end

          expect(page).to have_selector("#check-count-box", text: "チェック数 1", visible: true)

          within("div.item-space", text: c1_preset_item2.name) do
            check c1_preset_item2.name
            expect(find_field(c1_preset_item2.name)).to be_checked
          end

          expect(page).to have_selector("#check-count-box", text: "チェック数 2", visible: true)
        end

        it "初期状態ではアイテムのチェック数を示すポップアップが表示されないこと" do
          expect(page).to_not have_css("input[type='checkbox'][checked]")
          expect(page).to have_selector("#check-count-box", visible: false)
        end

        it "アイテムがチェックされていないときはアイテムのチェック数を示すポップアップが表示されないこと", js: true do
          expect(page).to have_selector("button.active", text: category1.name)
          expect(page).to have_selector(".item-name-space-shopping", text: c1_preset_item1.name, visible: true)

          # アイテムがチェックされていないこと＆ポップアップが表示されていないことを確認
          expect(page).to_not have_css("input[type='checkbox'][checked]")
          expect(page).to have_selector("#check-count-box", visible: false)

          # ポップアップを表示させる
          within("div.item-space", text: c1_preset_item1.name) do
            check c1_preset_item1.name
            expect(find_field(c1_preset_item1.name)).to be_checked
          end

          expect(page).to have_selector("#check-count-box", text: "チェック数 1", visible: true)

          # チェックを外してポップアップを消す
          within("div.item-space", text: c1_preset_item1.name) do
            uncheck c1_preset_item1.name
            expect(find_field(c1_preset_item1.name)).to_not be_checked
          end

          expect(page).to have_selector("#check-count-box", visible: false)
        end

        it "アイテムチェック数が20個を超えたときはポップアップの背景色のcssが変わること", js: true do
          expect(page).to have_selector("button.active", text: category1.name)
          expect(page).to have_selector(".item-name-space-shopping", text: c1_preset_item1.name, visible: true)

          within("div.item-space", text: c1_preset_item1.name) do
            check c1_preset_item1.name
            expect(find_field(c1_preset_item1.name)).to be_checked
          end

          # ポップアップに適用されているcssと非適用状態のcssを確認
          expect(page).to have_selector("#check-count-box.check-count-bg-color", text: "チェック数 1", visible: true)
          expect(page).to_not have_selector("#check-count-box.check-count-over-bg-color")

          # 20個のアイテムを持つカテゴリーに切り替える
          click_button category3.name

          # カテゴリーの全てのアイテムをチェックする
          c3_preset_items.each do |item|
            within("div.item-space", text: item.name) do
              check item.name
              expect(find_field(item.name)).to be_checked
            end
          end

          # ポップアップに適用されているcssの変更を確認
          expect(page).to_not have_selector("#check-count-box.check-count-bg-color")
          expect(page).to have_selector("#check-count-box.check-count-over-bg-color", text: "チェック数 21", visible: true)
        end

        it "リセットボタンをクリックするとアイテムのチェックが全て解除されること", js: true do
          # category1のアイテムをチェックする
          expect(page).to have_selector("button.active", text: category1.name)

          within("div.item-space", text: c1_preset_item1.name) do
            check c1_preset_item1.name
            expect(find_field(c1_preset_item1.name)).to be_checked
          end

          # category2のアイテムをチェックする
          click_button category2.name
          expect(page).to have_selector("button.active", text: category2.name)

          within("div.item-space", text: c2_user_item.name) do
            check c2_user_item.name
            expect(find_field(c2_user_item.name)).to be_checked
          end

          # category3のアイテムをチェックする
          click_button category3.name
          expect(page).to have_selector("button.active", text: category3.name)

          within("div.item-space", text: c3_preset_items[0].name) do
            check c3_preset_items[0].name
            expect(find_field(c3_preset_items[0].name)).to be_checked
          end

          click_button "リセット"

          # アイテムのチェックが全て解除されていることを確認
          expect(page).to_not have_css("input[type='checkbox'][checked]")
        end

        # ヘルプモーダルの基本機能テスト用変数
        let(:page_title) { "お買い物の登録" }

        include_examples "ヘルプモーダルの基本機能テスト"

        it "ヘルプモーダル内の主な項目が正しく表示されること" do
          within "#helpModal.modal" do
            expect(page).to have_selector("h3", text: "お買い物登録の仕方")
            expect(page).to have_selector("h5", text: "① タイトルの入力")
            expect(page).to have_selector("h5", text: "② 買うものにチェック")
            expect(page).to have_selector("h5", text: "③ 登録内容の確認ボタンを押す")
            expect(page).to have_selector("h3", text: "ボタン・カテゴリーについて")
            expect(page).to have_selector("h4", text: "各ボタンの説明")
            expect(page).to have_selector(".item-name-space-shopping", text: "アイテム名")
            expect(page).to have_selector("i.fa-tag")
            expect(page).to have_selector("div.h6", text: "購入記録なし")
            expect(page).to have_selector("h5", text: "各アイテムボタン")
            expect(page).to have_selector("div.btn", text: "登録内容の確認")
            expect(page).to have_selector("h5", text: "登録内容の確認ボタン")
            expect(page).to have_selector("div.btn", text: "リセット")
            expect(page).to have_selector("h5", text: "リセットボタン")
            expect(page).to have_selector("h4", text: "各カテゴリーの説明")
            # 各カテゴリーの説明分の確認
            categories_help.each do |help|
              expect(page).to have_selector("h5", text: help["name"])
              expect(page).to have_content(help["description"])
            end
          end
        end
      end

      context "サインインしていない場合" do
        before do
          visit shopping_new_path
        end

        include_examples "非ログイン状態で認可が必要なページにアクセスした時のリダイレクトテスト"
      end

      describe "ユーザー区分で異なる箇所のテスト" do
        context "ゲストユーザーの場合" do
          let(:user) { User.guest }

          before do
            sign_in_as(user)
            # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
            expect(page).to have_content "ログインしました。"
            visit shopping_new_path
          end

          it "ヘルプモーダル内にゲストユーザーのお買い物登録数の制限に関するテキストが存在すること" do
            within "#helpModal.modal" do
              expect(page).to have_selector("h3", text: "ゲストユーザーのお買い物の最大登録数")
              expect(page).to have_content(
                "ゲストユーザーで登録できるお買い物の数はお買い物履歴を含めて" \
                "最大#{ShoppingRecordForm::GUEST_SHOPPING_MAXIMUM_COUNT}件です。"
              )
            end
          end
        end

        context "ゲストユーザー以外の場合" do
          let(:user) { create(:user) }

          before do
            sign_in_as(user)
            # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
            expect(page).to have_content "ログインしました。"
            visit shopping_new_path
          end

          it "ヘルプモーダル内にゲストユーザーのお買い物登録数の制限に関するテキストが存在しないこと" do
            within "#helpModal.modal" do
              expect(page).to_not have_selector("h3", text: "ゲストユーザーのお買い物の最大登録数")
              expect(page).to_not have_content(
                "ゲストユーザーで登録できるお買い物の数はお買い物履歴を含めて" \
                "最大#{ShoppingRecordForm::GUEST_SHOPPING_MAXIMUM_COUNT}件です。"
              )
            end
          end
        end
      end

      describe "ひらがなモードの設定により異なる箇所のテスト" do
        let(:user) { create(:user) }
        let!(:master_user) { create(:user, :master_admin) }
        let(:category1) { create(:category) }
        let!(:c1_preset_item1) { create(:item, user: master_user, category: category1) }

        context "ひらがなモードOFF（デフォルト）の場合" do
          before do
            expect(user.hiragana_view).to be_falsey
            sign_in_as(user)
            # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
            expect(page).to have_content "ログインしました。"
            visit shopping_new_path
          end

          it "カテゴリー項目内でカテゴリー名（category.name）が表示されること" do
            expect(page).to have_selector("button", text: category1.name)
          end

          it "カテゴリー項目内でひらがな（カテゴリー名）(category.hiragana)が表示されないこと" do
            expect(page).to_not have_selector("button", text: category1.hiragana)
          end

          it "アイテム項目内でアイテム名(item.name)が表示されること" do
            expect(page).to have_selector("div.item-space", text: c1_preset_item1.name)
          end

          it "アイテム項目内でひらがな（アイテム名）(item.hiragana)が表示されないこと" do
            expect(page).to_not have_selector("div.item-space", text: c1_preset_item1.hiragana)
          end
        end

        context "ひらがなモードONの場合" do
          before do
            user.update(hiragana_view: true)
            sign_in_as(user)
            # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
            expect(page).to have_content "ログインしました。"
            visit shopping_new_path
          end

          it "カテゴリー項目内でひらがな（カテゴリー名）(category.hiragana)が表示されること" do
            expect(page).to have_selector("button", text: category1.hiragana)
          end

          it "カテゴリー項目内でカテゴリー名（category.name）が表示されないこと" do
            expect(page).to_not have_selector("button", text: category1.name)
          end

          it "アイテム項目内でひらがな（アイテム名）(item.hiragana)が表示されること" do
            expect(page).to have_selector("div.item-space", text: c1_preset_item1.hiragana)
          end

          it "アイテム項目内でアイテム名(item.name)が表示されないこと" do
            expect(page).to_not have_selector("div.item-space", text: c1_preset_item1.name)
          end
        end
      end
    end

    describe "confirm", js: true do
      let(:user) { create(:user) }
      let!(:master_user) { create(:user, :master_admin) }
      let(:category1) { create(:category, id: 1) }
      let(:category2) { create(:category, id: 2) }
      let!(:c1_preset_item1) { create(:item, user: master_user, category: category1) }
      let!(:c1_preset_item2) { create(:item, user: master_user, category: category1) }
      let!(:c2_preset_item) { create(:item, user: master_user, category: category2) }
      # お買い物タイトルのデフォルトの入力値
      let(:default_title) { "#{Date.today.to_fs(:date_ja)}のお買い物" }

      before do
        sign_in_as(user)
        # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
        expect(page).to have_content "ログインしました。"
        visit shopping_new_path

        # タイトルフィールドにデフォルトタイトルが入力されていることを確認
        expect(page).to have_field("タイトル", with: default_title)

        # category1のアイテムをチェックする
        within("div.item-space", text: c1_preset_item1.name) do
          check c1_preset_item1.name
        end

        # category2のアイテムをチェックする
        click_button category2.name
        within("div.item-space", text: c2_preset_item.name) do
          check c2_preset_item.name
        end
      end

      describe "共通項目のテスト" do
        before do
          # confirmにフォームの入力値をpostする
          click_button "登録内容の確認"
          expect(page).to have_selector("h2", text: "登録内容の確認")
        end

        include_examples "ユーザー情報の表示テスト"

        # ナビゲーションのテスト用変数
        let(:navigation_content) { "登録内容を確認するよ！" }

        include_examples "ナビゲーションのテスト"

        it "ページタイトルが表示されること" do
          expect(page).to have_selector("h1", text: "お買い物の登録")
        end

        it "登録内容の確認の項目が存在すること" do
          within ".confirm-window-text" do
            expect(page).to have_selector("h2", text: "登録内容の確認")
          end
        end

        it "登録画面から投稿されたタイトルが表示されること" do
          within ".confirm-window-text" do
            expect(page).to have_selector("h4", text: "タイトル")
            expect(page).to have_selector("span.h5", text: default_title)
          end
        end

        it "お買い物タイトルが入力されたhiddenフィールドが存在すること（登録ボタン用）" do
          expect(find_field("confirm_shopping_record_form_title", type: "hidden").value).to eq default_title
        end

        it "アイテムのhashidが入力されたhiddenフィールドが存在すること（登録ボタン用）" do
          hashid1 = c1_preset_item1.hashid
          hashid2 = c2_preset_item.hashid

          expect(find_field("confirm_shopping_record_form_hashids_#{hashid1}", type: "hidden").value).to eq hashid1
          expect(find_field("confirm_shopping_record_form_hashids_#{hashid2}", type: "hidden").value).to eq hashid2
        end

        it "お買い物タイトルが入力されたhiddenフィールドが存在すること（もどるボタン用）" do
          expect(find_field("back_shopping_record_form_title", type: "hidden").value).to eq default_title
        end

        it "アイテムのhashidが入力されたhiddenフィールドが存在すること（もどるボタン用）" do
          hashid1 = c1_preset_item1.hashid
          hashid2 = c2_preset_item.hashid

          expect(find_field("back_shopping_record_form_hashids_#{hashid1}", type: "hidden").value).to eq hashid1
          expect(find_field("back_shopping_record_form_hashids_#{hashid2}", type: "hidden").value).to eq hashid2
        end

        it "お買い物を登録するボタンが存在すること" do
          expect(page).to have_button("お買い物を登録")
        end

        it "もどるボタンが存在すること" do
          expect(page).to have_button("もどる")
        end

        it "もどるボタンをクリックするとお買い物登録画面に遷移すること" do
          click_button "もどる"

          # pathは変わらないため登録画面の要素を確認
          expect(page).to have_selector("h3", text: "タイトルを入力")
          expect(page).to have_field("タイトル")
          expect(page).to have_button("登録内容の確認")
        end
      end

      describe "ひらがなモードの設定により異なる箇所のテスト" do
        context "ひらがなモードOFF（デフォルト）の場合" do
          before do
            expect(user.hiragana_view).to be_falsey
            # confirmにフォームの入力値をpostする
            click_button "登録内容の確認"
            expect(page).to have_selector("h2", text: "登録内容の確認")
          end

          it "登録画面から投稿されたアイテムがアイテム名(item.name)で表示されること" do
            within ".confirm-window-text" do
              expect(page).to have_selector("h4", text: "買う予定のアイテム")
              expect(page).to have_selector("li", text: c1_preset_item1.name)
              expect(page).to have_selector("li", text: c2_preset_item.name)
            end
          end

          it "登録画面から投稿されたアイテムがひらがな（アイテム名）(item.hiragana)で表示されないこと" do
            within ".confirm-window-text" do
              expect(page).to_not have_selector("li", text: c1_preset_item1.hiragana)
              expect(page).to_not have_selector("li", text: c2_preset_item.hiragana)
            end
          end

          it "チェックされていないアイテム名は表示されないこと" do
            within ".confirm-window-text" do
              expect(page).to_not have_selector("li", text: c1_preset_item2.name)
            end
          end
        end

        context "ひらがなモードONの場合" do
          before do
            user.update(hiragana_view: true)
            # confirmにフォームの入力値をpostする
            click_button "登録内容の確認"
            expect(page).to have_selector("h2", text: "登録内容の確認")
          end

          it "登録画面から投稿されたアイテムがひらがな（アイテム名）(item.hiragana)で表示されること" do
            within ".confirm-window-text" do
              expect(page).to have_selector("h4", text: "買う予定のアイテム")
              expect(page).to have_selector("li", text: c1_preset_item1.hiragana)
              expect(page).to have_selector("li", text: c2_preset_item.hiragana)
            end
          end

          it "登録画面から投稿されたアイテムがアイテム名(item.name)で表示されないこと" do
            within ".confirm-window-text" do
              expect(page).to_not have_selector("li", text: c1_preset_item1.name)
              expect(page).to_not have_selector("li", text: c2_preset_item.name)
            end
          end

          it "チェックされていないひらがな（アイテム名）は表示されないこと" do
            within ".confirm-window-text" do
              expect(page).to_not have_selector("li", text: c1_preset_item2.hiragana)
            end
          end
        end
      end
    end
  end

  describe "お買い物登録のフロー" do
    describe "ユーザー区分で共通のフロー" do
      let(:user) { create(:user) }
      let!(:master_user) { create(:user, :master_admin) }
      let(:category1) { create(:category) }
      let(:category2) { create(:category) }
      let!(:c1_item1) { create(:item, user: master_user, category: category1) }
      let!(:c1_item2) { create(:item, user: master_user, category: category1) }
      let!(:c2_item) { create(:item, user: master_user, category: category2) }
      let(:default_title) { "#{Date.today.to_fs(:date_ja)}のお買い物" }

      before do
        sign_in_as(user)
        # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
        expect(page).to have_content "ログインしました。"
      end

      context "正常系" do
        before do
          visit shopping_new_path
        end

        scenario "ユーザーがお買い物を登録する", js: true do
          expect(page).to have_field("タイトル", with: default_title)

          fill_in "タイトル", with: "お買い物テスト"

          expect(page).to have_selector("button.active", text: category1.name)
          expect(page).to have_selector(".item-name-space-shopping", text: c1_item1.name, visible: true)
          expect(page).to have_selector(".item-name-space-shopping", text: c1_item2.name, visible: true)

          check c1_item1.name
          check c1_item2.name

          click_button category2.name

          expect(page).to have_selector("button.active", text: category2.name)
          expect(page).to have_selector(".item-name-space-shopping", text: c2_item.name, visible: true)

          check c2_item.name

          click_button "登録内容の確認"
          expect(page).to have_selector("h2", text: "登録内容の確認")
          within(".confirm-window", text: "タイトル") do
            expect(page).to have_content "お買い物テスト"
          end
          within(".confirm-window", text: "買う予定のアイテム") do
            expect(page).to have_content c1_item1.name
            expect(page).to have_content c1_item2.name
            expect(page).to have_content c2_item.name
          end

          expect do
            click_button "お買い物を登録"

            expect(page).to have_content "お買い物が登録されました。"
            expect(current_path).to eq root_path
          end.to change { ShoppingRecord.count }.by(1)

          shopping_record = ShoppingRecord.last
          expect(shopping_record.title).to eq "お買い物テスト"
          expect(shopping_record.buys.pluck(:item_name)).to include(c1_item1.name, c1_item2.name, c2_item.name)
        end

        scenario "フォームを入力して登録内容の確認画面から登録画面へ戻るとフォームの入力値が保持される", js: true do
          expect(page).to have_field("タイトル", with: default_title)

          fill_in "タイトル", with: "お買い物テスト"

          expect(page).to have_selector("button.active", text: category1.name)
          expect(page).to have_selector(".item-name-space-shopping", text: c1_item1.name, visible: true)
          expect(page).to have_selector(".item-name-space-shopping", text: c1_item2.name, visible: true)

          check c1_item1.name

          click_button category2.name

          expect(page).to have_selector("button.active", text: category2.name)
          expect(page).to have_selector(".item-name-space-shopping", text: c2_item.name, visible: true)

          check c2_item.name

          click_button "登録内容の確認"
          expect(page).to have_selector("h2", text: "登録内容の確認")
          within(".confirm-window", text: "タイトル") do
            expect(page).to have_content "お買い物テスト"
          end
          within(".confirm-window", text: "買う予定のアイテム") do
            expect(page).to have_content c1_item1.name
            expect(page).to_not have_content c1_item2.name
            expect(page).to have_content c2_item.name
          end

          click_button "もどる"

          # フォームの入力状態の保持を確認
          expect(page).to have_field("タイトル", with: "お買い物テスト")
          expect(find_field(c1_item1.name)).to be_checked
          expect(find_field(c1_item2.name)).to_not be_checked
          click_button category2.name
          expect(find_field(c2_item.name)).to be_checked
        end
      end

      context "異常系" do
        context "チェックできるアイテム数がチェック最大数未満の場合" do
          before do
            visit shopping_new_path
          end

          scenario "必須フィールドが空・未選択の状態でアイテム登録を試みる" do
            fill_in "タイトル", with: ""
            expect(page).to_not have_css("input[type='checkbox'][checked]")

            click_button "登録内容の確認"

            within ".alert" do
              expect(page).to have_content "タイトルを入力してください。"
              expect(page).to have_content "アイテムは#{ShoppingRecordForm::HASHIDS_MINIMUM_SIZE} つ以上選択してください。"
            end

            expect(page).to have_field("タイトル", with: default_title)
          end

          let(:over_length_title) { "a" * 41 }

          scenario "タイトルの文字数がオーバーしている状態でアイテム登録を試みる" do
            fill_in "タイトル", with: over_length_title

            check c1_item1.name

            click_button "登録内容の確認"

            within ".alert" do
              expect(page).to have_content "タイトルは#{ShoppingRecord::MAX_LENGTH_TITLE}文字以内で入力してください。"
            end
          end
        end

        context "チェックできるアイテム数がチェック最大数を超える場合" do
          let(:category3) { create(:category) }
          let!(:c3_items) { create_list(:item, 20, user: master_user, category: category3) }

          before do
            visit shopping_new_path
          end

          scenario "アイテムのチェック数がオーバーした状態でお買い物登録を試みる", js: true do
            expect(page).to have_selector("button.active", text: category1.name)
            check c1_item1.name

            click_button category3.name

            expect(page).to have_selector("button.active", text: category3.name)
            c3_items.each do |item|
              check item.name
            end

            click_button "登録内容の確認"

            within ".alert" do
              expect(page).to have_content "アイテムのチェック数が#{ShoppingRecordForm::HASHIDS_MAXIMUM_SIZE} 個を超えています。"
            end
          end
        end

        context "登録済みの未完了のお買い物数が最大数の場合" do
          let(:unclosed_shopping_records) { create_list(:shopping_record, 5, user: user) }
          let!(:unclosed_shopping_records_buys) do
            unclosed_shopping_records.each do |record|
              create(:buy, user: user, shopping_record: record,
                           item_name: c1_item1.name, item_hiragana: c1_item1.hiragana)
            end
          end

          before do
            visit shopping_new_path
          end

          scenario "未完了のお買い物登録数が最大に達しているときにお買い物の登録を試みる" do
            expect(page).to have_field("タイトル", with: default_title)
            expect(page).to have_selector("button.active", text: category1.name)
            check c1_item1.name

            click_button "登録内容の確認"

            within ".alert" do
              expect(page).to have_content "お買い物の登録数が最大数（#{ShoppingRecordForm::SHOPPING_REGISTRATION_MAXIMUM_COUNT}つ）に達しています。"
            end
          end
        end
      end
    end

    describe "ユーザー区分で異なるフロー" do
      context "ゲストユーザーの場合" do
        let(:user) { User.guest }
        let!(:master_user) { create(:user, :master_admin) }
        let(:category) { create(:category) }
        let!(:item) { create(:item, user: master_user, category: category) }
        let(:default_title) { "#{Date.today.to_fs(:date_ja)}のお買い物" }

        context "異常系" do
          let(:unclosed_shopping_records) { create_list(:shopping_record, 4, user: user) }
          let!(:unclosed_shopping_records_buys) do
            unclosed_shopping_records.each do |record|
              create(:buy, user: user, shopping_record: record,
                           item_name: item.name, item_hiragana: item.hiragana)
            end
          end
          let(:closed_shopping_records) { create_list(:shopping_record, 16, :closed, user: user) }
          let!(:closed_shopping_records_buys) do
            closed_shopping_records.each do |record|
              create(:buy, user: user, shopping_record: record,
                           item_name: item.name, item_hiragana: item.hiragana)
            end
          end

          before do
            # ゲストユーザーボタンからログイン
            visit root_path
            within "nav" do
              click_button "ゲストログイン"
            end
            expect(page).to have_content "ゲストユーザーとしてログインしました。"
            visit shopping_new_path
          end

          scenario "未完了状態・完了状態のお買い物の合計数が最大に達しているときにお買い物登録を試みる" do
            expect(page).to have_field("タイトル", with: default_title)
            expect(page).to have_selector("button.active", text: category.name)
            check item.name

            click_button "登録内容の確認"

            within ".alert" do
              expect(page).to have_content(
                "ゲストユーザーが登録できるお買い物は履歴を含めて" \
                "#{ShoppingRecordForm::GUEST_SHOPPING_MAXIMUM_COUNT}件までです。新しく登録する場合は登録済みのお買い物またはお買い物履歴を削除してください。"
              )
            end
          end
        end
      end
    end
  end
end
