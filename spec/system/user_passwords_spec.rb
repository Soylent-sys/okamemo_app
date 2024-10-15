require 'rails_helper'

RSpec.describe "UserPasswords", type: :system do
  describe "ビューの要素" do
    describe "new" do
      context "サインインしていない場合" do
        before do
          visit new_user_password_path
        end

        it "ページタイトルが表示されていること" do
          expect(page).to have_selector("h1", text: "パスワード再設定")
        end

        it "確認メール再送フォームが表示されること" do
          within "form.new_user" do
            expect(page).to have_selector("h2", text: "メールアドレスの入力")
            expect(page).to have_field("Eメールアドレス")
            expect(page).to have_button("パスワード再設定方法の送信")
          end
        end

        it "登録済みユーザー向けのログイン画面へのリンクが存在すること" do
          within ".form-other-bg" do
            expect(page).to have_link("ログイン", href: new_user_session_path)
          end
        end

        it "登録済みユーザー向けのログイン画面へのリンクでログイン画面に遷移すること" do
          within ".form-other-bg" do
            click_link "ログイン"
          end

          expect(page).to have_http_status(:success)
          expect(current_path).to eq new_user_session_path
        end

        it "未登録ユーザー向けのユーザー登録画面へのリンクが存在すること" do
          within ".form-other-bg" do
            expect(page).to have_link("ユーザー登録", href: new_user_registration_path)
          end
        end

        it "未登録ユーザー向けのユーザー登録画面へのリンクでログイン画面に遷移すること" do
          within ".form-other-bg" do
            click_link "ユーザー登録"
          end

          expect(page).to have_http_status(:success)
          expect(current_path).to eq new_user_registration_path
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
          visit new_user_password_path
        end

        include_examples "ログイン状態で非ログイン専用ページにアクセスした時のリダイレクトテスト"
      end
    end

    describe "edit" do
      let(:user) { create(:user) }
      # パスワード再設定メールの送信時にreset_password関連カラムのupdateがされるため
      # before_updateメソッドの処理にマスター管理ユーザーが必要
      let!(:master_user) { create(:user, :master_admin) }

      context "サインインしていない場合" do
        context "リクエスト時にパスワードリセット用トークンのクエリパラメータがある場合" do
          before do
            # パスワード再設定用ページのURLをメール送信して
            # userのreset_password_tokenを設定する
            user.send_reset_password_instructions
            token = user.reload.reset_password_token
            # userのreset_password_tokenをクエリパラメータにパスワード変更ページへアクセス
            visit edit_user_password_path(reset_password_token: token)
          end

          it "ページタイトルが表示されていること" do
            expect(page).to have_selector("h1", text: "パスワード変更")
          end

          it "確認メール再送フォームが表示されること" do
            within "form.new_user" do
              expect(page).to have_selector("h2", text: "パスワードの再設定")
              # ラベルは部分一致するためIDを指定
              expect(page).to have_field("user_password", exact: true)
              expect(page).to have_field("user_password_confirmation", exact: true)
              expect(page).to have_button("パスワード変更")
            end
          end

          it "登録済みユーザー向けのログイン画面へのリンクが存在すること" do
            within ".form-other-bg" do
              expect(page).to have_link("ログイン", href: new_user_session_path)
            end
          end

          it "登録済みユーザー向けのログイン画面へのリンクでログイン画面に遷移すること" do
            within ".form-other-bg" do
              click_link "ログイン"
            end

            expect(page).to have_http_status(:success)
            expect(current_path).to eq new_user_session_path
          end

          it "未登録ユーザー向けのユーザー登録画面へのリンクが存在すること" do
            within ".form-other-bg" do
              expect(page).to have_link("ユーザー登録", href: new_user_registration_path)
            end
          end

          it "未登録ユーザー向けのユーザー登録画面へのリンクでログイン画面に遷移すること" do
            within ".form-other-bg" do
              click_link "ユーザー登録"
            end

            expect(page).to have_http_status(:success)
            expect(current_path).to eq new_user_registration_path
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

        context "リクエスト時にパスワードリセット用トークンのクエリパラメータがない場合" do
          it "ログイン画面にリダイレクトすること" do
            # クエリパラメータを付けずにアクセス
            visit edit_user_password_path

            expect(current_path).to eq new_user_session_path
            expect(page).to have_content "このページにはアクセスできません。パスワード再設定メールのリンクからアクセスされた場合には、URL をご確認ください。"
          end
        end
      end

      context "サインインしている場合" do
        before do
          # パスワード再設定用ページのURLをメール送信して
          # userのreset_password_tokenを設定する
          user.send_reset_password_instructions
          token = user.reload.reset_password_token
          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
          # userのreset_password_tokenをクエリパラメータにパスワード変更ページへアクセス
          visit edit_user_password_path(reset_password_token: token)
        end

        include_examples "ログイン状態で非ログイン専用ページにアクセスした時のリダイレクトテスト"
      end
    end
  end

  describe "パスワードリセットのフロー" do
    context "正常系" do
      let!(:user) { create(:user, password: "password123") }
      # フローの中でreset_password関連カラムのupdateがされるため
      # before_updateメソッドの処理にマスター管理ユーザーが必要
      let!(:master_user) { create(:user, :master_admin) }
      let(:new_password) { "newPass123" }

      scenario "ユーザーのパスワードをリセットする" do
        visit new_user_password_path
        fill_in "Eメールアドレス", with: user.email
        click_button "パスワード再設定方法の送信"

        expect(page).to have_content "メールアドレスが登録済みの場合、パスワード再設定用のメールが数分以内に送信されます。"

        # パスワード再設定メール送信確認
        email = ActionMailer::Base.deliveries.last
        expect(email.to).to include user.email
        expect(email.subject).to eq "パスワードの再設定について"

        # メール内のURLからアカウント有効化
        reset_password_link = email.body.match(/(https?:\/\/[^\s]+)/)[0]
        visit reset_password_link

        expect(user.valid_password?("password123")).to be_truthy

        expect do
          # パスワード関連のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "user_password", with: new_password
          fill_in "user_password_confirmation", with: new_password
          click_button "パスワード変更"
        end.to change { user.reload.encrypted_password }
        expect(current_path).to eq root_path
        expect(page).to have_content "パスワードが正しく変更されました。"
        expect(user.valid_password?(new_password)).to be_truthy
      end
    end

    context "異常系" do
      describe "メールアドレスの入力" do
        let(:guest_user) { User.guest }
        let(:unexist_email) { "unexist-mail@example.test" }

        before do
          visit new_user_password_path
        end

        scenario "登録されていないEメールアドレスでパスワード再設定メールの送信を試みる" do
          expect(User.exists?(email: unexist_email)).to be_falsey
          fill_in "Eメールアドレス", with: unexist_email
          click_button "パスワード再設定方法の送信"

          # Deviseのparanoidモードを使用しているため正常系と同じメッセージが表示される
          expect(current_path).to eq new_user_session_path
          expect(page).to have_content "メールアドレスが登録済みの場合、パスワード再設定用のメールが数分以内に送信されます。"

          # メール送信が行われていないことを確認
          expect(ActionMailer::Base.deliveries).to be_empty
        end

        scenario "Eメールアドレスの項目を入力せずにパスワード再設定メールの送信を試みる" do
          click_button "パスワード再設定方法の送信"

          # Deviseのparanoidモードを使用しているため正常系と同じメッセージが表示される
          expect(current_path).to eq new_user_session_path
          expect(page).to have_content "メールアドレスが登録済みの場合、パスワード再設定用のメールが数分以内に送信されます。"

          # メール送信が行われていないことを確認
          expect(ActionMailer::Base.deliveries).to be_empty
        end

        scenario "ゲストユーザーのEメールアドレスでパスワード再設定メールの送信を試みる" do
          fill_in "Eメールアドレス", with: guest_user.email
          click_button "パスワード再設定方法の送信"

          expect(current_path).to eq new_user_session_path
          expect(page).to have_content "ゲストユーザーのパスワード再設定は許可されていません。"

          # メール送信が行われていないことを確認
          expect(ActionMailer::Base.deliveries).to be_empty
        end
      end

      describe "パスワードの再設定" do
        let!(:user) { create(:user) }
        # フローの中でreset_password関連カラムのupdateがされるため
        # before_updateメソッドの処理にマスター管理ユーザーが必要
        let!(:master_user) { create(:user, :master_admin) }

        before do
          visit new_user_password_path
          fill_in "Eメールアドレス", with: user.email
          click_button "パスワード再設定方法の送信"
          expect(page).to have_content "メールアドレスが登録済みの場合、パスワード再設定用のメールが数分以内に送信されます。"

          # パスワード再設定メール送信確認
          email = ActionMailer::Base.deliveries.last
          expect(email.to).to include user.email
          expect(email.subject).to eq "パスワードの再設定について"

          # メール内のURLからアカウント有効化
          reset_password_link = email.body.match(/(https?:\/\/[^\s]+)/)[0]
          visit reset_password_link
        end

        scenario "パスワードが空の状態でパスワード変更を試みる" do
          expect do
            click_button "パスワード変更"
          end.to_not change { user.reload.encrypted_password }
          expect(current_path).to eq user_password_path
          expect(page).to have_content "パスワードを入力してください。"
          expect(page).to have_selector("h2", text: "パスワードの再設定")
        end

        let(:lack_length_password) { "pass123" }

        scenario "パスワードの文字数が不足している状態でパスワード変更を試みる" do
          expect do
            # パスワード関連のフィールドはラベル文字列だと重複して扱われるためidを指定
            fill_in "user_password", with: lack_length_password
            fill_in "user_password_confirmation", with: lack_length_password
            click_button "パスワード変更"
          end.to_not change { user.reload.encrypted_password }
          expect(current_path).to eq user_password_path
          expect(page).to have_content "パスワードは#{Devise.password_length.min}文字以上で入力してください。"
          expect(page).to have_selector("h2", text: "パスワードの再設定")
        end

        let(:over_length_password) { "Ab1" * 43 } # 129文字

        scenario "パスワードの文字数がオーバーしている状態でパスワード変更を試みる" do
          expect do
            # パスワード関連のフィールドはラベル文字列だと重複して扱われるためidを指定
            fill_in "user_password", with: over_length_password
            fill_in "user_password_confirmation", with: over_length_password
            click_button "パスワード変更"
          end.to_not change { user.reload.encrypted_password }
          expect(current_path).to eq user_password_path
          expect(page).to have_content "パスワードは#{Devise.password_length.max}文字以内で入力してください。"
          expect(page).to have_selector("h2", text: "パスワードの再設定")
        end

        let(:invalid_password) { "password" }

        scenario "パスワードのフォーマットが正しくない状態でパスワード変更を試みる" do
          expect do
            # パスワード関連のフィールドはラベル文字列だと重複して扱われるためidを指定
            fill_in "user_password", with: invalid_password
            fill_in "user_password_confirmation", with: invalid_password
            click_button "パスワード変更"
          end.to_not change { user.reload.encrypted_password }
          expect(current_path).to eq user_password_path
          expect(page).to have_content "パスワードは不正な値です。"
          expect(page).to have_selector("h2", text: "パスワードの再設定")
        end

        scenario "パスワードとパスワード確認が一致しない状態でパスワード変更を試みる" do
          expect do
            # パスワード関連のフィールドはラベル文字列だと重複して扱われるためidを指定
            fill_in "user_password", with: "ChangePass123"
            fill_in "user_password_confirmation", with: "DifferentPass123"
            click_button "パスワード変更"
          end.to_not change { user.reload.encrypted_password }
          expect(current_path).to eq user_password_path
          expect(page).to have_content "パスワード（確認用）とパスワードの入力が一致しません。"
          expect(page).to have_selector("h2", text: "パスワードの再設定")
        end
      end

      describe "パスワードリセット用トークンの有効期限" do
        let!(:user) { create(:user) }
        # フローの中でreset_password関連カラムのupdateがされるため
        # before_updateメソッドの処理にマスター管理ユーザーが必要
        let!(:master_user) { create(:user, :master_admin) }
        let(:valid_new_password) { "NewPass123" }

        scenario "トークンの有効期限が切れた状態でパスワードの変更をしようとする" do
          visit new_user_password_path
          fill_in "Eメールアドレス", with: user.email
          click_button "パスワード再設定方法の送信"
          expect(page).to have_content "メールアドレスが登録済みの場合、パスワード再設定用のメールが数分以内に送信されます。"

          # パスワード再設定メール送信確認
          email = ActionMailer::Base.deliveries.last
          expect(email.to).to include user.email
          expect(email.subject).to eq "パスワードの再設定について"

          # Deviseに設定している有効期限
          password_reset_expiration = 6.hours

          # 期限を過ぎた状態にする
          travel_to(Time.current + password_reset_expiration + 1.second) do
            # メール内のURLからアカウント有効化
            reset_password_link = email.body.match(/(https?:\/\/[^\s]+)/)[0]
            visit reset_password_link

            expect do
              # パスワード関連のフィールドはラベル文字列だと重複して扱われるためidを指定
              fill_in "user_password", with: valid_new_password
              fill_in "user_password_confirmation", with: valid_new_password
              click_button "パスワード変更"
            end.to_not change { user.reload.encrypted_password }

            # パスワードリセット用トークンの有効期限切れを確認
            expect(current_path).to eq user_password_path
            expect(page).to have_content "パスワードリセット用トークンの有効期限が切れました。新しくリクエストしてください。"
            expect(page).to have_selector("h2", text: "パスワードの再設定")
          end
        end
      end

      describe "不正なパスワードリセット用トークン" do
        let(:invalid_token) { "InvalidToken" }
        let(:valid_new_password) { "NewPass123" }

        scenario "登録されていないトークンでパスワードの変更をしようとする" do
          # 不正なトークンをクエリパラメータにパスワード変更画面へアクセス
          expect(User.exists?(reset_password_token: invalid_token)).to be_falsey
          visit edit_user_password_path(reset_password_token: invalid_token)

          # パスワード関連のフィールドはラベル文字列だと重複して扱われるためidを指定
          fill_in "user_password", with: valid_new_password
          fill_in "user_password_confirmation", with: valid_new_password
          click_button "パスワード変更"

          # パスワードリセット用トークンの有効期限切れを確認
          expect(current_path).to eq user_password_path
          expect(page).to have_content "パスワードリセット用トークンは不正な値です。"
          expect(page).to have_selector("h2", text: "パスワードの再設定")
        end
      end
    end
  end
end
