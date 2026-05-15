require "rails_helper"

RSpec.describe ContactMailer, type: :mailer do
  describe "#send_contact_mail" do
    let(:mail) { ContactMailer.with(contact: contact).send_contact_mail }
    let(:contact) { Contact.new(name: name, email: email, subject: subject, message: message) }
    let(:subject) { "お問い合わせの件名" }
    let(:message) { "お問い合わせの内容が正しく送信されているか確認する" }

    shared_examples "メールの基本テスト" do
      it "メールの件名が正しいこと" do
        expect(mail.subject).to eq("【お問い合わせ】#{contact.subject}")
      end

      it "メールの送信先のメールアドレスが正しいこと" do
        contact_email_original = ENV["CONTACT_EMAIL"]
        ENV["CONTACT_EMAIL"] = "test-contact-email@example.com"

        expect(mail.to).to eq(["test-contact-email@example.com"])

        ENV["CONTACT_EMAIL"] = contact_email_original
      end

      it "メールの送信元が正しいこと" do
        expect(mail.from).to eq(["no-reply@okamemo.com"])
      end

      it "メール本文に問い合わせ送信者の名前が含まれていること" do
        expect(mail.body.encoded).to include(contact.name)
      end

      it "メール本文にお問い合わせ内容が含まれていること" do
        expect(mail.body.encoded).to include(contact.message)
      end
    end

    context "登録していないユーザーがお問い合わせを送信した場合" do
      let(:name) { "外部ユーザー" }
      let(:email) { "unregistered-user@example.com" }

      it_behaves_like "メールの基本テスト"

      it "メール本文にユーザーの登録済みを示す文言が含まていないこと" do
        expect(mail.body.encoded).to_not include("登録済み")
      end

      let(:expected_number_of_strings) { 2 }

      it "メール本文で「ユーザー登録の有無」と「IDの情報」の二項目が\"未登録\"となっていること" do
        mail_body = mail.body.encoded
        expect(mail_body.scan("未登録").count).to eq(expected_number_of_strings)
      end
    end

    context "登録済みのユーザーがお問い合わせを送信した場合" do
      let(:user) { create(:user, name: "登録済みユーザー", email: "registered-user@example.com") }
      let(:name) { user.name }
      let(:email) { user.email }

      it_behaves_like "メールの基本テスト"

      it "メール本文にユーザーの登録済みを示す文言が含まれていること" do
        expect(mail.body.encoded).to include("登録済み")
      end

      let(:expected_number_of_strings) { 0 }

      it "メール本文で\"未登録\"の文字列が含まれないこと" do
        expect(mail.body.encoded).to_not include("未登録")
      end

      it "メール本文にユーザーIDが含まれていること" do
        expect(mail.body.encoded).to include(user.id.to_s)
      end
    end
  end
end
