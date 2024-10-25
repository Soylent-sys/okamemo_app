require 'rails_helper'

RSpec.describe "Items", type: :system do
  describe "ビューの要素" do
    describe "index" do
      context "サインインしている場合" do
        let(:user) { create(:user) }

        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
        end

        context "アイテム登録の有/無で共通" do
          before do
            visit items_path
          end

          include_examples "ユーザー情報の表示テスト"

          # ナビゲーションのテスト用変数
          let(:navigation_content) { "新しいアイテムを登録したり、登録済みのアイテムを編集できるよ！" }

          include_examples "ナビゲーションのテスト"

          it "ページタイトルが表示されること" do
            expect(page).to have_selector("h1", text: "アイテム一覧")
          end

          it "メインメニューに戻るリンクが存在すること" do
            expect(page).to have_link("メインメニュー にもどる", href: root_path)
          end

          it "メインメニューに戻るリンクをクリックしてrootページに遷移すること" do
            click_link "メインメニュー にもどる"

            expect(page).to have_http_status(:success)
            expect(current_path).to eq root_path
          end

          it "アイテムの新規登録ボタンが存在すること" do
            expect(page).to have_link("新規登録", href: new_item_path)
          end

          # ヘルプモーダルの基本機能テスト用変数
          let(:page_title) { "アイテム一覧" }

          include_examples "ヘルプモーダルの基本機能テスト"

          it "ヘルプモーダル内の主な項目が正しく表示されること" do
            within "#helpModal.modal" do
              expect(page).to have_selector("h3", text: "アイテム登録の仕方")
              expect(page).to have_selector("h5", text: "① 新規登録ボタンを押して登録画面へ移動する")
              expect(page).to have_selector("h5", text: "② アイテムを登録する")
              expect(page).to have_selector("h3", text: "ボタンについて")
              expect(page).to have_selector("h4", text: "各ボタンの説明")
              expect(page).to have_selector("div.btn", text: "新規登録")
              expect(page).to have_selector("h5", text: "登録ボタン")
              expect(page).to have_selector("i.fa-pencil")
              expect(page).to have_selector("h5", text: "編集ボタン")
              expect(page).to have_selector("i.fa-trash-can")
              expect(page).to have_selector("h5", text: "削除ボタン")
            end
          end
        end

        context "アイテムが登録されている場合" do
          # アイテムのcreate時にマスター管理ユーザーの登録アイテム（デフォルトアイテム）との
          # 重複を確認するバリデーションを実行するためマスター管理ユーザーが必要
          let!(:master_user) { create(:user, :master_admin) }
          let(:category_1) { create(:category, id: 1) }
          let(:category_2) { create(:category, id: 2) }
          let!(:no_item_category) { create(:category, id: 3) }
          let!(:user_item_1) { create(:item, user: user, category: category_1) }
          let!(:user_item_2) { create(:item, user: user, category: category_2) }
          let!(:user_item_3) { create(:item, user: user, category: category_2) }
          let(:other_user) { create(:user) }
          let!(:other_user_item) { create(:item, user: other_user, category: category_2) }

          before do
            visit items_path
          end

          it "アイテムが登録されていないメッセージが存在しないこと" do
            expect(page).to_not have_selector("h2", text: "アイテムは登録されていません")
          end

          it "カテゴリーの項目が表示されること" do
            expect(page).to have_selector("h4", text: "カテゴリー")
          end

          it "登録アイテムの項目が表示されること" do
            expect(page).to have_selector("h4", text: "登録アイテム")
          end

          it "ユーザーが登録しているアイテムのカテゴリーが表示されること" do
            expect(page).to have_button(category_1.name)
            expect(page).to have_button(category_2.name)
          end

          it "ユーザーが登録していないアイテムのカテゴリーは表示されないこと" do
            expect(page).to_not have_button(no_item_category.name)
          end

          it "初期状態では表示カテゴリーの中で一番若いidのカテゴリーが選択されていること" do
            expect(page).to have_selector("button.active", text: category_1.name)
            expect(page).to_not have_selector("button.active", text: category_2.name)
          end

          it "選択したカテゴリーのユーザーが登録したアイテム名が表示されること", js: true do
            click_button category_2.name
            expect(page).to have_selector("button.active", text: category_2.name)

            expect(page).to have_selector(".item-name-space", text: user_item_2.name, visible: true)
            expect(page).to have_selector(".item-name-space", text: user_item_3.name, visible: true)
          end

          it "選択したカテゴリーの別のユーザーが登録したアイテム名が表示されないこと", js: true do
            click_button category_2.name
            expect(page).to have_selector("button.active", text: category_2.name)

            expect(page).to_not have_selector(".item-name-space", text: other_user_item.name)
          end

          it "選択していないカテゴリーのアイテム名が表示されないこと", js: true do
            click_button category_2.name
            expect(page).to have_selector("button.active", text: category_2.name)

            expect(page).to have_selector(".item-name-space", text: user_item_1.name, visible: false)
          end

          it "表示中のアイテムそれぞれの編集リンクが存在すること", js: true do
            click_button category_2.name
            expect(page).to have_selector("button.active", text: category_2.name)

            expect(page).to have_link(href: edit_item_path(user_item_2.hashid), visible: true)
            expect(page).to have_link(href: edit_item_path(user_item_3.hashid), visible: true)
          end

          it "アイテムの編集リンクからアイテム編集画面へ遷移できること", js: true do
            click_button category_2.name
            expect(page).to have_selector("button.active", text: category_2.name)
            expect(page).to have_link(href: edit_item_path(user_item_2.hashid), visible: true)

            within("div.item-space", text: user_item_2.name) do
              find("i.edit-icon").click
            end

            expect(page).to have_selector("h1", text: "アイテムの編集")
            expect(current_path).to eq edit_item_path(user_item_2.hashid)
          end

          # 表示中のアイテム数
          let(:visible_items_count) { 2 }

          it "表示中のアイテムそれぞれの削除ボタンが存在すること", js: true do
            click_button category_2.name

            expect(page).to have_selector("i.delete-icon", count: visible_items_count, visible: true)
          end

          it "アイテム削除ボタンをクリックするとモーダルが表示されること", js: true do
            expect(page).to have_selector("#turbo-confirm-modal", visible: false)

            within("div.item-space", text: user_item_1.name) do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)
          end

          it "アイテム削除モーダルにタイトルが表示されること", js: true do
            within("div.item-space", text: user_item_1.name) do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            within "#turbo-confirm-modal" do
              expect(page).to have_selector("h1", visible: true, text: "アイテムの削除")
            end
          end

          it "アイテム削除モーダルのヘッダーにモーダルを閉じるボタンがあること", js: true do
            within("div.item-space", text: user_item_1.name) do
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
            within("div.item-space", text: user_item_1.name) do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            within "#turbo-confirm-modal" do
              expect(page).to have_selector("button", visible: true, text: "削除する")
              expect(page).to have_selector("button", visible: true, text: "キャンセル")
            end
          end

          it "アイテム削除モーダルのキャンセルボタンでアイテム削除を中止できること", js: true do
            within("div.item-space", text: user_item_1.name) do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            within "#turbo-confirm-modal" do
              click_button "キャンセル"
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: false)
          end

          it "アイテム削除モーダルの外をクリックするとモーダルが閉じること", js: true do
            within("div.item-space", text: user_item_1.name) do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            # モーダルの外をクリック
            page.execute_script("document.querySelector('body').click();")

            expect(page).to have_selector("#turbo-confirm-modal", visible: false)
          end

          it "アイテム削除ボタンからアイテムが削除できること", js: true do
            within("div.item-space", text: user_item_1.name) do
              find("i.delete-icon").click
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            expect do
              within "#turbo-confirm-modal" do
                click_button "削除する"
              end

              within ".alert" do
                expect(page).to have_content "アイテムが削除されました。"
              end

              expect(current_path).to eq items_path
            end.to change { Item.count }.by(-1)

            # アイテムがDBに存在しないことを確認
            expect(Item.where(id: user_item_1.id)).to_not exist
          end
        end

        context "アイテムが登録されていない場合" do
          before do
            visit items_path
          end

          it "カテゴリーの項目が表示されないこと" do
            expect(page).to_not have_selector("h4", text: "カテゴリー")
          end

          it "登録アイテムの項目が表示されないこと" do
            expect(page).to_not have_selector("h4", text: "登録アイテム")
          end

          it "アイテムが登録されていないメッセージが存在すること" do
            expect(page).to have_selector("h2", text: "アイテムは登録されていません")
          end
        end
      end

      context "サインインしていない場合" do
        before do
          visit items_path
        end

        include_examples "非ログイン状態で認可が必要なページにアクセスした時のリダイレクトテスト"
      end

      describe "ユーザー区分で異なる箇所のテスト" do
        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
          visit items_path
        end

        context "ゲストユーザー以外の場合" do
          let(:user) { create(:user) }

          it "ヘルプモーダル内に一般ユーザー向けのアイテム最大登録数のテキストが存在すること" do
            within "#helpModal.modal" do
              expect(page).to have_selector("h3", text: "アイテムの最大登録数")
              expect(page).to have_content "登録できるアイテムの数は最大#{Item::ITEM_MAXIMUM_COUNT}個までです。"
            end
          end

          it "ヘルプモーダル内にゲストユーザー向けのアイテム最大登録数のテキストが存在しないこと" do
            within "#helpModal.modal" do
              expect(page).to_not have_selector("h3", text: "ゲストユーザーのアイテム最大登録数")
              expect(page).to_not have_content "ゲストユーザーで登録できるアイテムの数は最大#{Item::GUEST_ITEM_MAXIMUM_COUNT}個までです。"
            end
          end
        end

        context "ゲストユーザーの場合" do
          let(:user) { User.guest }

          it "ヘルプモーダル内にゲストユーザー向けのアイテム最大登録数のテキストが存在すること" do
            within "#helpModal.modal" do
              expect(page).to have_selector("h3", text: "ゲストユーザーのアイテム最大登録数")
              expect(page).to have_content "ゲストユーザーで登録できるアイテムの数は最大#{Item::GUEST_ITEM_MAXIMUM_COUNT}個までです。"
            end
          end

          it "ヘルプモーダル内に一般ユーザー向けのアイテム最大登録数のテキストが存在しないこと" do
            within "#helpModal.modal" do
              expect(page).to_not have_selector("h3", text: "アイテムの最大登録数")
              expect(page).to_not have_content "登録できるアイテムの数は最大#{Item::ITEM_MAXIMUM_COUNT}個までです。"
            end
          end
        end
      end
    end

    describe "new" do
      context "サインインしている場合" do
        let(:user) { create(:user) }
        # フォームのカテゴリー選択フィールドで使用するカテゴリー
        let!(:categories) { create_list(:category, 3) }
        # YAMLファイルからヘルプモーダルのカテゴリー説明内容を読み込む
        let(:categories_help) { YAML.safe_load_file(Rails.root.join('spec/fixtures/categories_help.yml')) }

        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
          visit new_item_path
        end

        include_examples "ユーザー情報の表示テスト"

        # ナビゲーションのテスト用変数
        let(:navigation_content) { "ここでは新しいアイテムを登録できるよ！" }

        include_examples "ナビゲーションのテスト"

        it "ページタイトルが表示されること" do
          expect(page).to have_selector("h1", text: "アイテムの登録")
        end

        it "アイテム一覧に戻るリンクが存在すること" do
          expect(page).to have_link("アイテム一覧 にもどる", href: items_path)
        end

        it "アイテム一覧に戻るリンクをクリックしてアイテム一覧ページに遷移すること" do
          click_link "アイテム一覧 にもどる"

          expect(page).to have_http_status(:success)
          expect(current_path).to eq items_path
        end

        it "アイテム登録フォームが表示されること" do
          expect(page).to have_selector("h2", text: "登録内容の入力")
          expect(page).to have_select("item[category_id]", options: ["カテゴリーを選択", categories.map(&:name)].flatten)
          expect(page).to have_field("アイテム名")
          expect(page).to have_field("ひらがな（アイテム名）")
          expect(page).to have_button("登録")
        end

        # ヘルプモーダルの基本機能テスト用変数
        let(:page_title) { "アイテムの登録" }

        include_examples "ヘルプモーダルの基本機能テスト"

        it "ヘルプモーダル内の主な項目が正しく表示されること" do
          within "#helpModal.modal" do
            expect(page).to have_selector("h3", text: "フォームについて")
            expect(page).to have_selector("h4", text: "入力項目の説明")
            expect(page).to have_selector("h5", text: "カテゴリーを選択")
            expect(page).to have_selector("h5", text: "アイテム名")
            expect(page).to have_selector("h5", text: "ひらがな（アイテム名）")
            expect(page).to have_selector("h3", text: "ボタン・カテゴリーについて")
            expect(page).to have_selector("h4", text: "各ボタンの説明")
            expect(page).to have_selector("div.btn", text: "登録")
            expect(page).to have_selector("h5", text: "登録ボタン")
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
          visit new_item_path
        end

        include_examples "非ログイン状態で認可が必要なページにアクセスした時のリダイレクトテスト"
      end
    end

    describe "edit" do
      context "サインインしている場合" do
        let(:user) { create(:user) }
        # アイテムのcreate時にマスター管理ユーザーの登録アイテム（デフォルトアイテム）との
        # 重複を確認するバリデーションを実行するためマスター管理ユーザーが必要
        let!(:master_user) { create(:user, :master_admin) }
        let(:categories) { create_list(:category, 3) }
        let!(:user_item) { create(:item, user: user, category: categories[0]) }
        # YAMLファイルからヘルプモーダルのカテゴリー説明内容を読み込む
        let(:categories_help) { YAML.safe_load_file(Rails.root.join('spec/fixtures/categories_help.yml')) }

        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
          visit edit_item_path(user_item.hashid)
        end

        include_examples "ユーザー情報の表示テスト"

        # ナビゲーションのテスト用変数
        let(:navigation_content) { "ここではアイテムを編集できるよ！" }

        include_examples "ナビゲーションのテスト"

        it "ページタイトルが表示されること" do
          expect(page).to have_selector("h1", text: "アイテムの編集")
        end

        it "アイテム一覧に戻るリンクが存在すること" do
          expect(page).to have_link("アイテム一覧 にもどる", href: items_path)
        end

        it "アイテム一覧に戻るリンクをクリックしてアイテム一覧ページに遷移すること" do
          click_link "アイテム一覧 にもどる"

          expect(page).to have_http_status(:success)
          expect(current_path).to eq items_path
        end

        it "アイテム更新フォームが表示されること" do
          expect(page).to have_selector("h2", text: "編集内容の入力")
          expect(page).to have_select("item[category_id]", options: categories.map(&:name))
          expect(page).to have_field("アイテム名")
          expect(page).to have_field("ひらがな（アイテム名）")
          expect(page).to have_button("更新")
        end

        it "デフォルトでカテゴリー選択のフィールドで現在のカテゴリーが選択されていること" do
          expect(page).to have_select("item[category_id]", selected: categories[0].name)
        end

        it "デフォルトでアイテム名のフィールドに現在のアイテム名が入力されていること" do
          expect(page).to have_field("アイテム名", with: user_item.name)
        end

        it "デフォルトでひらがな（アイテム名）のフィールドに現在のひらがな（アイテム名）が入力されていること" do
          expect(page).to have_field("ひらがな（アイテム名）", with: user_item.hiragana)
        end

        # ヘルプモーダルの基本機能テスト用変数
        let(:page_title) { "アイテムの編集" }

        include_examples "ヘルプモーダルの基本機能テスト"

        it "ヘルプモーダル内の主な項目が正しく表示されること" do
          within "#helpModal.modal" do
            expect(page).to have_selector("h3", text: "フォームについて")
            expect(page).to have_selector("h4", text: "入力項目の説明")
            expect(page).to have_selector("h5", text: "カテゴリーを選択")
            expect(page).to have_selector("h5", text: "アイテム名")
            expect(page).to have_selector("h5", text: "ひらがな（アイテム名）")
            expect(page).to have_selector("h3", text: "ボタン・カテゴリーについて")
            expect(page).to have_selector("h4", text: "各ボタンの説明")
            expect(page).to have_selector("div.btn", text: "更新")
            expect(page).to have_selector("h5", text: "更新ボタン")
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
        let(:user) { create(:user) }
        # アイテムのcreate時にマスター管理ユーザーの登録アイテム（デフォルトアイテム）との
        # 重複を確認するバリデーションを実行するためマスター管理ユーザーが必要
        let!(:master_user) { create(:user, :master_admin) }
        let(:category) { create(:category) }
        let!(:user_item) { create(:item, user: user, category: category) }

        before do
          visit edit_item_path(user_item.hashid)
        end

        include_examples "非ログイン状態で認可が必要なページにアクセスした時のリダイレクトテスト"
      end
    end
  end

  describe "アイテム登録のフロー" do
    describe "ユーザー区分で共通のフロー" do
      let(:user) { create(:user) }
      # アイテムのcreate時にマスター管理ユーザーの登録アイテム（デフォルトアイテム）との
      # 重複を確認するバリデーションを実行するためマスター管理ユーザーが必要
      let!(:master_user) { create(:user, :master_admin) }
      let(:category) { create(:category) }
      let!(:exist_item) { create(:item, user: user, category: category, name: "既存アイテム", hiragana: "きぞんあいてむ") }
      let!(:preset_item) { create(:item, user: master_user, category: category, name: "デフォルトアイテム", hiragana: "でふぉるとあいてむ") }

      before do
        sign_in_as(user)
        # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
        expect(page).to have_content "ログインしました。"
        visit new_item_path
      end

      context "正常系" do
        scenario "ユーザーがアイテムを登録する" do
          expect do
            select category.name, from: "item[category_id]"
            # アイテム名、ひらがな（アイテム名）のフィールドはラベル文字列だと重複して扱われるためidを指定
            fill_in "item_name", with: "テストアイテム1"
            fill_in "item_hiragana", with: "てすとあいてむ1"
            click_button "登録"
          end.to change { Item.count }.by(1)

          expect(current_path).to eq items_path
          expect(page).to have_content "アイテム登録が完了しました。"
        end
      end

      context "異常系" do
        scenario "必須フィールドが空・未選択の状態でアイテム登録を試みる" do
          expect do
            click_button "登録"
          end.to_not change { Item.count }

          expect(page).to have_content "カテゴリーを入力してください。"
          expect(page).to have_content "アイテム名を入力してください。"
          expect(page).to have_content "ひらがな（アイテム名）を入力してください。"
        end

        let(:over_length_name) { "a" * 21 }

        scenario "アイテム名の文字数がオーバーしている状態でアイテム登録を試みる" do
          expect do
            select category.name, from: "item[category_id]"
            # アイテム名、ひらがな（アイテム名）のフィールドはラベル文字列だと重複して扱われるためidを指定
            fill_in "item_name", with: over_length_name
            fill_in "item_hiragana", with: "てすとあいてむ1"
            click_button "登録"
          end.to_not change { Item.count }

          expect(page).to have_content "アイテム名は#{Item::MAX_LENGTH_NAME}文字以内で入力してください。"
        end

        let(:over_length_hiragana) { "あ" * 21 }

        scenario "ひらがな（アイテム名）の文字数がオーバーしている状態でアイテム登録を試みる" do
          expect do
            select category.name, from: "item[category_id]"
            # アイテム名、ひらがな（アイテム名）のフィールドはラベル文字列だと重複して扱われるためidを指定
            fill_in "item_name", with: "テストアイテム1"
            fill_in "item_hiragana", with: over_length_hiragana
            click_button "登録"
          end.to_not change { Item.count }

          expect(page).to have_content "ひらがな（アイテム名）は#{Item::MAX_LENGTH_HIRAGANA}文字以内で入力してください。"
        end

        let(:invalid_hiragana) { "テストアイテム壱" }

        scenario "ひらがな（アイテム名）を平仮名と半角数字以外で入力している状態でアイテム登録を試みる" do
          expect do
            select category.name, from: "item[category_id]"
            # アイテム名、ひらがな（アイテム名）のフィールドはラベル文字列だと重複して扱われるためidを指定
            fill_in "item_name", with: "テストアイテム1"
            fill_in "item_hiragana", with: invalid_hiragana
            click_button "登録"
          end.to_not change { Item.count }

          expect(page).to have_content "ひらがな（アイテム名）の項目は平仮名・半角数字のみ使用してください。"
        end

        scenario "登録済みのアイテムと同じカテゴリー、アイテム名で登録を試みる" do
          expect do
            select exist_item.category.name, from: "item[category_id]"
            # アイテム名、ひらがな（アイテム名）のフィールドはラベル文字列だと重複して扱われるためidを指定
            fill_in "item_name", with: exist_item.name
            fill_in "item_hiragana", with: "てすとあいてむ1"
            click_button "登録"
          end.to_not change { Item.count }

          expect(page).to have_content "アイテム名は同じカテゴリーの中で二つ以上登録できません。"
        end

        scenario "登録済みのアイテムと同じカテゴリー、ひらがな（アイテム名）で登録を試みる" do
          expect do
            select exist_item.category.name, from: "item[category_id]"
            # アイテム名、ひらがな（アイテム名）のフィールドはラベル文字列だと重複して扱われるためidを指定
            fill_in "item_name", with: "テストアイテム1"
            fill_in "item_hiragana", with: exist_item.hiragana
            click_button "登録"
          end.to_not change { Item.count }

          expect(page).to have_content "ひらがな（アイテム名）は同じカテゴリーの中で二つ以上登録できません。"
        end

        scenario "デフォルトアイテム（マスター管理ユーザーの登録アイテム）と同じカテゴリー、アイテム名で登録を試みる" do
          expect do
            select preset_item.category.name, from: "item[category_id]"
            # アイテム名、ひらがな（アイテム名）のフィールドはラベル文字列だと重複して扱われるためidを指定
            fill_in "item_name", with: preset_item.name
            fill_in "item_hiragana", with: "てすとあいてむ1"
            click_button "登録"
          end.to_not change { Item.count }

          expect(page).to have_content "アイテム名が同じカテゴリーに存在するデフォルトアイテムと重複しています。"
        end

        scenario "デフォルトアイテム（マスター管理ユーザーの登録アイテム）と同じカテゴリー、ひらがな（アイテム名）で登録を試みる" do
          expect do
            select preset_item.category.name, from: "item[category_id]"
            # アイテム名、ひらがな（アイテム名）のフィールドはラベル文字列だと重複して扱われるためidを指定
            fill_in "item_name", with: "テストアイテム1"
            fill_in "item_hiragana", with: preset_item.hiragana
            click_button "登録"
          end.to_not change { Item.count }

          expect(page).to have_content "ひらがな（アイテム名）が同じカテゴリーに存在するデフォルトアイテムと重複しています。"
        end
      end
    end

    describe "ユーザー区分で異なるフロー" do
      # アイテムのcreate時にマスター管理ユーザーの登録アイテム（デフォルトアイテム）との
      # 重複を確認するバリデーションを実行するためマスター管理ユーザーが必要
      let!(:master_user) { create(:user, :master_admin) }
      let(:category) { create(:category) }

      context "一般・管理ユーザーの場合" do
        let(:user) { create(:user) }
        let(:general_user_item_maximum_count) { 150 }
        let!(:user_items) { create_list(:item, general_user_item_maximum_count, user: user, category: category) }

        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
          visit new_item_path
        end

        context "異常系" do
          scenario "アイテムの最大登録数に達した状態で登録を試みる" do
            expect do
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

      context "マスター管理ユーザーの場合" do
        let(:general_user_item_maximum_count) { 150 }
        let!(:master_user_items) { create_list(:item, general_user_item_maximum_count, user: master_user, category: category) }

        before do
          sign_in_as(master_user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
          visit new_item_path
        end

        context "正常系" do
          scenario "マスター管理ユーザーはのアイテム最大登録数を超えてアイテム登録ができる" do
            expect do
              select category.name, from: "item[category_id]"
              # アイテム名、ひらがな（アイテム名）のフィールドはラベル文字列だと重複して扱われるためidを指定
              fill_in "item_name", with: "テストアイテム"
              fill_in "item_hiragana", with: "てすとあいてむ"
              click_button "登録"
            end.to change { Item.count }.by(1)

            expect(current_path).to eq items_path
            expect(page).to have_content "アイテム登録が完了しました。"
          end
        end
      end

      context "ゲストユーザーの場合" do
        let(:guest_user) { User.guest }
        let(:guest_user_item_maximum_count) { 10 }
        let!(:guest_user_items) { create_list(:item, guest_user_item_maximum_count, user: guest_user, category: category) }

        before do
          # ゲストユーザーボタンからログイン
          visit root_path
          within "nav" do
            click_button "ゲストログイン"
          end
          expect(page).to have_content "ゲストユーザーとしてログインしました。"
          visit new_item_path
        end

        context "異常系" do
          scenario "ゲストユーザーのアイテムの最大登録数に達した状態で登録を試みる" do
            expect do
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

  describe "アイテム編集のフロー" do
    let(:user) { create(:user) }
    # アイテムのcreate時にマスター管理ユーザーの登録アイテム（デフォルトアイテム）との
    # 重複を確認するバリデーションを実行するためマスター管理ユーザーが必要
    let!(:master_user) { create(:user, :master_admin) }
    let(:category_1) { create(:category) }
    let!(:category_2) { create(:category) }
    let!(:edit_item) { create(:item, user: user, category: category_1, name: "編集アイテム1", hiragana: "へんしゅうあいてむ1") }
    let!(:exist_item) { create(:item, user: user, category: category_1, name: "既存アイテム", hiragana: "きぞんあいてむ") }
    let!(:preset_item) { create(:item, user: master_user, category: category_1, name: "デフォルトアイテム", hiragana: "でふぉるとあいてむ") }

    before do
      sign_in_as(user)
      # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
      expect(page).to have_content "ログインしました。"
      visit items_path

      # アイテム一覧画面のアイテムの編集ボタンから編集画面へアクセス
      within("div.item-space", text: edit_item.name) do
        click_link(href: edit_item_path(edit_item.hashid))
      end

      expect(page).to have_selector("h1", text: "アイテムの編集")
      expect(current_path).to eq edit_item_path(edit_item.hashid)
    end

    context "正常系" do
      let(:new_name) { "新しいアイテム名" }
      let(:new_hiragana) { "あたらしいひらがな" }

      scenario "ユーザーがアイテムのカテゴリーを更新する" do
        expect do
          select category_2.name, from: "item[category_id]"
          click_button "更新"
        end.to change { edit_item.reload.category_id }.from(category_1.id).to(category_2.id)

        expect(page).to have_content "アイテムの更新が完了しました。"
        expect(current_path).to eq items_path
      end

      scenario "ユーザーがアイテム名を更新する" do
        before_name = edit_item.name
        expect do
          # アイテム名、ひらがな（アイテム名）のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "item_name", with: new_name
          click_button "更新"
        end.to change { edit_item.reload.name }.from(before_name).to(new_name)

        expect(page).to have_content "アイテムの更新が完了しました。"
        expect(current_path).to eq items_path
      end

      scenario "ユーザーがひらがな（アイテム名）を更新する" do
        before_hiragana = edit_item.hiragana
        expect do
          # アイテム名、ひらがな（アイテム名）のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "item_hiragana", with: new_hiragana
          click_button "更新"
        end.to change { edit_item.reload.hiragana }.from(before_hiragana).to(new_hiragana)

        expect(page).to have_content "アイテムの更新が完了しました。"
        expect(current_path).to eq items_path
      end
    end

    context "異常系" do
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
    let(:user) { create(:user) }
    # アイテムのcreate時にマスター管理ユーザーの登録アイテム（デフォルトアイテム）との
    # 重複を確認するバリデーションを実行するためマスター管理ユーザーが必要
    let!(:master_user) { create(:user, :master_admin) }
    let(:category) { create(:category) }
    let!(:user_item) { create(:item, user: user, category: category, name: "テストアイテム1", hiragana: "てすとあいてむ1") }

    before do
      sign_in_as(user)
      # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
      expect(page).to have_content "ログインしました。"
      visit items_path
    end

    scenario "ユーザーがアイテムを削除する", js: true do
      within("div.item-space", text: user_item.name) do
        find("i.delete-icon").click
      end

      expect(page).to have_selector("#turbo-confirm-modal", visible: true)

      expect do
        within "#turbo-confirm-modal" do
          click_button "削除する"
        end

        within ".alert" do
          expect(page).to have_content "アイテムが削除されました。"
        end

        expect(current_path).to eq items_path
      end.to change { Item.count }.by(-1)

      # アイテムがDBに存在しないことを確認
      expect(Item.where(id: user_item.id)).to_not exist
    end
  end
end
