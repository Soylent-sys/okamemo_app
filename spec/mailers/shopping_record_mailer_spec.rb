require "rails_helper"

RSpec.describe ShoppingRecordMailer, type: :mailer do
  let(:mail) do
    ShoppingRecordMailer.with(shopping_record: shopping_record, nt_user: notification_target_user).send_shopping_result
  end
  let(:user) { create(:user) }
  let(:shopping_record) { create(:shopping_record, :closed, user: user) }
  let(:notification_target_user) { create(:notification_target_user, user: user) }

  describe "#send_shopping_result" do
    shared_examples "メールの基本テスト" do
      it "メールの件名が正しいこと" do
        expect(mail.subject).to eq("【お知らせ】#{notification_target_user.user.name}さんがお買い物しました！")
      end

      it "メールの送信先のメールアドレスが正しいこと" do
        expect(mail.to).to eq([notification_target_user.email])
      end

      it "メールの送信元が正しいこと" do
        expect(mail.from).to eq(["no-reply@okamemo.com"])
      end

      it "メール本文に通知対象ユーザーの名前が含まれていること" do
        expect(mail.body.encoded).to include(notification_target_user.name)
      end

      it "メール本文に通知対象ユーザーのメールアドレスが含まれていること" do
        expect(mail.body.encoded).to include(notification_target_user.email)
      end

      it "メール本文に通知対象ユーザーを登録したユーザー名が含まれていること" do
        expect(mail.body.encoded).to include(notification_target_user.user.name)
      end
    end

    context "お買い物(shopping_record)に紐づく購入記録(buy)が購入済み(purchased: true)と未購入(unpurchased: false)のレコードで混在する場合" do
      let!(:purchased_buy) { create(:buy, user: user, shopping_record: shopping_record, purchased: true, item_name: "アイテム1") }
      let!(:unpurchased_buy) { create(:buy, user: user, shopping_record: shopping_record, purchased: false, item_name: "アイテム2") }

      it_behaves_like "メールの基本テスト"

      it "メール本文に購入記録のアイテム名が含まれていること" do
        expect(mail.body.encoded).to include(purchased_buy.item_name, unpurchased_buy.item_name)
      end

      it "購入済みアイテムが無い事を示す文言が含まれないこと" do
        expect(mail.body.encoded).to_not include("買ったアイテムはありません")
      end

      it "未購入アイテムが無い事を示す文言が含まれないこと" do
        expect(mail.body.encoded).to_not include("買わなかったアイテムはありません")
      end
    end

    context "お買い物(shopping_record)に紐づく購入記録(buy)が購入済み(purchased: true)のレコードのみの場合" do
      let!(:purchased_buy) { create(:buy, user: user, shopping_record: shopping_record, purchased: true, item_name: "購入アイテム") }

      it_behaves_like "メールの基本テスト"

      it "メール本文に購入記録のアイテム名が含まれていること" do
        expect(mail.body.encoded).to include(purchased_buy.item_name)
      end

      it "購入済みアイテムが無い事を示す文言が含まれないこと" do
        expect(mail.body.encoded).to_not include("買ったアイテムはありません")
      end

      it "未購入アイテムが無い事を示す文言が含まれること" do
        expect(mail.body.encoded).to include("買わなかったアイテムはありません")
      end
    end

    context "お買い物(shopping_record)に紐づく購入記録(buy)が未購入(unpurchased: flase)のレコードのみの場合" do
      let!(:unpurchased_buy) do
        create(:buy, user: user, shopping_record: shopping_record, purchased: false, item_name: "未購入アイテム")
      end

      it_behaves_like "メールの基本テスト"

      it "メール本文に購入記録のアイテム名が含まれていること" do
        expect(mail.body.encoded).to include(unpurchased_buy.item_name)
      end

      it "購入済みアイテムが無い事を示す文言が含まれること" do
        expect(mail.body.encoded).to include("買ったアイテムはありません")
      end

      it "未購入アイテムが無い事を示す文言が含まれないこと" do
        expect(mail.body.encoded).to_not include("買わなかったアイテムはありません")
      end
    end
  end

  describe ".send_shopping_result_to_notification_target_users" do
    let!(:confirmed_nt_user1) { create(:notification_target_user, user: user, confirmation_status: :confirmed) }
    let!(:confirmed_nt_user2) { create(:notification_target_user, user: user, confirmation_status: :confirmed) }
    let!(:unconfirmed_nt_user) { create(:notification_target_user, user: user, confirmation_status: :unconfirmed) }
    let(:confirmed_nt_user_count) { 2 }

    it "ユーザーに紐づく認証済みの通知対象ユーザーにメールを送信すること" do
      expect { ShoppingRecordMailer.send_shopping_result_to_notification_target_users(shopping_record) }.
        to have_enqueued_mail(ShoppingRecordMailer, :send_shopping_result).exactly(confirmed_nt_user_count).times
    end
  end
end
