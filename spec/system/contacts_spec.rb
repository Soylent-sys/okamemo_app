require 'rails_helper'

RSpec.describe "Contacts", type: :system do
  describe "ビューの要素" do
    describe "new" do
      context "共通のテスト" do
        before do
          visit contact_path
        end

        it "ページタイトルが表示されること" do
          expect(page).to have_selector("h1", text: "お問い合わせ")
        end

        it "トップページにもどる のリンクが存在すること" do
          expect(page).to have_link("トップページ にもどる", href: root_path)
        end

        it "トップページにもどる のリンクをクリックしてrootページに遷移すること" do
          click_link "トップページ にもどる"

          expect(page).to have_http_status(:success)
          expect(current_path).to eq root_path
        end

        it "お問い合わせ用のフォームが表示されること" do
          within("form", text: "お問い合わせフォーム") do
            expect(page).to have_selector("h2", text: "お問い合わせフォーム")
            expect(page).to have_field("お名前")
            expect(page).to have_field("Eメールアドレス")
            expect(page).to have_field("件名")
            expect(page).to have_field("お問い合わせ内容")
            expect(page).to have_button("送信内容の確認")
          end
        end
      end

      context "サインインしていない場合" do
        before do
          visit contact_path
        end

        it "お名前のフィールドがreadonlyではないこと" do
          expect(page).to have_field("お名前", readonly: false)
        end

        it "お名前のフィールドのインフォメーションが未登録ユーザー向けであること" do
          within("div.field", text: "お名前") do
            expect(page).to have_selector("small", text: "お名前は最大#{Contact::MAX_LENGTH_NAME}文字まで入力できます")
          end
        end

        it "Eメールアドレスのフィールドがreadonlyではないこと" do
          expect(page).to have_field("Eメールアドレス", readonly: false)
        end

        it "Eメールアドレスのフィールドのインフォメーションが未登録ユーザー向けであること" do
          within("div.field", text: "Eメールアドレス") do
            expect(page).to have_selector("small", text: "このメールアドレスにご連絡いたします")
          end
        end

        it "お問い合わせフォームにRecaptchaが存在すること" do
          # Recaptchaの表示を確認
          expect(page).to have_css("div.g-recaptcha")
        end

        it "送信内容の確認ボタンが活性状態であること" do
          expect(page).to have_button("送信内容の確認", disabled: false)
        end
      end

      context "サインインしている場合" do
        context "共通のテスト" do
          let!(:user) { create(:user) }

          before do
            sign_in_as(user)
            # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
            expect(page).to have_content "ログインしました。"
            visit contact_path
          end

          it "お名前のフィールドがreadonlyであること" do
            expect(page).to have_field("お名前", readonly: true)
          end

          it "お名前のフィールドにユーザーのニックネームが入力されていること" do
            expect(page).to have_field("お名前", with: user.name)
          end

          it "お名前のフィールドのインフォメーションが登録ユーザー向けであること" do
            within("div.field", text: "お名前") do
              expect(page).to have_selector("small", text: "ご登録のニックネームで送信されます")
            end
          end

          it "Eメールアドレスのフィールドがreadonlyであること" do
            expect(page).to have_field("Eメールアドレス", readonly: true)
          end

          it "Eメールアドレスのフィールドにユーザーのメールアドレスが入力されていること" do
            expect(page).to have_field("Eメールアドレス", with: user.email)
          end

          it "Eメールアドレスのフィールドのインフォメーションが登録ユーザー向けであること" do
            within("div.field", text: "Eメールアドレス") do
              expect(page).to have_selector("small", text: "ご登録のメールアドレスにご連絡いたします")
            end
          end

          it "お問い合わせフォームにRecaptchaが存在しないこと" do
            # Recaptchaの表示を確認
            expect(page).to_not have_css("div.g-recaptcha")
          end
        end

        context "ゲストユーザー以外の場合" do
          let!(:user) { create(:user) }

          before do
            sign_in_as(user)
            # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
            expect(page).to have_content "ログインしました。"
            visit contact_path
          end

          it "送信内容の確認ボタンが活性状態であること" do
            expect(page).to have_button("送信内容の確認", disabled: false)
          end
        end

        context "ゲストユーザーの場合" do
          let!(:user) { User.guest }

          before do
            sign_in_as(user)
            # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
            expect(page).to have_content "ログインしました。"
            visit contact_path
          end

          it "送信内容の確認ボタンが非活性状態であること" do
            expect(page).to have_button("送信内容の確認", disabled: true)
          end
        end
      end
    end

    describe "confirm" do
      before do
        visit contact_path

        fill_in "お名前", with: "テストユーザー"
        fill_in "Eメールアドレス", with: "test-user@example.test"
        fill_in "件名", with: "テスト件名"
        fill_in "お問い合わせ内容", with: "お問い合わせ内容をテストする"
        click_button "送信内容の確認"
      end

      it "ページタイトルが表示されること" do
        expect(page).to have_selector("h1", text: "お問い合わせ")
      end

      it "お問い合わせ内容確認の表示枠が存在すること" do
        expect(page).to have_selector("div.confirm-window-text", text: "お問い合わせ内容の確認")
      end

      it "入力画面で入力したお名前が表示されること" do
        within("div.confirm-window", text: "お名前") do
          expect(page).to have_content "テストユーザー"
        end
      end

      it "入力画面で入力したEメールアドレスが表示されること" do
        within("div.confirm-window", text: "Eメールアドレス") do
          expect(page).to have_content "test-user@example.test"
        end
      end

      it "入力画面で入力した件名が表示されること" do
        within("div.confirm-window", text: "件名") do
          expect(page).to have_content "テスト件名"
        end
      end

      it "入力画面で入力したお問い合わせ内容が表示されること" do
        within("div.confirm-window", text: "お問い合わせ内容") do
          expect(page).to have_content "お問い合わせ内容をテストする"
        end
      end

      it "送信ボタンが存在すること" do
        expect(page).to have_button "送信"
      end

      it "お名前が入力されたhiddenフィールドが存在すること（送信ボタン用）" do
        expect(find_field("confirm_contact_name", type: "hidden").value).to eq "テストユーザー"
      end

      it "Eメールアドレスが入力されたhiddenフィールドが存在すること（送信ボタン用）" do
        expect(find_field("confirm_contact_email", type: "hidden").value).to eq "test-user@example.test"
      end

      it "件名が入力されたhiddenフィールドが存在すること（送信ボタン用）" do
        expect(find_field("confirm_contact_subject", type: "hidden").value).to eq "テスト件名"
      end

      it "お問い合わせ内容が入力されたhiddenフィールドが存在すること（送信ボタン用）" do
        expect(find_field("confirm_contact_message", type: "hidden").value).to eq "お問い合わせ内容をテストする"
      end

      it "もどるボタンが存在すること" do
        expect(page).to have_button "もどる"
      end

      it "お名前が入力されたhiddenフィールドが存在すること（もどるボタン用）" do
        expect(find_field("back_contact_name", type: "hidden").value).to eq "テストユーザー"
      end

      it "Eメールアドレスが入力されたhiddenフィールドが存在すること（もどるボタン用）" do
        expect(find_field("back_contact_email", type: "hidden").value).to eq "test-user@example.test"
      end

      it "件名が入力されたhiddenフィールドが存在すること（もどるボタン用）" do
        expect(find_field("back_contact_subject", type: "hidden").value).to eq "テスト件名"
      end

      it "お問い合わせ内容が入力されたhiddenフィールドが存在すること（もどるボタン用）" do
        expect(find_field("back_contact_message", type: "hidden").value).to eq "お問い合わせ内容をテストする"
      end

      it "もどるボタンをクリックするとお問い合わせの入力画面に遷移すること" do
        click_button("もどる")

        # postによるrender処理のためcurrent_pathではなく該当ページの要素で遷移を確認
        expect(page).to have_selector("h2", text: "お問い合わせフォーム")
        expect(page).to have_button("送信内容の確認")
      end
    end

    describe "done" do
      before do
        visit contact_path

        fill_in "お名前", with: "テストユーザー"
        fill_in "Eメールアドレス", with: "test-user@example.test"
        fill_in "件名", with: "テスト件名"
        fill_in "お問い合わせ内容", with: "お問い合わせ内容をテストする"
        click_button "送信内容の確認"

        expect(page).to have_selector("h2", text: "お問い合わせ内容の確認")
        click_button "送信"
      end

      it "ページタイトルが表示されること" do
        expect(page).to have_selector("h1", text: "お問い合わせ")
      end

      it "お問い合わせ内容の送信完了メッセージが表示されること" do
        expect(page).to have_selector("h2", text: "お問い合わせ内容を送信しました")
      end

      it "お問い合わせについての対応を示すメッセージが表示されること" do
        expect(page).to have_content "お問い合わせの内容を確認・受付の後、ご入力いただいたEメールアドレスへご連絡いたします。しばらくお待ちください。"
      end

      it "トップページにもどる のリンクが存在すること" do
        expect(page).to have_link("トップページにもどる", href: root_path)
      end

      it "トップページにもどる のリンクをクリックしてrootページに遷移すること" do
        click_link "トップページにもどる"

        expect(page).to have_http_status(:success)
        expect(current_path).to eq root_path
      end
    end
  end

  describe "お問い合わせ送信のフロー" do
    context "正常系" do
      context "ユーザー登録していないユーザーの場合" do
        let!(:contact_email_original) { ENV["CONTACT_EMAIL"] }

        before do
          # お問い合わせの送信先メールアドレス定数をテスト用に置き換える
          ENV["CONTACT_EMAIL"] = "test-contact-email@example.com"
          visit contact_path
        end

        after do
          # beforeで置き換えたお問い合わせの送信先メールアドレスを戻す
          ENV["CONTACT_EMAIL"] = contact_email_original
        end

        scenario "ユーザーがお問い合わせを送信する" do
          fill_in "お名前", with: "テストユーザー"
          fill_in "Eメールアドレス", with: "test-user@example.test"
          fill_in "件名", with: "テスト件名"
          fill_in "お問い合わせ内容", with: "お問い合わせ内容をテストする"
          click_button "送信内容の確認"

          # 送信内容の確認画面
          expect(page).to have_selector("h2", text: "お問い合わせ内容の確認")
          within("div.confirm-window", text: "お名前") do
            expect(page).to have_content "テストユーザー"
          end
          within("div.confirm-window", text: "Eメールアドレス") do
            expect(page).to have_content "test-user@example.test"
          end
          within("div.confirm-window", text: "件名") do
            expect(page).to have_content "テスト件名"
          end
          within("div.confirm-window", text: "お問い合わせ内容") do
            expect(page).to have_content "お問い合わせ内容をテストする"
          end
          click_button "送信"

          # 送信完了画面
          expect(page).to have_selector("h2", text: "お問い合わせ内容を送信しました")

          # 送信されたお問い合わせメール内容
          mail = ActionMailer::Base.deliveries.last
          expect(mail.to).to include "test-contact-email@example.com"
          expect(mail.subject).to eq "【お問い合わせ】テスト件名"
          expect(mail.body.encoded).to include "テストユーザー"
          expect(mail.body.encoded).to include "test-user@example.test"
          expect(mail.body.encoded).to include "テスト件名"
          expect(mail.body.encoded).to include "【ユーザー登録の有無】： 未登録"
          expect(mail.body.encoded).to include "【ユーザーID】: 未登録"
          expect(mail.body.encoded).to include "お問い合わせ内容をテストする"
        end
      end

      context "登録済みユーザーの場合" do
        let(:user) { create(:user) }
        let!(:contact_email_original) { ENV["CONTACT_EMAIL"] }

        before do
          # お問い合わせの送信先メールアドレス定数をテスト用に置き換える
          ENV["CONTACT_EMAIL"] = "test-contact-email@example.com"
          visit contact_path

          sign_in_as(user)
          # ログイン処理完了前にvisitを実行しないようログイン成功の確認を挟む
          expect(page).to have_content "ログインしました。"
          visit contact_path
        end

        after do
          # beforeで置き換えたお問い合わせの送信先メールアドレスを戻す
          ENV["CONTACT_EMAIL"] = contact_email_original
        end

        scenario "ユーザーがお問い合わせを送信する" do
          fill_in "件名", with: "テスト件名"
          fill_in "お問い合わせ内容", with: "お問い合わせ内容をテストする"
          click_button "送信内容の確認"

          # 送信内容の確認画面
          expect(page).to have_selector("h2", text: "お問い合わせ内容の確認")
          within("div.confirm-window", text: "お名前") do
            expect(page).to have_content user.name
          end
          within("div.confirm-window", text: "Eメールアドレス") do
            expect(page).to have_content user.email
          end
          within("div.confirm-window", text: "件名") do
            expect(page).to have_content "テスト件名"
          end
          within("div.confirm-window", text: "お問い合わせ内容") do
            expect(page).to have_content "お問い合わせ内容をテストする"
          end
          click_button "送信"

          # 送信完了画面
          expect(page).to have_selector("h2", text: "お問い合わせ内容を送信しました")

          # 送信されたお問い合わせメール内容
          mail = ActionMailer::Base.deliveries.last
          expect(mail.to).to include "test-contact-email@example.com"
          expect(mail.subject).to eq "【お問い合わせ】テスト件名"
          expect(mail.body.encoded).to include user.name
          expect(mail.body.encoded).to include user.email
          expect(mail.body.encoded).to include "テスト件名"
          expect(mail.body.encoded).to include "【ユーザー登録の有無】： 登録済み"
          expect(mail.body.encoded).to include "【ユーザーID】: #{user.id}"
          expect(mail.body.encoded).to include "お問い合わせ内容をテストする"
        end
      end

      context "共通のテスト" do
        before do
          visit contact_path
          fill_in "お名前", with: "テストユーザー"
          fill_in "Eメールアドレス", with: "test-user@example.test"
          fill_in "件名", with: "テスト件名"
          fill_in "お問い合わせ内容", with: "お問い合わせ内容をテストする"
          click_button "送信内容の確認"
        end

        scenario "フォームを入力して投稿した後に確認画面から入力画面へ戻るとフォームの入力値が保持される" do
          # 送信内容の確認画面
          expect(page).to have_selector("h2", text: "お問い合わせ内容の確認")
          within("div.confirm-window", text: "お名前") do
            expect(page).to have_content "テストユーザー"
          end
          within("div.confirm-window", text: "Eメールアドレス") do
            expect(page).to have_content "test-user@example.test"
          end
          within("div.confirm-window", text: "件名") do
            expect(page).to have_content "テスト件名"
          end
          within("div.confirm-window", text: "お問い合わせ内容") do
            expect(page).to have_content "お問い合わせ内容をテストする"
          end
          click_button "もどる"

          # お問い合わせ入力画面の各フィールドの内容確認
          expect(page).to have_selector("h2", text: "お問い合わせフォーム")
          expect(page).to have_field("お名前", with: "テストユーザー")
          expect(page).to have_field("Eメールアドレス", with: "test-user@example.test")
          expect(page).to have_field("件名", with: "テスト件名")
          expect(page).to have_field("お問い合わせ内容", with: "お問い合わせ内容をテストする")
        end
      end
    end

    context "異常系" do
      let(:valid_name) { "テストユーザー" }
      let(:valid_email) { "valid-email@example.test" }
      let(:valid_subject) { "テスト件名" }
      let(:valid_message) { "お問い合わせ内容をテストする" }

      before do
        visit contact_path
      end

      scenario "必須フィールドが空の状態でお問い合わせの送信を試みる" do
        fill_in "お名前", with: ""
        fill_in "Eメールアドレス", with: ""
        fill_in "件名", with: ""
        fill_in "お問い合わせ内容", with: ""
        click_button "送信内容の確認"

        expect(page).to have_content "お名前を入力してください。"
        expect(page).to have_content "Eメールアドレスを入力してください。"
        expect(page).to have_content "件名を入力してください。"
        expect(page).to have_content "お問い合わせ内容を入力してください。"
      end

      let(:over_length_name) { "a" * 21 }

      scenario "お名前の文字数がオーバーしている状態でお問い合わせの送信を試みる" do
        fill_in "お名前", with: over_length_name
        fill_in "Eメールアドレス", with: valid_email
        fill_in "件名", with: valid_subject
        fill_in "お問い合わせ内容", with: valid_message
        click_button "送信内容の確認"

        expect(page).to have_content "お名前は#{Contact::MAX_LENGTH_NAME}文字以内で入力してください。"
      end

      let(:over_length_email) { "#{"a" * 244}@example.com" }

      scenario "メールアドレスの文字数がオーバーしている状態でお問い合わせの送信を試みる" do
        fill_in "お名前", with: valid_name
        fill_in "Eメールアドレス", with: over_length_email
        fill_in "件名", with: valid_subject
        fill_in "お問い合わせ内容", with: valid_message
        click_button "送信内容の確認"

        expect(page).to have_content "Eメールアドレスは#{Contact::MAX_LENGTH_EMAIL}文字以内で入力してください。"
      end

      scenario "メールアドレスのフォーマットが正しくない状態でお問い合わせの送信を試みる" do
        fill_in "お名前", with: valid_name
        fill_in "Eメールアドレス", with: "invalid-email"
        fill_in "件名", with: valid_subject
        fill_in "お問い合わせ内容", with: valid_message
        click_button "送信内容の確認"

        expect(page).to have_content "Eメールアドレスは不正な値です。"
      end

      let(:over_length_subject) { "あ" * 51 }

      scenario "件名の文字数がオーバーしている状態でお問い合わせの送信を試みる" do
        fill_in "お名前", with: valid_name
        fill_in "Eメールアドレス", with: valid_email
        fill_in "件名", with: over_length_subject
        fill_in "お問い合わせ内容", with: valid_message
        click_button "送信内容の確認"

        expect(page).to have_content "件名は#{Contact::MAX_LENGTH_SUBJECT}文字以内で入力してください。"
      end

      let(:over_length_message) { "あ" * 501 }

      scenario "お問い合わせ内容の文字数がオーバーしている状態でお問い合わせの送信を試みる" do
        fill_in "お名前", with: valid_name
        fill_in "Eメールアドレス", with: valid_email
        fill_in "件名", with: valid_subject
        fill_in "お問い合わせ内容", with: over_length_message
        click_button "送信内容の確認"

        expect(page).to have_content "お問い合わせ内容は#{Contact::MAX_LENGTH_MESSAGE}文字以内で入力してください。"
      end
    end
  end
end
