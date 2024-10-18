require "rails_helper"

RSpec.describe "Devise Mailer", type: :mailer do
  # ユーザーのtokenを更新するためupdate処理が実行される
  # その際のbefore_updateメソッドにマスター管理ユーザーが必要
  let!(:master_user) { create(:user, :master_admin) }

  describe "メールアドレス確認メール" do
    shared_examples "メールアドレス確認メールの共通テスト" do
      it "メールの件名が正しいこと" do
        expect(mail.subject).to eq "メールアドレス確認メール"
      end

      it "メールの送信先のメールアドレスが正しいこと" do
        # テスト先でentry_email変数を定義する
        expect(mail.to).to eq [entry_email]
      end

      it "メールの送信元が正しいこと" do
        expect(mail.from).to eq ["no-reply@okamemo.com"]
      end

      it "メール本文に正しいURLリンクが含まれていること" do
        expected_url = user_confirmation_url(confirmation_token: user.confirmation_token)
        expect(mail.body.encoded).to include(expected_url)
      end

      it "メール本文に正しい登録メールアドレスが表示されること" do
        # テスト先でentry_email変数を定義する
        expect(mail.body.encoded).to include "登録メールアドレス： #{entry_email}"
      end
    end

    context "ユーザー登録時の場合" do
      let(:user) { create(:user, :unactivated) }
      # ユーザー登録時は登録したメールアドレスを参照する
      let(:entry_email) { user.email }
      let(:mail) { user.send_confirmation_instructions }

      it_behaves_like "メールアドレス確認メールの共通テスト"
    end

    context "メールアドレス変更時の場合" do
      let(:user) { create(:user) }
      # メールアドレス変更時は変更予定のメールアドレスを参照する
      let(:entry_email) { user.reload.unconfirmed_email }

      # 擬似的にユーザー編集フォームで新しいメールアドレスを送信した場合の処理を再現
      before do
        user.update(
          unconfirmed_email: "new-email@example.test",
          confirmation_sent_at: Time.current
        )
      end

      # beforeの後にメールオブジェクトをmail変数に格納する
      # user_confirmation_urlメソッドの実行前に
      # user.confirmation_tokenを生成するため事前に読み込む
      let!(:mail) { user.send_reconfirmation_instructions }

      it_behaves_like "メールアドレス確認メールの共通テスト"
    end
  end

  describe "パスワード再設定メール" do
    let(:user) { create(:user) }
    let(:reset_password_token) { user.send_reset_password_instructions }
    # send_reset_password_instructionsの戻り値がメールオブジェクトではないため
    # ActionMailer::Base.deliveriesからメールオブジェクトを取得する
    let(:mail) { ActionMailer::Base.deliveries.last }

    before do
      # パスワードリセットのメールを送信しトークンを生成する（戻り値はリセットパスワードの生トークン）
      reset_password_token
    end

    it "メールの件名が正しいこと" do
      expect(mail.subject).to eq "パスワードの再設定について"
    end

    it "メールの送信先のメールアドレスが正しいこと" do
      expect(mail.to).to eq [user.email]
    end

    it "メールの送信元が正しいこと" do
      expect(mail.from).to eq ["no-reply@okamemo.com"]
    end

    it "メール本文に正しいURLリンクが含まれていること" do
      # reset_password_tokenの戻り値の生トークンを使用する
      expected_url = edit_user_password_url(reset_password_token: reset_password_token)
      expect(mail.body.encoded).to include(expected_url)
    end
  end
end
