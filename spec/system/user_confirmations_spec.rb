require 'rails_helper'

RSpec.describe "UserConfirmations", type: :system do
  describe "ビューの要素" do
    describe "new" do
      before do
        visit new_user_confirmation_path
      end

      it "ページタイトルが表示されていること" do
        expect(page).to have_selector("h1", text: "確認メールの再送")
      end

      it "確認メール再送フォームが表示されること" do
        within "form.new_user" do
          expect(page).to have_selector("h2", text: "メールアドレスの入力")
          expect(page).to have_field("Eメールアドレス")
          expect(page).to have_button("確認メール再送")
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

      it "パスワード再設定画面へのリンクが存在すること" do
        within ".form-other-bg" do
          expect(page).to have_link("パスワードを忘れましたか？", href: new_user_password_path)
        end
      end

      it "パスワード再設定画面へのリンクでパスワード再設定画面に遷移すること" do
        within ".form-other-bg" do
          click_link "パスワードを忘れましたか？"
        end

        expect(page).to have_http_status(:success)
        expect(current_path).to eq new_user_password_path
      end
    end
  end

  describe "アカウント認証メール再送のフロー" do
    context "正常系" do
      let(:user) { create(:user, :unactivated) }
      # フローの中でconfirm関連カラムのupdateがされるため
      # before_updateメソッドの処理にマスター管理ユーザーが必要
      let!(:master_user) { create(:user, :master_admin) }

      scenario "アカウント認証の確認メールを再送してアクティベートする" do
        expect(user.confirmed_at).to be_nil
        visit new_user_confirmation_path

        fill_in "Eメールアドレス", with: user.email
        click_button "確認メール再送"

        expect(page).to have_content "メールアドレスが登録済みの場合、本人確認用のメールが数分以内に送信されます。"

        # パスワード再設定メール送信確認
        email = ActionMailer::Base.deliveries.last
        expect(email.to).to include user.email
        expect(email.subject).to eq "メールアドレス確認メール"

        # メール内のURLからアカウント有効化
        confirmation_link = email.body.match(/(https?:\/\/[^\s]+)/)[0]
        visit confirmation_link

        expect(page).to have_content "メールアドレスが確認できました。"
        expect(current_path).to eq new_user_session_path
        expect(user.reload.confirmed_at).not_to be_nil
      end
    end

    context "異常系" do
      context "サインインしていない場合" do
        describe "メールアドレスの入力" do
          let(:unexist_email) { "unexist-mail@example.test" }

          before do
            visit new_user_confirmation_path
          end

          scenario "登録されていないEメールアドレスで確認メールの再送を試みる" do
            expect(User.exists?(email: unexist_email)).to be_falsey
            fill_in "Eメールアドレス", with: unexist_email
            click_button "確認メール再送"

            # Deviseのparanoidモードを使用しているため正常系と同じメッセージが表示される
            expect(current_path).to eq new_user_session_path
            expect(page).to have_content "メールアドレスが登録済みの場合、本人確認用のメールが数分以内に送信されます。"

            # メール送信が行われていないことを確認
            expect(ActionMailer::Base.deliveries).to be_empty
          end

          scenario "Eメールアドレスの項目を入力せずに確認メールの再送を試みる" do
            click_button "確認メール再送"

            # Deviseのparanoidモードを使用しているため正常系と同じメッセージが表示される
            expect(current_path).to eq new_user_session_path
            expect(page).to have_content "メールアドレスが登録済みの場合、本人確認用のメールが数分以内に送信されます。"

            # メール送信が行われていないことを確認
            expect(ActionMailer::Base.deliveries).to be_empty
          end
        end

        describe "確認メールの有効期限" do
          let(:user) { create(:user, :unactivated) }
          # フローの中でconfirm関連カラムのupdateがされるため
          # before_updateメソッドの処理にマスター管理ユーザーが必要
          let!(:master_user) { create(:user, :master_admin) }

          scenario "再送した確認メールの有効期限が切れた状態でアクティベートしようとする" do
            expect(user.confirmed_at).to be_nil
            visit new_user_confirmation_path

            fill_in "Eメールアドレス", with: user.email
            click_button "確認メール再送"

            expect(page).to have_content "メールアドレスが登録済みの場合、本人確認用のメールが数分以内に送信されます。"

            # パスワード再設定メール送信確認
            email = ActionMailer::Base.deliveries.last
            expect(email.to).to include user.email
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
              expect(user.reload.confirmed_at).to be_nil
            end
          end
        end
      end

      context "サインインしている場合" do
        let(:user) { create(:user) }

        before do
          sign_in_as(user)
          expect(page).to have_content "ログインしました。"
          visit new_user_confirmation_path
        end

        scenario "認証済みユーザーがログイン状態で確認メールの再送を試みる" do
          fill_in "Eメールアドレス", with: user.email
          click_button "確認メール再送"

          expect(page).to have_content "すでにログインしています。"
          expect(current_path).to eq root_path

          # メール送信が行われていないことを確認
          expect(ActionMailer::Base.deliveries).to be_empty
        end

        scenario "ログイン状態のユーザーでEメールアドレスの項目を入力せずに確認メールの再送を試みる" do
          click_button "確認メール再送"

          expect(page).to have_content "すでにログインしています。"
          expect(current_path).to eq root_path

          # メール送信が行われていないことを確認
          expect(ActionMailer::Base.deliveries).to be_empty
        end
      end
    end
  end
end
