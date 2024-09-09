require "rails_helper"

RSpec.describe NotificationTargetUserMailer, type: :mailer do
  describe "#send_email_confirmation" do
    let(:mail) { NotificationTargetUserMailer.with(nt_user: notification_target_user).send_email_confirmation }
    let(:user) { create(:user, name: "テストユーザー") }
    let(:notification_target_user) do
      NotificationTargetUser.new(
        user: user,
        name: "通知対象テストユーザー",
        email: "test-nt-user@example.com",
        confirmation_token: "dummy_token"
      )
    end

    it "メールの件名が正しいこと" do
      expect(mail.subject).to eq "メールアドレス認証のお願い"
    end

    it "メールの送信先のメールアドレスが正しいこと" do
      expect(mail.to).to eq [notification_target_user.email]
    end

    it "メールの送信元が正しいこと" do
      expect(mail.from).to eq ["no-reply@okamemo.com"]
    end

    it "メール本文に通知対象ユーザーの名前が含まれていること" do
      expect(mail.body.encoded).to include notification_target_user.name
    end

    it "メール本文に通知対象ユーザーのメールアドレスが含まれていること" do
      expect(mail.body.encoded).to include notification_target_user.email
    end

    it "メール本文に通知対象ユーザーを登録したユーザー名が含まれていること" do
      expect(mail.body.encoded).to include notification_target_user.user.name
    end

    it "メール本文に正しいURLリンクが含まれていること" do
      expected_url = confirm_email_notification_target_users_url(token: notification_target_user.confirmation_token)
      expect(mail.body.encoded).to include(expected_url)
    end

    it "メール本文に認証の有効期限が含まれていること" do
      expect(mail.body.encoded).to include("#{NotificationTargetUser::EMAIL_CONFIRMATION_LIMIT}分間")
    end
  end
end
