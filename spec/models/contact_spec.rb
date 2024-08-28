require 'rails_helper'

RSpec.describe Contact, type: :model do
  context "有効となる場合" do
    it "名前、メールアドレス、件名、お問い合わせ内容があれば有効な状態であること" do
      contact = Contact.new(
        name: "テストユーザー",
        email: "test-contact@example.com",
        subject: "テスト件名",
        message: "お問い合わせの内容が有効であるかをテストする"
      )
      expect(contact).to be_valid
    end
  end

  context "無効となる場合" do
    it "名前がなければ無効な状態であること" do
      contact = Contact.new(name: nil)
      contact.valid?
      expect(contact.errors.of_kind?(:name, :blank)).to be_truthy
    end

    it "名前が空文字のときは無効な状態であること" do
      contact = Contact.new(name: "")
      contact.valid?
      expect(contact.errors.of_kind?(:name, :blank)).to be_truthy
    end

    it "名前が20文字を超えたら無効な状態であること" do
      contact = Contact.new(name: "a" * 21)
      contact.valid?
      expect(contact.errors.of_kind?(:name, :too_long)).to be_truthy
    end

    it "メールアドレスがなければ無効な状態であること" do
      contact = Contact.new(email: nil)
      contact.valid?
      expect(contact.errors.of_kind?(:email, :blank)).to be_truthy
    end

    it "メールアドレスが空文字のときは無効な状態であること" do
      contact = Contact.new(email: "")
      contact.valid?
      expect(contact.errors.of_kind?(:email, :blank)).to be_truthy
    end

    it "メールアドレスが255文字を超えたら無効な状態であること" do
      contact = Contact.new(email: "#{"a" * 244}@example.com")
      contact.valid?
      expect(contact.errors.of_kind?(:email, :too_long)).to be_truthy
    end

    it "メールアドレスが正しいフォーマットでないときは無効な状態であること" do
      contact = Contact.new(email: "invalid_email")
      contact.valid?
      expect(contact.errors.of_kind?(:email, :invalid)).to be_truthy
    end

    it "件名がなければ無効な状態であること" do
      contact = Contact.new(subject: nil)
      contact.valid?
      expect(contact.errors.of_kind?(:subject, :blank)).to be_truthy
    end

    it "件名が空文字のときは無効な状態であること" do
      contact = Contact.new(subject: "")
      contact.valid?
      expect(contact.errors.of_kind?(:subject, :blank)).to be_truthy
    end

    it "件名が50文字を超えたら無効な状態であること" do
      contact = Contact.new(subject: "a" * 51)
      contact.valid?
      expect(contact.errors.of_kind?(:subject, :too_long)).to be_truthy
    end

    it "お問い合わせ内容がなければ無効な状態であること" do
      contact = Contact.new(message: nil)
      contact.valid?
      expect(contact.errors.of_kind?(:message, :blank)).to be_truthy
    end

    it "お問い合わせ内容が空文字のときは無効な状態であること" do
      contact = Contact.new(message: "")
      contact.valid?
      expect(contact.errors.of_kind?(:message, :blank)).to be_truthy
    end

    it "お問い合わせ内容が500文字を超えたら無効な状態であること" do
      contact = Contact.new(message: "a" * 501)
      contact.valid?
      expect(contact.errors.of_kind?(:message, :too_long)).to be_truthy
    end
  end
end
