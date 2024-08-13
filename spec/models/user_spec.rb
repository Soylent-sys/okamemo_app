require 'rails_helper'

RSpec.describe User, type: :model do
  context "ユーザーの登録ができる場合" do
    it "ニックネーム、メールアドレス、パスワードがあれば有効な状態であること" do
      user = User.new(
        name: "テストユーザー",
        email: "test-valid-mail@example.com",
        password: "Password1"
      )
      expect(user).to be_valid
    end
  end

  context "ユーザーの登録ができない場合" do
    it "ニックネームがなければ無効な状態であること" do
      user = User.new(name: nil)
      user.valid?
      expect(user.errors.of_kind?(:name, :blank)).to be_truthy
    end

    it "ニックネームが空文字のときは無効な状態であること" do
      user = User.new(name: "")
      user.valid?
      expect(user.errors.of_kind?(:name, :blank)).to be_truthy
    end

    it "ニックネームが20文字を超えたら無効な状態であること" do
      user = User.new(name: "a" * 21)
      user.valid?
      expect(user.errors.of_kind?(:name, :too_long)).to be_truthy
    end

    it "メールアドレスがなければ無効な状態であること" do
      user = User.new(email: nil)
      user.valid?
      expect(user.errors.of_kind?(:email, :blank)).to be_truthy
    end

    it "メールアドレスが空文字のときは無効な状態であること" do
      user = User.new(email: "")
      user.valid?
      expect(user.errors.of_kind?(:email, :blank)).to be_truthy
    end

    it "メールアドレスが255文字を超えたら無効な状態であること" do
      user = User.new(email: "#{"a" * 244}@example.com")
      user.valid?
      expect(user.errors.of_kind?(:email, :too_long)).to be_truthy
    end

    it "メールアドレスが正しいフォーマットでないときは無効な状態であること" do
      user = User.new(email: "invalid_email")
      user.valid?
      expect(user.errors.of_kind?(:email, :invalid)).to be_truthy
    end

    it "メールアドレスが重複しているときは無効な状態であること" do
      User.create(
        name: "テストユーザー1",
        email: "test-mail@example.com",
        password: "Password1"
      )
      user = User.new(
        name: "テストユーザー2",
        email: "test-mail@example.com",
        password: "Password1"
      )
      user.valid?
      expect(user.errors.of_kind?(:email, :taken)).to be_truthy
    end

    it "パスワードがなければ無効な状態であること" do
      user = User.new(password: nil)
      user.valid?
      expect(user.errors.of_kind?(:password, :blank)).to be_truthy
    end

    it "パスワードが空文字のときは無効な状態であること" do
      user = User.new(password: "")
      user.valid?
      expect(user.errors.of_kind?(:password, :blank)).to be_truthy
    end

    it "パスワードが8文字未満であるときは無効な状態であること" do
      user = User.new(password: "Pass123")
      user.valid?
      expect(user.errors.of_kind?(:password, :too_short)).to be_truthy
    end

    it "パスワードが128文字を超えたら無効な状態であること" do
      user = User.new(password: "#{"Ab1" * 43}")
      user.valid?
      expect(user.errors.of_kind?(:password, :too_long)).to be_truthy
    end

    it "パスワードが英文字のみでは無効な状態であること" do
      user = User.new(password: "InvalidPassword")
      user.valid?
      expect(user.errors.of_kind?(:password, :invalid)).to be_truthy
    end

    it "パスワードが数字のみでは無効な状態であること" do
      user = User.new(password: "12345678")
      user.valid?
      expect(user.errors.of_kind?(:password, :invalid)).to be_truthy
    end

    it "パスワードが特殊文字のみでは無効な状態であること" do
      user = User.new(password: "!@#$%^")
      user.valid?
      expect(user.errors.of_kind?(:password, :invalid)).to be_truthy
    end

    it "パスワードに特殊文字が含まれているときは無効な状態であること" do
      user = User.new(password: "Password1!")
      user.valid?
      expect(user.errors.of_kind?(:password, :invalid)).to be_truthy
    end

    it "パスワードとパスワード確認(password_confirmation属性)の値が異なるときは無効な状態であること" do
      user = User.new(
        password: "ValidPass1",
        password_confirmation: "DifferentPass1"
      )
      user.valid?
      expect(user.errors.of_kind?(:password_confirmation, :confirmation)).to be_truthy
    end
  end

  describe "boolean型カラムのデフォルト値" do
    let(:user) { User.new }

    it "ユーザー区分(admin属性)の値は指定がなければ一般ユーザー(false)であること" do
      expect(user.admin).to eq false
    end

    it "ひらがなモード(hiragana_view属性)の値は指定がなければOFF(false)であること" do
      expect(user.hiragana_view).to eq false
    end
  end

  describe ".master_admin_user" do
    context "マスター管理ユーザーが存在する場合" do
      let(:admin_user_email_original) { ENV['ADMIN_USER_EMAIL'] }
      let(:master_user) do
        User.create(
          email: ENV['ADMIN_USER_EMAIL'],
          name: "マスター管理ユーザー",
          password: "Password1",
        )
      end

      before do
        admin_user_email_original
        ENV['ADMIN_USER_EMAIL'] = "master_admin_user@example.com"
        master_user
      end

      after do
        ENV['ADMIN_USER_EMAIL'] = admin_user_email_original
      end

      it "マスター管理ユーザーを返すこと" do
        user = User.master_admin_user
        expect(user).to eq master_user
        expect(user.email).to eq "master_admin_user@example.com"
      end
    end

    context "マスター管理ユーザーが存在しない場合" do
      it "ActiveRecord::RecordNotFoundが発生すること" do
        expect { User.master_admin_user }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe ".guest" do
    context "ゲストユーザーが存在する場合" do
      let!(:existing_guest_user) do
        User.create(
          email: 'guest@example.com',
          name: "ゲストユーザー",
          password: "Password1",
          confirmed_at: Time.current
        )
      end

      it "登録済みのゲストユーザーを返すこと" do
        expect { User.guest }.to_not change { User.count }

        guest_user = User.guest
        expect(guest_user.id).to eq existing_guest_user.id
      end
    end

    context "ゲストユーザーが存在しない場合" do
      let(:guest_email) { 'guest@example.com' }
      let(:guest_name) { "ゲストユーザー" }

      it "ゲストユーザーを登録すること" do
        expect { User.guest }.to change { User.count }.by(1)

        guest_user = User.find_by(email: guest_email)
        expect(guest_user.name).to eq guest_name
        expect(guest_user).to be_confirmed
      end
    end
  end

  describe ".generate_guest_password" do
    let(:valid_password_regex) { /\A(?=.*[a-z])(?=.*\d)[a-z\d]+\z/i }
    let(:sequre_random_urlsafe_base64_regex) { /\A[\w-]{22}\z/ }
    let(:valid_password_length_min) { 8 }
    let(:valid_password_length_max) { 128 }

    it "有効なパスワードを生成すること" do
      password = User.send(:generate_guest_password)

      expect(password).to be_present
      expect(password).to match valid_password_regex
      expect(password).to match sequre_random_urlsafe_base64_regex
      expect(password.length).to be_between(valid_password_length_min, valid_password_length_max).inclusive
    end
  end

  describe "#master_admin_user?" do
    let(:admin_user_email_original) { ENV['ADMIN_USER_EMAIL'] }
    let(:master_user) do
      User.create(
        email: ENV['ADMIN_USER_EMAIL'],
        name: "マスター管理ユーザー",
        password: "Password1"
      )
    end

    before do
      admin_user_email_original
      ENV['ADMIN_USER_EMAIL'] = "master_admin_user@example.com"
      master_user
    end

    after do
      ENV['ADMIN_USER_EMAIL'] = admin_user_email_original
    end

    context "マスター管理ユーザーがレシーバーの場合" do
      it "trueを返すこと" do
        expect(master_user.master_admin_user?).to be_truthy
      end
    end

    context "マスター管理ユーザー以外がレシーバーの場合" do
      let(:no_master_admin_user) do
        User.create(
          name: "テストユーザー",
          email: "test-valid-mail@example.com",
          password: "Password1"
        )
      end

      it "falseを返すこと" do
        expect(no_master_admin_user.master_admin_user?).to be_falsey
      end
    end
  end

  describe "#guest?" do
    let(:guest_user) { User.guest }

    context "ゲストユーザーがレシーバーの場合" do
      it "trueを返すこと" do
        expect(guest_user.guest?).to be_truthy
      end
    end

    context "ゲストユーザー以外がレシーバーの場合" do
      let(:no_guest_user) do
        User.create(
          name: "テストユーザー",
          email: "test-valid-mail@example.com",
          password: "Password1"
        )
      end

      it "falseを返すこと" do
        expect(no_guest_user.id).to_not eq guest_user.id

        expect(no_guest_user.guest?).to be_falsey
      end
    end
  end

  describe "コールバック" do
    let(:admin_user_email_original) { ENV['ADMIN_USER_EMAIL'] }
    let(:master_user) do
      User.create(
        email: ENV['ADMIN_USER_EMAIL'],
        admin: true,
        name: "マスター管理ユーザー",
        password: "Password1"
      )
    end

    before do
      admin_user_email_original
      ENV['ADMIN_USER_EMAIL'] = "master_admin_user@example.com"
      master_user
    end

    after do
      ENV['ADMIN_USER_EMAIL'] = admin_user_email_original
    end

    describe "#prevent_master_admin_change" do
      context "マスター管理ユーザーの場合" do
        before do
          expect(master_user.master_admin_user?).to be_truthy
        end

        it "ユーザー区分(admin属性)が変更できないこと" do
          expect { master_user.update(admin: false) }.to_not change { User.master_admin_user.admin }
          expect(master_user.errors.of_kind?(:admin, "は変更できません。マスター管理ユーザーの権限変更は制限されています。")).to be_truthy
        end

        # deviseのメール認証を介する場合のemailのupdate処理（フォームからの更新を想定）
        it "unconfirmed_email属性が変更できないこと" do
          expect(master_user.unconfirmed_email).to eq nil

          expect { master_user.update(unconfirmed_email: "test-email@example.com") }.
            to_not change { User.master_admin_user.unconfirmed_email }
          expect(master_user.errors.of_kind?(:email, "は変更できません。マスター管理ユーザーのメールアドレス変更は制限されています。")).to be_truthy
        end

        # deviseのメール認証をスキップする場合のemailのupdate処理（管理画面からの更新を想定）
        it "メールアドレスが変更できないこと" do
          master_user.skip_reconfirmation!

          expect { master_user.update(email: "test-email@example.com") }.to_not change { User.master_admin_user.email }
          expect(master_user.errors.of_kind?(:email, "は変更できません。マスター管理ユーザーのメールアドレス変更は制限されています。")).to be_truthy
        end
      end

      context "一般ユーザーの場合" do
        let(:general_user) do
          User.create(
            admin: false,
            name: "テストユーザー",
            email: "test-valid-mail@example.com",
            password: "Password1"
          )
        end

        it "ユーザー区分(admin属性)が変更できること" do
          expect { general_user.update(admin: true) }.to change { general_user.reload.admin }.from(false).to(true)
        end

        # deviseのメール認証を介する場合のemailのupdate処理（フォームからの更新を想定）
        it "unconfirmed_email属性が変更できること" do
          expect { general_user.update(unconfirmed_email: "change-email@example.com") }.
            to change { general_user.reload.unconfirmed_email }.from(nil).to("change-email@example.com")
        end

        # deviseのメール認証をスキップする場合のemailのupdate処理（管理画面からの更新を想定）
        it "メールアドレスが変更できること" do
          general_user.skip_reconfirmation!

          expect { general_user.update(email: "change-email@example.com") }.
            to change { general_user.reload.email }.from("test-valid-mail@example.com").to("change-email@example.com")
        end
      end
    end

    describe "#prevent_master_admin_delete" do
      context "マスター管理ユーザーの場合" do
        it "ユーザーを削除できないこと" do
          expect(master_user.master_admin_user?).to be_truthy

          expect { master_user.destroy }.to_not change { User.count }
          expect(master_user.errors.of_kind?(:base, "マスター管理ユーザーのアカウント削除は制限されています。")).to be_truthy
        end
      end

      context "一般ユーザーの場合" do
        let!(:general_user) do
          User.create(
            admin: false,
            name: "テストユーザー",
            email: "test-valid-mail@example.com",
            password: "Password1"
          )
        end

        it "ユーザーを削除できること" do
          expect(general_user.master_admin_user?).to be_falsey
          expect(general_user.guest?).to be_falsey

          expect { general_user.destroy }.to change { User.count }.by(-1)
        end
      end

      context "ゲストユーザーの場合" do
        let(:guest_user) { User.guest }

        it "ユーザーを削除できること" do
          expect(guest_user.guest?).to be_truthy

          expect { guest_user.destroy }.to change { User.count }.by(-1)
        end
      end
    end

    describe "#prevent_guest_change" do
      let(:guest_user) { User.guest }

      context "ゲストユーザーの場合" do
        before do
          expect(guest_user.guest?).to be_truthy
        end

        it "ユーザー区分(admin属性)が変更できないこと" do
          expect(guest_user.admin).to be_falsey

          expect { guest_user.update(admin: true) }.to_not change { guest_user.reload.admin }
          expect(guest_user.errors.of_kind?(:admin, "は変更できません。ゲストユーザーの権限変更は制限されています。")).to be_truthy
        end

        it "ニックネームが変更できないこと" do
          expect(guest_user.name).to eq "ゲストユーザー"

          expect { guest_user.update(name: "変更後ゲストユーザー") }.to_not change { guest_user.reload.name }
          expect(guest_user.errors.of_kind?(:name, "は変更できません。ゲストユーザーのニックネーム変更は制限されています。")).to be_truthy
        end

        # deviseのメール認証を介する場合のemailのupdate処理（フォームからの更新を想定）
        it "unconfirmed_email属性が変更できないこと" do
          expect(guest_user.unconfirmed_email).to eq nil

          expect { guest_user.update(unconfirmed_email: "change-guest@example.com") }.
            to_not change { guest_user.reload.unconfirmed_email }
          expect(guest_user.errors.of_kind?(:email, "は変更できません。ゲストユーザーのメールアドレス変更は制限されています。")).to be_truthy
        end

        # deviseのメール認証をスキップする場合のemailのupdate処理（管理画面からの更新を想定）
        it "メールアドレスが変更できないこと" do
          expect(guest_user.email).to eq "guest@example.com"

          expect { guest_user.update(email: "change-guest@example.com") }.to_not change { guest_user.reload.email }
          expect(guest_user.errors.of_kind?(:email, "は変更できません。ゲストユーザーのメールアドレス変更は制限されています。")).to be_truthy
        end

        it "パスワード(encrypted_password属性)が変更できないこと" do
          before_encrypted_password = guest_user.encrypted_password

          expect { guest_user.update(password: "ChangePassword123") }.to_not change { guest_user.reload.encrypted_password }
          expect(guest_user.errors.of_kind?(:password, "は変更できません。ゲストユーザーのパスワード変更は制限されています。")).to be_truthy
          expect(guest_user.encrypted_password).to eq before_encrypted_password
        end
      end

      context "マスター管理ユーザーの場合" do
        before do
          expect(master_user.guest?).to be_falsey
        end

        it "ニックネームが変更できること" do
          expect { master_user.update(name: "変更後マスター管理ユーザー") }.
            to change { master_user.reload.name }.from("マスター管理ユーザー").to("変更後マスター管理ユーザー")
        end

        it "パスワード(encrypted_password属性)が変更できること" do
          before_encrypted_password = master_user.encrypted_password

          expect { master_user.update(password: "ChangePassword123") }.to change { master_user.reload.encrypted_password }
          expect(master_user.encrypted_password).to_not eq before_encrypted_password
        end
      end

      context "一般ユーザーの場合" do
        let!(:general_user) do
          User.create(
            admin: false,
            name: "テストユーザー",
            email: "test-valid-mail@example.com",
            password: "Password1"
          )
        end

        before do
          expect(general_user.guest?).to be_falsey
        end

        it "ニックネームが変更できること" do
          expect { general_user.update(name: "変更後テストユーザー") }.
            to change { general_user.reload.name }.from("テストユーザー").to("変更後テストユーザー")
        end

        # deviseのメール認証を介する場合のemailのupdate処理（フォームからの更新を想定）
        it "unconfirmed_email属性が変更できること" do
          expect { general_user.update(unconfirmed_email: "change-email@example.com") }.
            to change { general_user.reload.unconfirmed_email }.from(nil).to("change-email@example.com")
        end

        # deviseのメール認証をスキップする場合のemailのupdate処理（管理画面からの更新を想定）
        it "メールアドレスが変更できること" do
          general_user.skip_reconfirmation!

          expect { general_user.update(email: "change-email@example.com") }.
            to change { general_user.reload.email }.from("test-valid-mail@example.com").to("change-email@example.com")
        end

        it "パスワード(encrypted_password属性)が変更できること" do
          before_encrypted_password = general_user.encrypted_password

          expect { general_user.update(password: "ChangePassword123") }.to change { general_user.reload.encrypted_password }
          expect(general_user.encrypted_password).to_not eq before_encrypted_password
        end
      end
    end
  end

  describe "アソシエーション" do
    let(:association) { described_class.reflect_on_association(model) }

    subject { association.macro }

    context "Itemモデルとの関係性" do
      let(:model) { :items }

      it { is_expected.to eq :has_many }
    end

    context "Buyモデルとの関係性" do
      let(:model) { :buys }

      it { is_expected.to eq :has_many }
    end

    context "ShoppingRecordモデルとの関係性" do
      let(:model) { :shopping_records }

      it { is_expected.to eq :has_many }
    end

    context "NotificationTargetUserモデルとの関係性" do
      let(:model) { :notification_target_users }

      it { is_expected.to eq :has_many }
    end
  end

  describe "dependent:" do
    let!(:user) do
      User.create(
        admin: false,
        name: "テストユーザー",
        email: "test-valid-mail@example.com",
        password: "Password1",
        confirmed_at: Time.current
      )
    end

    before do
      FactoryBot.create(:user, :master_admin)
    end

    describe ":delete_all" do
      context "Itemモデル" do
        let(:category) { FactoryBot.create(:category) }

        it "ユーザーを削除するとユーザーが登録したアイテムも削除されること" do
          FactoryBot.create(:item, user: user, category: category)

          expect { user.destroy }.to change { Item.count }.by(-1)
        end
      end

      context "Buyモデル" do
        let(:shopping_record) { FactoryBot.create(:shopping_record, user: user) }

        it "ユーザーを削除するとユーザーが登録した購入履歴も削除されること" do
          FactoryBot.create(:buy, user: user, shopping_record: shopping_record)

          expect { user.destroy }.to change { Buy.count }.by(-1)
        end
      end

      context "NotificationTargetUserモデル" do
        it "ユーザーを削除するとユーザーが登録した通知対象ユーザーも削除されること" do
          FactoryBot.create(:notification_target_user, user: user)

          expect { user.destroy }.to change { NotificationTargetUser.count }.by(-1)
        end
      end
    end

    describe ":destroy" do
      context "ShoppingRecordモデル" do
        it "ユーザーを削除するとユーザーが登録したお買い物も削除されること" do
          FactoryBot.create(:shopping_record, user: user)

          expect { user.destroy }.to change { ShoppingRecord.count }.by(-1)
        end
      end
    end
  end
end
