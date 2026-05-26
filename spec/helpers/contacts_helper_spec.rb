require 'rails_helper'

RSpec.describe ContactsHelper, type: :helper do
  describe "#form_info_text_name" do
    context "サインインしている場合" do
      let(:user) { create(:user) }

      before do
        sign_in user
      end

      it "サインイン時用の文字列を返すこと" do
        expect(helper.form_info_text_name).to eq("ご登録のニックネームで送信されます")
      end
    end

    context "サインインしていない場合" do
      it "非サインイン時用の文字列を返すこと" do
        expect(helper.form_info_text_name).to eq("お名前は最大#{UserSharedConstants::MAX_LENGTH_NAME}文字まで入力できます")
      end
    end
  end

  describe "#form_info_text_email" do
    context "サインインしている場合" do
      let(:user) { create(:user) }

      before do
        sign_in user
      end

      it "サインイン時用の文字列を返すこと" do
        expect(helper.form_info_text_email).to eq("ご登録のメールアドレスにご連絡いたします")
      end
    end

    context "サインインしていない場合" do
      it "非サインイン時用の文字列を返すこと" do
        expect(helper.form_info_text_email).to eq("このメールアドレスにご連絡いたします")
      end
    end
  end

  describe "#done_text" do
    context "サインインしている場合" do
      let(:user) { create(:user) }

      before do
        sign_in user
      end

      it "サインイン時用の文字列を返すこと" do
        expect(helper.done_text).to eq("お問い合わせの内容を確認・受付の後、ご登録のEメールアドレスへご連絡いたします。しばらくお待ちください。")
      end
    end

    context "サインインしていない場合" do
      it "非サインイン時用の文字列を返すこと" do
        expect(helper.done_text).to eq("お問い合わせの内容を確認・受付の後、ご入力いただいたEメールアドレスへご連絡いたします。しばらくお待ちください。")
      end
    end
  end
end
