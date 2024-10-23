require 'rails_helper'

RSpec.describe "UserRegistrations", type: :system do
  describe "ビューの要素" do
    describe "new" do
      context "サインインしていない場合" do
        before do
          visit new_user_registration_path
        end

        it "ページタイトルが表示されていること" do
          expect(page).to have_selector("h1", text: "ユーザー登録")
        end

        it "ユーザー登録フォームが表示されること" do
          within "form.new_user" do
            expect(page).to have_selector("h2", text: "登録情報の入力")
            expect(page).to have_field("ニックネーム")
            expect(page).to have_field("Eメールアドレス")
            # ラベルは部分一致するためIDを指定
            expect(page).to have_field("user_password", exact: true)
            expect(page).to have_field("user_password_confirmation", exact: true)
            # Recaptchaの表示を確認
            expect(page).to have_css("div.g-recaptcha")
            expect(page).to have_button("ユーザー登録")
          end
        end

        it "登録済みのユーザー向けのログイン画面へのリンクが存在すること" do
          within ".form-other-bg" do
            expect(page).to have_link("ログイン", href: new_user_session_path)
          end
        end

        it "登録済みのユーザー向けのログインのリンクでログイン画面に遷移すること" do
          within ".form-other-bg" do
            click_link "ログイン"
          end

          expect(page).to have_http_status(:success)
          expect(current_path).to eq new_user_session_path
        end

        it "確認メール再送画面へのリンクが存在すること" do
          within ".form-other-bg" do
            expect(page).to have_link("アカウント確認のメールを受け取っていませんか？", href: new_user_confirmation_path)
          end
        end

        it "確認メール再送画面へのリンクで確認メール再送画面に遷移すること" do
          within ".form-other-bg" do
            click_link "アカウント確認のメールを受け取っていませんか？"
          end

          expect(page).to have_http_status(:success)
          expect(current_path).to eq new_user_confirmation_path
        end
      end

      context "サインインしている場合" do
        let(:user) { create(:user) }

        before do
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
          visit new_user_registration_path
        end

        include_examples "ログイン状態で非ログイン専用ページにアクセスした時のリダイレクトテスト"
      end
    end

    describe "edit" do
      context "サインインしている場合" do
        # コントローラー側でマスター管理ユーザーのインスタンスを取得するため
        let!(:master_user) { create(:user, :master_admin) }

        shared_examples "編集画面の共通テスト" do
          include_examples "ユーザー情報の表示テスト"

          # ナビゲーションのテスト用変数
          let(:navigation_content) { "ユーザーアカウントの設定を変更できるよ！" }

          include_examples "ナビゲーションのテスト"

          it "ページタイトルが表示されること" do
            expect(page).to have_selector("h1", text: "ユーザー設定")
          end

          it "メインメニューに戻るリンクが存在すること" do
            expect(page).to have_link("メインメニュー にもどる", href: root_path)
          end

          it "メインメニューに戻るリンクをクリックしてrootページに遷移すること" do
            click_link "メインメニュー にもどる"

            expect(page).to have_http_status(:success)
            expect(current_path).to eq root_path
          end

          it "ユーザー編集フォームが表示されること" do
            within "form.edit_user" do
              expect(page).to have_selector("h2", text: "ユーザー情報の編集")
              expect(page).to have_field("ニックネーム")
              expect(page).to have_field("Eメールアドレス")
              # 活性・非活性を問わないパスワード・確認用フィールドの表示をテストする
              expect(page).to have_selector("input#user_password")
              expect(page).to have_selector("label[for='user_password']", text: "パスワード")
              expect(page).to have_selector("input#user_password_confirmation")
              expect(page).to have_selector("label[for='user_password_confirmation']", text: "パスワード（確認用）")
              expect(page).to have_field("使う", type: "radio", with: "true")
              expect(page).to have_field("使わない", type: "radio", with: "false")
              expect(page).to have_button("更新")
            end
          end

          it "デフォルトでニックネームのフィールドに現在のニックネームが入力されていること" do
            expect(page).to have_field("ニックネーム", with: user.name)
          end

          it "デフォルトでEメールアドレスのフィールドに現在のEメールアドレスが入力されていること" do
            expect(page).to have_field("Eメールアドレス", with: user.email)
          end

          it "ユーザーアカウントの削除の項目が表示されること" do
            expect(page).to have_selector("h2", text: "ユーザーアカウントの削除")
          end

          it "ユーザーアカウントの削除ボタンが存在すること" do
            # 活性・非活性を問わないアカウント削除ボタンの表示をテストする
            expect(page).to have_selector("button", text: "アカウント削除")
          end
        end

        shared_examples "Eメールアドレスのフィールド活性確認" do
          it "編集フォームのEメールアドレスのフィールドがreadonlyではないこと" do
            expect(page).to have_field("Eメールアドレス", readonly: false)
          end
        end

        shared_examples "Eメールアドレスのフィールドの非活性確認" do
          it "編集フォームのEメールアドレスのフィールドがreadonlyであること" do
            expect(page).to have_field("Eメールアドレス", readonly: true)
          end
        end

        shared_examples "パスワードのフィールドの活性確認" do
          it "パスワードのフィールドがdisabledではないこと" do
            # パスワード（確認用）と部分一致しないようIDを指定
            expect(page).to have_field("user_password", disabled: false, exact: true)
          end

          it "パスワード（確認用）のフィールドがdisabledではないこと" do
            # パスワードと部分一致しないようIDを指定
            expect(page).to have_field("user_password_confirmation", disabled: false, exact: true)
          end
        end

        shared_examples "パスワードのフィールドの非活性確認" do
          it "パスワードのフィールドがdisabledであること" do
            # パスワード（確認用）と部分一致しないようIDを指定
            expect(page).to have_field("user_password", disabled: true, exact: true)
          end

          it "パスワード（確認用）のフィールドがdisabledであること" do
            # パスワードと部分一致しないようIDを指定
            expect(page).to have_field("user_password_confirmation", disabled: true, exact: true)
          end
        end

        shared_examples "アカウント削除ボタンの活性確認" do
          it "アカウント削除ボタンがdisabledではないこと" do
            expect(page).to have_button("アカウント削除", disabled: false)
          end
        end

        shared_examples "アカウント削除ボタンの非活性確認" do
          it "アカウント削除ボタンがdisabledであること" do
            expect(page).to have_button("アカウント削除", disabled: true)
          end
        end

        shared_examples "ヘルプモーダルの共通テスト" do
          # ヘルプモーダルの基本機能テスト用変数
          let(:page_title) { "ユーザー設定" }

          include_examples "ヘルプモーダルの基本機能テスト"

          it "ヘルプモーダル内の主な項目が正しく表示されること" do
            within "#helpModal.modal" do
              expect(page).to have_selector("h3", text: "フォームについて")
              expect(page).to have_selector("h4", text: "入力項目の説明")
              expect(page).to have_selector("h5", text: "ニックネーム")
              expect(page).to have_selector("h5", text: "Eメールアドレス")
              expect(page).to have_selector("h5", text: "パスワード")
              expect(page).to have_selector("h5", text: "パスワード（確認用）")
              expect(page).to have_selector("h5", text: "ひらがなモード")
              expect(page).to have_selector("h3", text: "ボタンについて")
              expect(page).to have_selector("h4", text: "各ボタンの説明")
              expect(page).to have_selector("div.btn", text: "更新")
              expect(page).to have_selector("h5", text: "更新ボタン")
              expect(page).to have_selector("div.btn", text: "アカウント削除")
              expect(page).to have_selector("h5", text: "アカウント削除ボタン")
            end
          end
        end

        shared_examples "ヘルプモーダルのゲストユーザー向け項目非表示のテスト" do
          it "ヘルプモーダル内にゲストユーザー向けの表示項目が表示されないこと" do
            within "#helpModal.modal" do
              expect(page).to have_no_selector("h3", text: "ゲストユーザーの編集制限")
            end
          end
        end

        context "一般ユーザーの場合" do
          let(:user) { create(:user) }

          before do
            sign_in_as(user)
            # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
            expect(page).to have_content "ログインしました。"
            visit edit_user_registration_path
          end

          it_behaves_like "編集画面の共通テスト"

          it_behaves_like "Eメールアドレスのフィールド活性確認"

          it_behaves_like "パスワードのフィールドの活性確認"

          it_behaves_like "アカウント削除ボタンの活性確認"

          it "アカウント削除ボタンをクリックするとモーダルが表示されること", js: true do
            expect(page).to have_selector("#turbo-confirm-modal", visible: false)

            click_button "アカウント削除"

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)
          end

          it "アカウント削除モーダルにタイトルが表示されること", js: true do
            click_button "アカウント削除"

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            within "#turbo-confirm-modal" do
              expect(page).to have_selector("h1", visible: true, text: "アカウントの削除")
            end
          end

          it "アカウント削除モーダルのヘッダーにモーダルを閉じるボタンがあること", js: true do
            click_button "アカウント削除"

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            within "#turbo-confirm-modal" do
              within ".modal-header" do
                expect(page).to have_selector("button.btn-close", visible: true)
              end
            end
          end

          it "アカウント削除モーダルに削除ボタン・キャンセルボタンが表示されること", js: true do
            click_button "アカウント削除"

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            within "#turbo-confirm-modal" do
              expect(page).to have_selector("button", visible: true, text: "削除する")
              expect(page).to have_selector("button", visible: true, text: "キャンセル")
            end
          end

          it "アカウント削除モーダルのキャンセルボタンでアカウント削除を中止できること", js: true do
            click_button "アカウント削除"

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            within "#turbo-confirm-modal" do
              click_button "キャンセル"
            end

            expect(page).to have_selector("#turbo-confirm-modal", visible: false)
          end

          it "アカウント削除モーダルの外をクリックするとモーダルが閉じること", js: true do
            click_button "アカウント削除"

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            # モーダルの外をクリック
            page.execute_script("document.querySelector('body').click();")

            expect(page).to have_selector("#turbo-confirm-modal", visible: false)
          end

          it "アカウント削除ボタンからユーザーアカウントが削除できること", js: true do
            click_button "アカウント削除"

            expect(page).to have_selector("#turbo-confirm-modal", visible: true)

            expect do
              within "#turbo-confirm-modal" do
                click_button "削除する"
              end

              within ".alert" do
                expect(page).to have_content "アカウントを削除しました。またのご利用をお待ちしております。"
              end

              expect(current_path).to eq root_path

              within "nav" do
                expect(page).to have_link("ログイン", href: new_user_session_path)
              end
            end.to change { User.count }.by(-1)

            # ユーザーがDBに存在しないことを確認
            expect(User.where(id: user.id)).to_not exist
          end

          it_behaves_like "ヘルプモーダルの共通テスト"

          it_behaves_like "ヘルプモーダルのゲストユーザー向け項目非表示のテスト"
        end

        context "管理ユーザーの場合" do
          let(:user) { create(:user, :admin) }

          before do
            sign_in_as(user)
            # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
            expect(page).to have_content "ログインしました。"
            visit edit_user_registration_path
          end

          it_behaves_like "編集画面の共通テスト"

          it_behaves_like "Eメールアドレスのフィールド活性確認"

          it_behaves_like "パスワードのフィールドの活性確認"

          it_behaves_like "アカウント削除ボタンの活性確認"

          it_behaves_like "ヘルプモーダルの共通テスト"

          it_behaves_like "ヘルプモーダルのゲストユーザー向け項目非表示のテスト"
        end

        context "マスター管理ユーザーの場合" do
          let(:user) { master_user }

          before do
            sign_in_as(user)
            # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
            expect(page).to have_content "ログインしました。"
            visit edit_user_registration_path
          end

          it_behaves_like "編集画面の共通テスト"

          it_behaves_like "Eメールアドレスのフィールドの非活性確認"

          it_behaves_like "パスワードのフィールドの活性確認"

          it_behaves_like "アカウント削除ボタンの非活性確認"

          it_behaves_like "ヘルプモーダルの共通テスト"

          it_behaves_like "ヘルプモーダルのゲストユーザー向け項目非表示のテスト"
        end

        context "ゲストユーザーの場合" do
          let(:user) { User.guest }

          before do
            # ゲストユーザーボタンからログイン
            visit root_path
            within "nav" do
              click_button "ゲストログイン"
            end
            expect(page).to have_content "ゲストユーザーとしてログインしました。"
            visit edit_user_registration_path
          end

          it_behaves_like "編集画面の共通テスト"

          it "編集フォームのニックネームのフィールドがreadonlyであること" do
            expect(page).to have_field("ニックネーム", readonly: true)
          end

          it_behaves_like "Eメールアドレスのフィールドの非活性確認"

          it_behaves_like "パスワードのフィールドの非活性確認"

          it_behaves_like "アカウント削除ボタンの非活性確認"

          it_behaves_like "ヘルプモーダルの共通テスト"

          it "ヘルプモーダル内にゲストユーザー向けの表示項目が存在すること" do
            expect(page).to have_selector("h3", text: "ゲストユーザーの編集制限")
          end
        end
      end

      context "サインインしていない場合" do
        before do
          visit edit_user_registration_path
        end

        include_examples "非ログイン状態で認可が必要なページにアクセスした時のリダイレクトテスト"
      end
    end
  end

  describe "ユーザー登録のフロー" do
    context "正常系" do
      let(:user_name) { "テストユーザー" }
      let(:user_email) { "registration@example.test" }
      let(:user_password) { "testpass123" }
      # フローの中でconfirm関連カラムのupdateがされるため
      # before_updateメソッドの処理にマスター管理ユーザーが必要
      let!(:master_user) { create(:user, :master_admin) }

      scenario "ユーザーアカウントを登録してアクティベートする" do
        expect do
          visit new_user_registration_path
          fill_in "ニックネーム", with: user_name
          fill_in "Eメールアドレス", with: user_email
          # パスワード関連のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "user_password", with: user_password
          fill_in "user_password_confirmation", with: user_password
          click_button "ユーザー登録"
        end.to change { User.count }.by(1)

        expect(page).to have_content "本人確認用のメールを送信しました。メール内のリンクからアカウントを有効化させてください。"

        # 認証メール送信確認
        email = ActionMailer::Base.deliveries.last
        expect(email.to).to include user_email
        expect(email.subject).to eq "メールアドレス確認メール"

        # メール内のURLからアカウント有効化
        confirmation_link = email.body.match(/(https?:\/\/[^\s]+)/)[0]
        visit confirmation_link

        expect(page).to have_content "メールアドレスが確認できました。"
        expect(current_path).to eq new_user_session_path
        expect(User.find_by(email: user_email).confirmed_at).not_to be_nil
      end
    end

    context "異常系" do
      let(:valid_name) { "テストユーザー" }
      let(:valid_email) { "registration@example.test" }
      let(:valid_password) { "testpass123" }

      before do
        visit new_user_registration_path
      end

      scenario "必須フィールドが空の状態でユーザー登録を試みる" do
        expect do
          click_button "ユーザー登録"
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
          click_button "ユーザー登録"
        end.to_not change { User.count }

        expect(page).to have_content "ニックネームは#{User::MAX_LENGTH_NAME}文字以内で入力してください。"
      end

      scenario "既に登録済みのメールアドレスでユーザー登録を試みる" do
        existing_user = create(:user)

        expect do
          fill_in "ニックネーム", with: valid_name
          fill_in "Eメールアドレス", with: existing_user.email
          # パスワード関連のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "user_password", with: valid_password
          fill_in "user_password_confirmation", with: valid_password
          click_button "ユーザー登録"
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
          click_button "ユーザー登録"
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
          click_button "ユーザー登録"
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
          click_button "ユーザー登録"
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
          click_button "ユーザー登録"
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
          click_button "ユーザー登録"
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
          click_button "ユーザー登録"
        end.to_not change { User.count }

        expect(page).to have_content "パスワード（確認用）とパスワードの入力が一致しません。"
      end

      scenario "メール認証の有効期限が切れた状態でアカウントのアクティベートをしようとする" do
        expect do
          fill_in "ニックネーム", with: valid_name
          fill_in "Eメールアドレス", with: valid_email
          # パスワード関連のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "user_password", with: valid_password
          fill_in "user_password_confirmation", with: valid_password
          click_button "ユーザー登録"
        end.to change { User.count }.by(1)

        expect(page).to have_content "本人確認用のメールを送信しました。メール内のリンクからアカウントを有効化させてください。"

        # 認証メール送信確認
        email = ActionMailer::Base.deliveries.last
        expect(email.to).to include valid_email
        expect(email.subject).to eq "メールアドレス確認メール"

        # Deviseに設定している有効期限
        confirmation_expiration = 6.hours

        # 期限を過ぎた状態にする
        travel_to(Time.current + confirmation_expiration + 1.second) do
          # メール内のURLからアカウント有効化
          confirmation_link = email.body.match(/(https?:\/\/[^\s]+)/)[0]
          visit confirmation_link

          # URLの有効期限切れと未アクティベート状態を確認
          expect(page).to have_content "Eメールアドレスの期限が切れました。約6時間 以内に確認する必要があります。 新しくリクエストしてください。"
          expect(User.find_by(email: valid_email).confirmed_at).to be_nil
        end
      end
    end
  end

  describe "ユーザー編集のフロー" do
    shared_examples "ユーザー編集の共通テスト 正常系" do
      let(:new_name) { "新しいユーザー名" }
      let(:new_password) { "newPass123" }

      scenario "ユーザーがニックネームを更新する" do
        before_name = user.name
        expect do
          fill_in "ニックネーム", with: new_name
          click_button "更新"
        end.to change { user.reload.name }.from(before_name).to(new_name)

        expect(current_path).to eq root_path
        expect(page).to have_content "アカウント情報を変更しました。"
      end

      scenario "ユーザーがパスワードを更新する" do
        expect(user.valid_password?("password123")).to be_truthy

        expect do
          # パスワード関連のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "user_password", with: new_password
          fill_in "user_password_confirmation", with: new_password
          click_button "更新"
        end.to change { user.reload.encrypted_password }
        expect(user.valid_password?(new_password)).to be_truthy

        expect(current_path).to eq root_path
        expect(page).to have_content "アカウント情報を変更しました。"
      end

      scenario "パスワードとパスワード（確認用）のフィールドが空だとパスワードが更新されない" do
        expect do
          # パスワード関連のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "user_password", with: ""
          fill_in "user_password_confirmation", with: ""
          click_button "更新"
        end.to_not change { user.reload.encrypted_password }
        expect(user.valid_password?("password123")).to be_truthy
      end
    end

    shared_examples "ひらがなモードの変更" do
      scenario "ユーザーがひらがなモードを変更する" do
        expect do
          choose "使う"
          click_button "更新"
        end.to change { user.reload.hiragana_view }.from(false).to(true)

        expect(current_path).to eq root_path
        expect(page).to have_content "アカウント情報を変更しました。"
      end
    end

    shared_examples "ユーザー編集の共通テスト 異常系" do
      scenario "ニックネームが空の状態で更新を試みる" do
        expect do
          fill_in "ニックネーム", with: ""
          click_button "更新"
        end.to_not change { user.reload.name }

        expect(current_path).to eq user_registration_path
        expect(page).to have_content "ニックネームを入力してください。"
        expect(page).to have_selector("h2", text: "ユーザー情報の編集")
      end

      let(:over_length_name) { "a" * 21 }

      scenario "ニックネームの文字数がオーバーしている状態で更新を試みる" do
        expect do
          fill_in "ニックネーム", with: over_length_name
          click_button "更新"
        end.to_not change { user.reload.name }

        expect(current_path).to eq user_registration_path
        expect(page).to have_content "ニックネームは#{User::MAX_LENGTH_NAME}文字以内で入力してください。"
        expect(page).to have_selector("h2", text: "ユーザー情報の編集")
      end

      let(:lack_length_password) { "pass123" }

      scenario "パスワードの文字数が不足している状態で更新を試みる" do
        expect do
          # パスワード関連のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "user_password", with: lack_length_password
          fill_in "user_password_confirmation", with: lack_length_password
          click_button "更新"
        end.to_not change { user.reload.encrypted_password }

        expect(current_path).to eq user_registration_path
        expect(page).to have_content "パスワードは#{Devise.password_length.min}文字以上で入力してください。"
        expect(page).to have_selector("h2", text: "ユーザー情報の編集")
      end

      let(:over_length_password) { "Ab1" * 43 } # 129文字

      scenario "パスワードの文字数がオーバーしている状態で更新を試みる" do
        expect do
          # パスワード関連のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "user_password", with: over_length_password
          fill_in "user_password_confirmation", with: over_length_password
          click_button "更新"
        end.to_not change { user.reload.encrypted_password }

        expect(current_path).to eq user_registration_path
        expect(page).to have_content "パスワードは#{Devise.password_length.max}文字以内で入力してください"
        expect(page).to have_selector("h2", text: "ユーザー情報の編集")
      end

      let(:invalid_password) { "password" }

      scenario "パスワードのフォーマットが正しくない状態で更新を試みる" do
        expect do
          # パスワード関連のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "user_password", with: invalid_password
          fill_in "user_password_confirmation", with: invalid_password
          click_button "更新"
        end.to_not change { user.reload.encrypted_password }

        expect(current_path).to eq user_registration_path
        expect(page).to have_content "パスワードは不正な値です。"
        expect(page).to have_selector("h2", text: "ユーザー情報の編集")
      end
    end

    context "一般ユーザーの場合" do
      let(:user) do
        create(:user, name: "テストユーザー", email: "test-user@example.test", password: "password123", hiragana_view: false)
      end
      # フローの中でupdate処理、ビューの表示にマスター管理ユーザーが必要
      let!(:master_user) { create(:user, :master_admin) }
      let(:new_email) { "new-test-user@example.test" }

      before do
        sign_in_as(user)
        expect(page).to have_content "ログインしました。"
        visit edit_user_registration_path
      end

      context "正常系" do
        it_behaves_like "ユーザー編集の共通テスト 正常系"

        scenario "ユーザーがEメールアドレスを更新する" do
          fill_in "Eメールアドレス", with: new_email
          click_button "更新"

          expect(current_path).to eq root_path
          expect(page).to have_content "アカウント情報を変更しました。変更されたメールアドレスの本人確認のため、本人確認用メールより確認処理をおこなってください。"
          expect(user.reload.unconfirmed_email).to eq new_email

          # 編集ページのEメールアドレスフォームの確認メッセージの確認
          within "nav" do
            click_link "ユーザー設定"
          end
          expect(current_path).to eq edit_user_registration_path
          expect(page).to have_content "#{new_email} の確認待ち"

          # 本人確認メール送信確認
          email = ActionMailer::Base.deliveries.last
          expect(email.to).to include new_email
          expect(email.subject).to eq "メールアドレス確認メール"

          # メール内のURLから新メールアドレスを有効化
          confirmation_link = email.body.match(/(https?:\/\/[^\s]+)/)[0]
          visit confirmation_link

          expect(page).to have_content "メールアドレスが確認できました。"
          expect(current_path).to eq new_user_session_path
          expect(user.reload.unconfirmed_email).to be_nil
        end

        it_behaves_like "ひらがなモードの変更"
      end

      context "異常系" do
        it_behaves_like "ユーザー編集の共通テスト 異常系"

        scenario "メールアドレスが空の状態で更新を試みる" do
          expect do
            fill_in "Eメールアドレス", with: ""
            click_button "更新"
          end.to_not change { user.reload.unconfirmed_email }

          expect(current_path).to eq user_registration_path
          expect(page).to have_content "Eメールアドレスを入力してください。"
          expect(page).to have_selector("h2", text: "ユーザー情報の編集")
        end

        let(:over_length_email) { "#{"a" * 244}@example.com" }

        scenario "メールアドレスの文字数がオーバーしている状態で更新を試みる" do
          expect do
            fill_in "Eメールアドレス", with: over_length_email
            click_button "更新"
          end.to_not change { user.reload.unconfirmed_email }

          expect(current_path).to eq user_registration_path
          expect(page).to have_content "Eメールアドレスは#{User::MAX_LENGTH_EMAIL}文字以内で入力してください。"
          expect(page).to have_selector("h2", text: "ユーザー情報の編集")
        end

        scenario "メールアドレスのフォーマットが正しくない状態で更新を試みる" do
          expect do
            fill_in "Eメールアドレス", with: "invalid-email"
            click_button "更新"
          end.to_not change { user.reload.unconfirmed_email }

          expect(current_path).to eq user_registration_path
          expect(page).to have_content "Eメールアドレスは不正な値です。"
          expect(page).to have_selector("h2", text: "ユーザー情報の編集")
        end
      end
    end

    context "マスター管理ユーザーの場合" do
      let!(:user) { create(:user, :master_admin, name: "テストユーザー", password: "password123", hiragana_view: false) }

      before do
        sign_in_as(user)
        expect(page).to have_content "ログインしました。"
        visit edit_user_registration_path
      end

      context "正常系" do
        it_behaves_like "ユーザー編集の共通テスト 正常系"

        it_behaves_like "ひらがなモードの変更"

        scenario "マスター管理ユーザーはEメールアドレスを変更できない" do
          expect(page).to have_field("Eメールアドレス", with: user.email, readonly: true)

          expect do
            click_button "更新"
          end.to_not change { user.reload.email }
        end
      end

      context "異常系" do
        it_behaves_like "ユーザー編集の共通テスト 異常系"
      end
    end

    context "ゲストユーザーの場合" do
      let(:user) { User.guest }
      # ビューの表示にマスター管理ユーザーが必要
      let!(:master_user) { create(:user, :master_admin) }

      before do
        # ゲストユーザーボタンからログイン
        visit root_path
        within "nav" do
          click_button "ゲストログイン"
        end
        expect(page).to have_content "ゲストユーザーとしてログインしました。"
        visit edit_user_registration_path
      end

      it_behaves_like "ひらがなモードの変更"

      scenario "ゲストユーザーはreadonly、disableのフィールドの属性を変更できない" do
        guest_name = user.name
        guest_email = user.email

        expect(page).to have_field("ニックネーム", readonly: true)
        expect(page).to have_field("Eメールアドレス", readonly: true)
        # パスワード関連のフィールドはラベル文字列だと重複して扱われるためidを指定
        expect(page).to have_field("user_password", exact: true, disabled: true)
        expect(page).to have_field("user_password_confirmation", exact: true, disabled: true)

        click_button "更新"

        user.reload
        expect(user.name).to eq guest_name
        expect(user.email).to eq guest_email
      end
    end
  end

  describe "ユーザーアカウント削除のフロー" do
    context "一般ユーザーの場合" do
      let(:user) { create(:user) }
      # フローの中でupdate処理、ビューの表示にマスター管理ユーザーが必要
      let!(:master_user) { create(:user, :master_admin) }

      before do
        sign_in_as(user)
        expect(page).to have_content "ログインしました。"
        visit edit_user_registration_path
      end

      scenario "ユーザーがアカウントを削除する", js: true do
        click_button "アカウント削除"

        # アカウント削除のconfirmモーダルを確認
        expect(page).to have_selector("#turbo-confirm-modal", visible: true)
        within "#turbo-confirm-modal" do
          expect(page).to have_selector("h1", visible: true, text: "アカウントの削除")
        end

        expect do
          within "#turbo-confirm-modal" do
            click_button "削除する"
          end

          # アカウント削除と同時にログアウトしrootページへリダイレクトする
          within ".alert" do
            expect(page).to have_content "アカウントを削除しました。またのご利用をお待ちしております。"
          end

          expect(current_path).to eq root_path

          within "nav" do
            expect(page).to have_link("ログイン", href: new_user_session_path)
          end
        end.to change { User.count }.by(-1)

        # ユーザーがDBに存在しないことを確認
        expect(User.where(id: user.id)).to_not exist
      end
    end

    context "マスター管理ユーザーの場合" do
      let!(:user) { create(:user, :master_admin) }

      before do
        sign_in_as(user)
        expect(page).to have_content "ログインしました。"
        visit edit_user_registration_path
      end

      scenario "マスター管理ユーザーはアカウントを削除することができない" do
        expect(page).to have_button("アカウント削除", disabled: true)
      end
    end

    context "ゲストユーザーの場合" do
      let(:user) { User.guest }
      # フローの中でupdate処理、ビューの表示にマスター管理ユーザーが必要
      let!(:master_user) { create(:user, :master_admin) }

      before do
        # ゲストユーザーボタンからログイン
        visit root_path
        within "nav" do
          click_button "ゲストログイン"
        end
        expect(page).to have_content "ゲストユーザーとしてログインしました。"
        visit edit_user_registration_path
      end

      scenario "ゲストユーザーはアカウントを削除することができない" do
        expect(page).to have_button("アカウント削除", disabled: true)
      end
    end
  end
end
