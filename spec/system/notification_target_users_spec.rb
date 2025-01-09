require 'rails_helper'

RSpec.describe "NotificationTargetUsers", type: :system do
  # 一部のテストで非同期のメール送信を即時実行するために必要
  include ActiveJob::TestHelper

  describe "ビューの要素" do
    describe "index" do
      let(:user) { create(:user) }

      context "サインインしている場合" do
        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
          visit notification_target_users_path
        end

        include_examples "ユーザー情報の表示テスト"

        # ナビゲーションのテスト用変数
        let(:navigation_content) do
          "ここではお買い物内容をメールで通知するメールアドレスを #{NotificationTargetUser::NOTIFICATION_TARGET_USER_MUXIMUM_COUNT} 件まで登録できるよ！"
        end

        include_examples "ナビゲーションのテスト"

        it "ページタイトルが表示されること" do
          expect(page).to have_selector("h1", text: "通知メール登録")
        end

        it "メインメニューに戻るリンクが存在すること" do
          expect(page).to have_link("メインメニュー にもどる", href: root_path)
        end

        it "メインメニューに戻るリンクをクリックしてrootページに遷移すること" do
          click_link "メインメニュー にもどる"

          expect(page).to have_http_status(:success)
          expect(current_path).to eq root_path
        end

        it "通知対象ユーザーの登録用リンクが存在すること" do
          expect(page).to have_link("登録", href: new_notification_target_user_path)
        end

        it "通知対象ユーザー登録画面へのリンクをクリックして通知対象ユーザー登録画面へ遷移できること" do
          within("div.shopping-record-window-bg", text: "通知メールアドレス") do
            click_link "登録"
          end

          expect(page).to have_http_status(:success)
          expect(current_path).to eq new_notification_target_user_path
        end

        # ヘルプモーダルの基本機能テスト用変数
        let(:page_title) { "通知メール登録" }

        include_examples "ヘルプモーダルの基本機能テスト"

        it "ヘルプモーダル内の主な項目が正しく表示されること" do
          within "#helpModal.modal" do
            expect(page).to have_selector("h3", text: "通知メールアドレスの登録の仕方")
            expect(page).to have_selector("h5", text: "① 登録ボタンを押して登録画面へ移動する")
            expect(page).to have_selector("h5", text: "② 通知メールアドレスを登録する")
            expect(page).to have_selector("h5", text: "③ 登録した人に確認メールが送信されるのでメールアドレス認証を完了してもらう")
            expect(page).to have_selector("h3", text: "ボタンについて")
            expect(page).to have_selector("h4", text: "各ボタンの説明")
            expect(page).to have_selector("div.btn", text: "登録")
            expect(page).to have_selector("h5", text: "登録ボタン")
            expect(page).to have_selector("i.fa-trash-can")
            expect(page).to have_selector("h5", text: "削除ボタン")
            expect(page).to have_selector("div.send-icon", text: "確認メール再送信")
            expect(page).to have_selector("h5", text: "確認メール再送信ボタン")
          end
        end
      end

      context "サインインしていない場合" do
        before do
          visit notification_target_users_path
        end

        include_examples "非ログイン状態で認可が必要なページにアクセスした時のリダイレクトテスト"
      end

      describe "通知対象ユーザー登録の有／無・状態で異なる箇所のテスト" do
        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
        end

        context "通知対象ユーザーが未登録の場合" do
          before do
            visit notification_target_users_path
          end

          it "通知メールアドレス欄にメールアドレス未登録のメッセージが存在すること" do
            within("div.shopping-record-window-bg", text: "通知メールアドレス") do
              expect(page).to have_selector("h3", text: "メールアドレスは未登録です")
            end
          end
        end

        context "通知対象ユーザーが登録されている場合" do
          context "共通のテスト" do
            let!(:notification_target_users) { create_list(:notification_target_user, 2, user: user) }

            before do
              visit notification_target_users_path
            end

            it "登録済通知対象ユーザーの名前が表示されていること" do
              notification_target_users.each do |nt_user|
                expect(page).to have_selector("h5", text: nt_user.name)
              end
            end

            it "登録済通知対象ユーザーのメールアドレスが表示されていること" do
              notification_target_users.each do |nt_user|
                within("div.shopping-record-bg", text: nt_user.name) do
                  expect(page).to have_selector("h5", text: nt_user.email)
                end
              end
            end

            it "表示中の各通知対象ユーザーに削除ボタンが存在すること" do
              notification_target_users.each do |nt_user|
                within("div.shopping-record-bg", text: nt_user.name) do
                  expect(page).to have_selector("i.delete-icon")
                end
              end
            end

            it "通知対象ユーザーの削除ボタンをクリックするとモーダルが表示されること", js: true do
              expect(page).to have_selector("#turbo-confirm-modal", visible: false)

              within("div.shopping-record-bg", text: notification_target_users[0].name) do
                find("i.delete-icon").click
              end

              expect(page).to have_selector("#turbo-confirm-modal", visible: true)
            end

            it "通知対象ユーザー削除モーダルにタイトルが表示されること", js: true do
              within("div.shopping-record-bg", text: notification_target_users[0].name) do
                find("i.delete-icon").click
              end

              expect(page).to have_selector("#turbo-confirm-modal", visible: true)

              within "#turbo-confirm-modal" do
                expect(page).to have_selector("h1", visible: true, text: "通知ユーザーの削除")
              end
            end

            it "通知対象ユーザー削除モーダルのヘッダーにモーダルを閉じるボタンがあること", js: true do
              within("div.shopping-record-bg", text: notification_target_users[0].name) do
                find("i.delete-icon").click
              end

              expect(page).to have_selector("#turbo-confirm-modal", visible: true)

              within "#turbo-confirm-modal" do
                within ".modal-header" do
                  expect(page).to have_selector("button.btn-close", visible: true)
                end
              end
            end

            it "通知対象ユーザー削除モーダルに削除ボタン・キャンセルボタンが表示されること", js: true do
              within("div.shopping-record-bg", text: notification_target_users[0].name) do
                find("i.delete-icon").click
              end

              expect(page).to have_selector("#turbo-confirm-modal", visible: true)

              within "#turbo-confirm-modal" do
                expect(page).to have_selector("button", visible: true, text: "削除する")
                expect(page).to have_selector("button", visible: true, text: "キャンセル")
              end
            end

            it "通知対象ユーザー削除モーダルのキャンセルボタンでお買い物削除を中止できること", js: true do
              within("div.shopping-record-bg", text: notification_target_users[0].name) do
                find("i.delete-icon").click
              end

              expect(page).to have_selector("#turbo-confirm-modal", visible: true)

              within "#turbo-confirm-modal" do
                click_button "キャンセル"
              end

              expect(page).to have_selector("#turbo-confirm-modal", visible: false)
            end

            it "通知対象ユーザー削除モーダルの外をクリックするとモーダルが閉じること", js: true do
              within("div.shopping-record-bg", text: notification_target_users[0].name) do
                find("i.delete-icon").click
              end

              expect(page).to have_selector("#turbo-confirm-modal", visible: true)

              # モーダルの外をクリック
              page.execute_script("document.querySelector('body').click();")

              expect(page).to have_selector("#turbo-confirm-modal", visible: false)
            end

            it "通知対象ユーザー削除ボタンから通知対象ユーザーが削除できること", js: true do
              within("div.shopping-record-bg", text: notification_target_users[0].name) do
                find("i.delete-icon").click
              end

              expect(page).to have_selector("#turbo-confirm-modal", visible: true)

              expect do
                within "#turbo-confirm-modal" do
                  click_button "削除する"
                end

                within ".alert" do
                  expect(page).to have_content "通知対象ユーザーが削除されました。"
                end
              end.to change { NotificationTargetUser.count }.by(-1)

              # 削除した通知ーユーザーがDBに存在しないことを確認
              expect(NotificationTargetUser.where(id: notification_target_users[0].id)).to_not exist
            end
          end

          context "通知対象ユーザーが認証済みの場合" do
            let!(:notification_target_user) { create(:notification_target_user, user: user) }

            before do
              visit notification_target_users_path
            end

            it "メールアドレス認証済み メッセージが表示されていること" do
              within("div.shopping-record-bg", text: notification_target_user.name) do
                expect(page).to have_selector("div.email-confirm-ok", text: "メールアドレス認証済み")
              end
            end
          end

          context "通知対象ユーザーが未認証の場合" do
            let!(:notification_target_user) { create(:notification_target_user, :unconfirmed, user: user) }

            context "通知対象ユーザー認証メールの期限が切れていない場合" do
              before do
                visit notification_target_users_path
              end

              it "メールアドレス認証待ち メッセージが表示されていること" do
                within("div.shopping-record-bg", text: notification_target_user.name) do
                  expect(page).to have_selector("div.email-confirm-info", text: "メールアドレス認証待ち")
                end
              end
            end

            context "通知対象ユーザー認証メールの期限が切れている場合" do
              let(:email_confirmation_limit) { NotificationTargetUser::EMAIL_CONFIRMATION_LIMIT }

              before do
                # 期限を過ぎた状態でページを読み込む
                travel_to(Time.current + email_confirmation_limit.minutes + 1.second) do
                  visit notification_target_users_path
                end
              end

              it "確認メール有効期限切れ メッセージが表示されていること" do
                within("div.shopping-record-bg", text: notification_target_user.name) do
                  expect(page).to have_selector("div.email-confirm-ng", text: "確認メール有効期限切れ")
                end
              end

              it "確認メールを再送信するリンクが存在すること" do
                within("div.shopping-record-bg", text: notification_target_user.name) do
                  expect(page).to have_link "確認メール再送信"
                end
              end

              it "確認メール再送信リンクのクリックで通知対象ユーザーのメールアドレスに確認メールが送信されること" do
                # 期限を過ぎた状態で確認メールを再送信する
                travel_to(Time.current + email_confirmation_limit.minutes + 1.second) do
                  # 非同期のメール送信を即時実行する
                  perform_enqueued_jobs do
                    within("div.shopping-record-bg", text: notification_target_user.name) do
                      click_link "確認メール再送信"
                    end
                  end
                end

                expect(page).to have_content(
                  "#{notification_target_user.email} へ確認メールを再送信しました。" \
                  "確認メールの認証の有効期限は#{email_confirmation_limit}分です。"
                )

                # 確認メール送信確認
                email = ActionMailer::Base.deliveries.last
                expect(email.to).to include notification_target_user.email
                expect(email.subject).to eq "メールアドレス認証のお願い"
              end
            end
          end

          context "通知対象ユーザーの登録数が最大に達している場合" do
            # 認証済み・未認証の通知対象ユーザー合わせて3件を登録済みにする
            let!(:notification_target_users) { create_list(:notification_target_user, 2, user: user) }
            let!(:unconfirmed_notification_target_user) { create(:notification_target_user, :unconfirmed, user: user) }

            before do
              visit notification_target_users_path
            end

            it "通知対象ユーザーの登録用リンクが非活性であること" do
              # 登録リンクにdisabledクラスが付与されていることを確認
              expect(page).to have_link("登録", href: new_notification_target_user_path, class: "disabled")
            end
          end
        end
      end
    end

    describe "new" do
      let(:user) { create(:user) }

      context "サインインしている場合" do
        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
          visit new_notification_target_user_path
        end

        include_examples "ユーザー情報の表示テスト"

        # ナビゲーションのテスト用変数
        let(:navigation_content) { "通知メールアドレスを登録するよ！" }

        include_examples "ナビゲーションのテスト"

        it "ページタイトルが表示されること" do
          expect(page).to have_selector("h1", text: "通知メール登録")
        end

        it "通知メールアドレス一覧に戻るリンクが存在すること" do
          expect(page).to have_link("通知メールアドレス一覧 にもどる", href: notification_target_users_path)
        end

        it "通知メールアドレス一覧に戻るリンクをクリックして通知メールアドレス一覧一覧ページに遷移すること" do
          click_link "通知メールアドレス一覧 にもどる"

          expect(page).to have_http_status(:success)
          expect(current_path).to eq notification_target_users_path
        end

        it "通知対象ユーザーの登録フォームが表示されること" do
          expect(page).to have_selector("h2", text: "登録情報の入力")
          expect(page).to have_field("ニックネーム")
          expect(page).to have_field("Eメールアドレス")
          expect(page).to have_button("登録")
        end

        # ヘルプモーダルの基本機能テスト用変数
        let(:page_title) { "通知メール登録" }

        include_examples "ヘルプモーダルの基本機能テスト"

        it "ヘルプモーダル内の主な項目が正しく表示されること" do
          within "#helpModal.modal" do
            expect(page).to have_selector("h3", text: "フォームについて")
            expect(page).to have_selector("h4", text: "入力項目の説明")
            expect(page).to have_selector("h5", text: "ニックネーム")
            expect(page).to have_selector("h5", text: "Eメールアドレス")
            expect(page).to have_selector("h3", text: "ボタンについて")
            expect(page).to have_selector("h4", text: "各ボタンの説明")
            expect(page).to have_selector("div.btn", text: "登録")
            expect(page).to have_selector("h5", text: "登録ボタン")
          end
        end
      end

      context "サインインしていない場合" do
        before do
          visit new_notification_target_user_path
        end

        include_examples "非ログイン状態で認可が必要なページにアクセスした時のリダイレクトテスト"
      end
    end

    describe "confirm_email" do
      let(:user) { create(:user) }

      context "確認メールの期限が切れていない場合" do
        let!(:notification_target_user) { create(:notification_target_user, :unconfirmed, user: user) }

        before do
          # 確認メールのURLからのアクセスをシミュレート
          visit confirm_email_notification_target_users_path(token: notification_target_user.confirmation_token)
        end

        it "ページタイトルが表示されること" do
          expect(page).to have_selector("h1", text: "メールアドレス認証")
        end

        it "メールアドレス認証が完了のメッセージが表示されること" do
          expect(page).to have_selector("h2", text: "メールアドレス認証が完了しました")
        end

        it "通知対象ユーザーのニックネームが文章内に表示されていること" do
          within "p.ce-info-text" do
            have_content "#{notification_target_user.name} さんのメールアドレス"
            have_content "このアプリで記録したお買い物の内容が #{notification_target_user.name} さん にメールで通知されます。"
          end
        end

        it "通知対象ユーザーのEメールアドレスが文章内に表示されていること" do
          within "p.ce-info-text" do
            have_content "#{notification_target_user.email} が認証されました。"
          end
        end

        it "通知対象ユーザーを登録したユーザーのニックネームが文章内に表示されていること" do
          within "p.ce-info-text" do
            have_content "今後、#{user.name} さん がこのアプリで記録したお買い物の内容が"
          end
        end
      end

      context "確認メールの期限が切れている場合" do
        let!(:notification_target_user) { create(:notification_target_user, :unconfirmed, user: user) }
        let(:email_confirmation_limit) { NotificationTargetUser::EMAIL_CONFIRMATION_LIMIT }

        before do
          # 確認メールの有効期限を過ぎてから認証ページにアクセスする
          travel_to(Time.current + email_confirmation_limit.minutes + 1.second) do
            # 確認メールのURLからのアクセスをシミュレート
            visit confirm_email_notification_target_users_path(token: notification_target_user.confirmation_token)
          end
        end

        it "ページタイトルが表示されること" do
          expect(page).to have_selector("h1", text: "メールアドレス認証")
        end

        it "メールアドレス認証失敗のメッセージが表示されること" do
          expect(page).to have_selector("h2", text: "メールアドレスが認証できませんでした")
        end

        it "通知対象ユーザーを登録したユーザーのニックネームが文章内に表示されていること" do
          within "p.ce-info-text" do
            have_content "#{user.name} さん に確認メールを再送信してもらい、受信したメールから再度メールアドレス認証をお願いいたします。"
          end
        end
      end

      context "確認メールのURL以外でアクセスした場合" do
        before do
          # クエリパラメータに不正な認証トークンをセットしてビューにアクセスする
          visit confirm_email_notification_target_users_path(token: "invalid_token")
        end

        it "rootページにリダイレクトされること" do
          within ".alert" do
            expect(page).to have_content "メールアドレス認証以外でのアクセスは禁止されています。"
          end

          expect(current_path).to eq root_path
        end
      end
    end
  end

  describe "通知対象ユーザー登録のフロー" do
    let(:user) { create(:user) }
    let(:email_confirmation_limit) { NotificationTargetUser::EMAIL_CONFIRMATION_LIMIT }

    before do
      sign_in_as(user)
      # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
      expect(page).to have_content "ログインしました。"
      visit new_notification_target_user_path
    end

    context "正常系" do
      scenario "ユーザーが通知対象ユーザーを登録する" do
        expect do
          fill_in "ニックネーム", with: "テスト通知ユーザー"
          fill_in "Eメールアドレス", with: "test-notification-target-user@example.com"
          # 非同期のメール送信を即時実行する
          perform_enqueued_jobs do
            click_button "登録"
            expect(page).to have_content "登録したメールアドレスへ確認メールを送信しました。確認メールの認証の有効期限は#{email_confirmation_limit}分です。"
            expect(current_path).to eq notification_target_users_path
          end
        end.to change { NotificationTargetUser.count }.by(1)

        notification_target_user = NotificationTargetUser.last
        expect(notification_target_user.name).to eq "テスト通知ユーザー"
        expect(notification_target_user.email).to eq "test-notification-target-user@example.com"
        expect(notification_target_user.confirmation_status).to eq "unconfirmed"
      end
    end

    context "異常系" do
      let(:valid_name) { "テストユーザー" }
      let(:valid_email) { "valid-email@example.test" }

      scenario "必須フィールドが空の状態で通知対象ユーザーの登録を試みる" do
        expect do
          fill_in "ニックネーム", with: ""
          fill_in "Eメールアドレス", with: ""
          click_button "登録"
          expect(page).to have_content "ニックネームを入力してください。"
          expect(page).to have_content "Eメールアドレスを入力してください。"
        end.to_not change { NotificationTargetUser.count }
      end

      let(:over_length_name) { "a" * 21 }

      scenario "ニックネームの文字数がオーバーしている状態で通知対象ユーザー登録を試みる" do
        expect do
          fill_in "ニックネーム", with: over_length_name
          fill_in "Eメールアドレス", with: valid_email
          click_button "登録"
          expect(page).to have_content "ニックネームは#{NotificationTargetUser::MAX_LENGTH_NAME}文字以内で入力してください。"
        end.to_not change { NotificationTargetUser.count }
      end

      scenario "既にユーザーが登録済みのメールアドレスで通知対象ユーザー登録を試みる" do
        existing_nt_user = create(:notification_target_user, user: user)

        expect do
          fill_in "ニックネーム", with: valid_name
          fill_in "Eメールアドレス", with: existing_nt_user.email
          click_button "登録"
          expect(page).to have_content "Eメールアドレスは既に登録されています。"
        end.to_not change { NotificationTargetUser.count }
      end

      let(:over_length_email) { "#{"a" * 244}@example.com" }

      scenario "メールアドレスの文字数がオーバーしている状態で通知対象ユーザー登録を試みる" do
        expect do
          fill_in "ニックネーム", with: valid_name
          fill_in "Eメールアドレス", with: over_length_email
          click_button "登録"
          expect(page).to have_content "Eメールアドレスは#{NotificationTargetUser::MAX_LENGTH_EMAIL}文字以内で入力してください。"
        end.to_not change { NotificationTargetUser.count }
      end

      scenario "メールアドレスのフォーマットが正しくない状態でユーザー登録を試みる" do
        expect do
          fill_in "ニックネーム", with: valid_name
          fill_in "Eメールアドレス", with: "invalid-email"
          click_button "登録"
          expect(page).to have_content "Eメールアドレスは不正な値です。"
        end.to_not change { NotificationTargetUser.count }
      end
    end
  end

  describe "通知対象ユーザー認証のフロー", js: true do
    let(:user) { create(:user) }
    let(:email_confirmation_limit) { NotificationTargetUser::EMAIL_CONFIRMATION_LIMIT }
    let(:added_notification_target_user) { NotificationTargetUser.last }
    # ユーザーのログアウト処理にマスター管理ユーザーが必要
    let!(:master_user) { create(:user, :master_admin) }

    before do
      sign_in_as(user)
      # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
      expect(page).to have_content "ログインしました。"

      # ユーザーの通知対象ユーザー登録のシミュレート
      visit new_notification_target_user_path
      expect do
        fill_in "ニックネーム", with: "テスト通知ユーザー"
        fill_in "Eメールアドレス", with: "test-notification-target-user@example.com"
        # 非同期のメール送信を即時実行する
        perform_enqueued_jobs do
          click_button "登録"
          expect(page).to have_content "登録したメールアドレスへ確認メールを送信しました。確認メールの認証の有効期限は#{email_confirmation_limit}分です。"
          expect(current_path).to eq notification_target_users_path
        end
      end.to change { NotificationTargetUser.count }.by(1)

      expect(added_notification_target_user.name).to eq "テスト通知ユーザー"
      expect(added_notification_target_user.email).to eq "test-notification-target-user@example.com"
      expect(added_notification_target_user.confirmation_status).to eq "unconfirmed"

      # このあとは通知対象ユーザー側の操作となるため
      # 親ユーザーをログアウトさせて擬似的に別のセッションとする
      within "nav" do
        click_button "ログアウト"
      end
      expect(page).to have_selector("#turbo-confirm-modal", visible: true)
      within "#turbo-confirm-modal" do
        click_button "ログアウトする"
      end
      expect(page).to have_content "ログアウトしました。"
    end

    scenario "通知対象ユーザーが確認メールから認証を実施する" do
      # 通知対象ユーザーが確認メールを取得し認証用URLをクリックする操作のシミュレート
      email = ActionMailer::Base.deliveries.last
      expect(email.to).to include "test-notification-target-user@example.com"
      expect(email.subject).to eq "メールアドレス認証のお願い"
      confirmation_link = email.body.encoded.match(/(https?:\/\/[^\s]+)/)[0]
      # js: trueのテストではリモートのブラウザでテストが実行されるため
      # 確認メールのURLのホスト名を"localhost"からリモートのホスト名に置き換える必要がある
      confirmation_link.sub!("localhost", Capybara.server_host)

      # リンクのクリックによる認証と完了ページの表示
      expect do
        visit confirmation_link
        expect(page).to have_selector("h1", text: "メールアドレス認証")
        expect(page).to have_selector("h2", text: "メールアドレス認証が完了しました")
      end.to change { added_notification_target_user.reload.confirmation_status }.from("unconfirmed").to("confirmed")
    end

    scenario "確認メールの期限が切れた状態で通知対象ユーザーが認証を試みる" do
      # 通知対象ユーザーが確認メールを取得し認証用URLをクリックする操作のシミュレート
      email = ActionMailer::Base.deliveries.last
      expect(email.to).to include "test-notification-target-user@example.com"
      expect(email.subject).to eq "メールアドレス認証のお願い"
      confirmation_link = email.body.encoded.match(/(https?:\/\/[^\s]+)/)[0]
      # js: trueのテストではリモートのブラウザでテストが実行されるため
      # 確認メールのURLのホスト名を"localhost"からリモートのホスト名に置き換える必要がある
      confirmation_link.sub!("localhost", Capybara.server_host)

      # 期限切れの確認メールのリンクのクリックによるページの表示
      travel_to(Time.current + email_confirmation_limit.minutes + 1.second) do
        expect do
          visit confirmation_link
          expect(page).to have_selector("h1", text: "メールアドレス認証")
          expect(page).to have_selector("h2", text: "メールアドレスが認証できませんでした")
        end.to_not change { added_notification_target_user.reload.confirmation_status }
      end
    end
  end

  describe "確認メール再送信のフロー" do
    let(:user) { create(:user) }
    let(:email_confirmation_limit) { NotificationTargetUser::EMAIL_CONFIRMATION_LIMIT }
    let!(:notification_target_user) { create(:notification_target_user, :unconfirmed, user: user) }

    before do
      # 確認メールの期限が切れた状態で実行
      travel_to(Time.current + email_confirmation_limit.minutes + 1.second) do
        # 期限切れにより認証ができないことを確認
        expect do
          visit confirm_email_notification_target_users_path(token: notification_target_user.confirmation_token)
          expect(page).to have_selector("h1", text: "メールアドレス認証")
          expect(page).to have_selector("h2", text: "メールアドレスが認証できませんでした")
        end.to_not change { notification_target_user.reload.confirmation_status }

        # ユーザーの操作
        sign_in_as(user)
        # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
        expect(page).to have_content "ログインしました。"
        visit notification_target_users_path
      end
    end

    scenario "ユーザーが通知対象ユーザーに確認メールを再送する" do
      # 確認メールの期限が切れた状態で実行
      travel_to(Time.current + email_confirmation_limit.minutes + 1.second) do
        expect do
          # 非同期のメール送信を即時実行する
          perform_enqueued_jobs do
            within("div.shopping-record-bg", text: notification_target_user.name) do
              click_link "確認メール再送信"
            end
          end
          # 認証トークンの更新を確認
        end.to change { notification_target_user.reload.confirmation_token }

        expect(page).to have_content(
          "#{notification_target_user.email} へ確認メールを再送信しました。" \
          "確認メールの認証の有効期限は#{email_confirmation_limit}分です。"
        )

        # 確認メール送信確認
        email = ActionMailer::Base.deliveries.last
        expect(email.to).to include notification_target_user.email
        expect(email.subject).to eq "メールアドレス認証のお願い"
        # URLのトークン部分が更新されていることを確認
        confirmation_link = email.body.encoded.match(/(https?:\/\/[^\s]+)/)[0]
        expect(confirmation_link).to include notification_target_user.confirmation_token
      end
    end
  end

  describe "通知対象ユーザー削除のフロー" do
    let(:user) { create(:user) }
    let!(:notification_target_user) { create(:notification_target_user, user: user) }

    before do
      sign_in_as(user)
      # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
      expect(page).to have_content "ログインしました。"
      visit notification_target_users_path
    end

    scenario "ユーザーが通知対象ユーザーを削除する", js: true do
      within("div.shopping-record-bg", text: notification_target_user.name) do
        # 登録済み通知対象ユーザーの表示を確認
        expect(page).to have_selector("h5", text: notification_target_user.email)

        find("i.delete-icon").click
      end

      expect do
        within "#turbo-confirm-modal" do
          click_button "削除する"
        end

        within ".alert" do
          expect(page).to have_content "通知対象ユーザーが削除されました。"
        end
      end.to change { NotificationTargetUser.count }.by(-1)

      # 通知対象ユーザーがDBに存在しないことを確認
      expect(NotificationTargetUser.where(id: notification_target_user.id)).to_not exist
    end
  end
end
