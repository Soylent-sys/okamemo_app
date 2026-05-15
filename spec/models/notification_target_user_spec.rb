require 'rails_helper'

RSpec.describe NotificationTargetUser, type: :model do
  let(:user) { create(:user) }

  context "通知対象ユーザーの登録ができる場合" do
    it "親ユーザーID、ニックネーム、メールアドレスがあれば有効な状態であること" do
      notification_target_user = NotificationTargetUser.new(
        user: user,
        name: "テスト通知対象ユーザー",
        email: "test-notification-target@example.com"
      )
      expect(notification_target_user).to be_valid
    end
  end

  context "通知対象ユーザーの登録ができない場合" do
    it "親ユーザーIDがなければ無効な状態であること" do
      notification_target_user = NotificationTargetUser.new(user: nil)
      notification_target_user.valid?
      expect(notification_target_user.errors.of_kind?(:user, :blank)).to be_truthy
    end

    it "ニックネームがなければ無効な状態であること" do
      notification_target_user = NotificationTargetUser.new(name: nil)
      notification_target_user.valid?
      expect(notification_target_user.errors.of_kind?(:name, :blank)).to be_truthy
    end

    it "ニックネームが空文字のときは無効な状態であること" do
      notification_target_user = NotificationTargetUser.new(name: "")
      notification_target_user.valid?
      expect(notification_target_user.errors.of_kind?(:name, :blank)).to be_truthy
    end

    it "ニックネームが20文字を超えたら無効な状態であること" do
      notification_target_user = NotificationTargetUser.new(name: "a" * 21)
      notification_target_user.valid?
      expect(notification_target_user.errors.of_kind?(:name, :too_long)).to be_truthy
    end

    it "メールアドレスがなければ無効な状態であること" do
      notification_target_user = NotificationTargetUser.new(email: nil)
      notification_target_user.valid?
      expect(notification_target_user.errors.of_kind?(:email, :blank)).to be_truthy
    end

    it "メールアドレスが空文字のときは無効な状態であること" do
      notification_target_user = NotificationTargetUser.new(email: "")
      notification_target_user.valid?
      expect(notification_target_user.errors.of_kind?(:email, :blank)).to be_truthy
    end

    it "メールアドレスが255文字を超えたら無効な状態であること" do
      notification_target_user = NotificationTargetUser.new(email: "#{"a" * 244}@example.com")
      notification_target_user.valid?
      expect(notification_target_user.errors.of_kind?(:email, :too_long)).to be_truthy
    end

    it "メールアドレスが正しいフォーマットでないときは無効な状態であること" do
      notification_target_user = NotificationTargetUser.new(email: "invalid_email")
      notification_target_user.valid?
      expect(notification_target_user.errors.of_kind?(:email, :invalid)).to be_truthy
    end

    it "親ユーザーIDとメールアドレスが重複しているときは無効な状態であること" do
      NotificationTargetUser.create(
        user: user,
        name: "テスト通知対象ユーザー",
        email: "test-notification-target@example.com",
        confirmation_status: :confirmed
      )
      notification_target_user = NotificationTargetUser.new(
        user: user,
        name: "別のテスト通知対象ユーザー",
        email: "test-notification-target@example.com"
      )
      notification_target_user.valid?
      expect(notification_target_user.errors.of_kind?(:email, :taken)).to be_truthy
    end
  end

  describe "enum型カラム confirmation_status" do
    it "有効な認証状態(confirmation_status)が存在すること" do
      enum_hash = { "unconfirmed" => 0, "confirmed" => 1 }
      expect(NotificationTargetUser.confirmation_statuses).to eq(enum_hash)
    end

    describe "デフォルト値" do
      let(:notification_target_user) { NotificationTargetUser.new }

      it "認証状態(confirmation_status属性)の値は指定がなければ unconfirmed であること" do
        expect(notification_target_user.confirmation_status).to eq("unconfirmed")
      end
    end

    describe "enum インスタンスメソッド" do
      let(:notification_target_user) { NotificationTargetUser.new(confirmation_status: :unconfirmed) }

      it "認証状態がunconfirmedであるときはunconfirmed?メソッドに対しtrueを返すこと" do
        expect(notification_target_user.unconfirmed?).to be_truthy
      end

      it "認証状態がunconfirmedであるときはconfirmed?メソッドに対しfalseを返すこと" do
        expect(notification_target_user.confirmed?).to be_falsey
      end
    end

    describe "enum スコープメソッド" do
      let(:unconfirmed_nt_user) { create(:notification_target_user, user: user, confirmation_status: :unconfirmed) }
      let(:confirmed_nt_user) { create(:notification_target_user, user: user, confirmation_status: :confirmed) }

      it "unconfirmedスコープに対して認証状態がunconfirmedの通知対象ユーザーのみを返すこと" do
        expect(NotificationTargetUser.unconfirmed).to include(unconfirmed_nt_user)
        expect(NotificationTargetUser.unconfirmed).to_not include(confirmed_nt_user)
      end
    end

    describe "無効な値による登録の制御" do
      it "無効な認証状態を設定した場合はエラーが発生すること" do
        expect { NotificationTargetUser.new(confirmation_status: :invalid_status) }.to raise_error(ArgumentError)
      end
    end

    describe "状態変更のテスト" do
      let(:notification_target_user) { create(:notification_target_user, user: user, confirmation_status: :unconfirmed) }

      it "認証状態の変更が可能であること" do
        notification_target_user.confirmation_status = :confirmed
        expect(notification_target_user.confirmed?).to be_truthy
      end
    end
  end

  describe "カスタムバリデーション" do
    describe "#check_count" do
      let!(:notification_target_users) { create_list(:notification_target_user, 3, user: user) }

      it "通知対象ユーザーが3つを超えたら無効な状態であること" do
        notification_target_user = NotificationTargetUser.new(
          user: user,
          name: "4人目のテスト通知対象ユーザー",
          email: "over-test-notification-target@example.com"
        )
        notification_target_user.valid?
        error_message = "の登録数が最大数（#{NotificationTargetUser::NOTIFICATION_TARGET_USER_MUXIMUM_COUNT}つ）に達しています。"
        expect(notification_target_user.errors.of_kind?(:notification_target_user, error_message)).to be_truthy
      end
    end
  end

  describe ".confirmation_new_token" do
    let(:sequre_random_urlsafe_base64_n47_regex) { /\A[\w-]{63}\z/ }

    it "63文字のトークンを生成すること" do
      token = NotificationTargetUser.confirmation_new_token

      expect(token).to be_present
      expect(token).to match(sequre_random_urlsafe_base64_n47_regex)
    end

    context "重複したトークンが生成された場合" do
      let!(:notification_target_user) { create(:notification_target_user, user: user, confirmation_token: "duplicate_token") }

      it "ユニークなトークンを返すまで処理を繰り返すこと" do
        # モックを使用してSecureRandom.urlsafe_base64が2回重複したトークンを生成し、その後に一意のトークンを生成するように設定
        allow(SecureRandom).to receive(:urlsafe_base64).and_return("duplicate_token", "duplicate_token", "unique_token")
        token = NotificationTargetUser.confirmation_new_token

        expect(token).to eq("unique_token")
        expect(NotificationTargetUser.exists?(confirmation_token: token)).to be_falsey
      end
    end
  end

  describe "#expired?" do
    let(:notification_target_user) { create(:notification_target_user, :unconfirmed, user: user, expiration_date: time) }

    # 明示的にセットした有効期限(expiration_date属性)でメソッドの評価を確認したいため、
    # set_email_confirmationコールバックメソッドをスキップして有効期限が自動でセットされないようにする
    include_context "skip call back set_email_confirmation"

    context "有効期限(expiration_date属性)が現在時刻よりも前の場合" do
      let(:time) { Time.current - 1.minutes }

      it "trueを返すこと" do
        expect(notification_target_user.expired?).to be_truthy
      end
    end

    context "有効期限(expiration_date属性)が現在時刻よりも後の場合" do
      let(:time) { Time.current + 1.minutes }

      it "falseを返すこと" do
        expect(notification_target_user.expired?).to be_falsey
      end
    end

    context "有効期限(expiration_date属性)が存在しない場合" do
      let(:time) { nil }

      it "falseを返すこと" do
        expect(notification_target_user.expired?).to be_falsey
      end
    end
  end

  describe "#activate" do
    context "認証状態(confirmation_status属性)が未認証(unconfirmed)の場合" do
      let(:notification_target_user) do
        create(
          :notification_target_user,
          user: user,
          confirmation_status: :unconfirmed,
          confirmation_token: "token",
          expiration_date: Time.current
        )
      end

      # 明示的にセットしたトークン(confirmation_token属性)と有効期限(expiration_date属性)をメソッドの実行で更新されるか確認したいため、
      # set_email_confirmationコールバックメソッドをスキップしてトークンと有効期限が自動でセットされないようにする
      include_context "skip call back set_email_confirmation"

      it "認証状態をconfirmedに更新すること" do
        expect { notification_target_user.activate }.to change(notification_target_user, :confirmation_status).to("confirmed")
      end

      it "認証トークンをnilに更新すること" do
        expect { notification_target_user.activate }.to change(notification_target_user, :confirmation_token).to(nil)
      end

      it "有効期限をnilに更新すること" do
        expect { notification_target_user.activate }.to change(notification_target_user, :expiration_date).to(nil)
      end
    end

    context "認証状態(confirmation_status属性)が認証済み(confirmed)の場合" do
      let(:notification_target_user) do
        create(
          :notification_target_user,
          user: user,
          confirmation_status: :confirmed,
          confirmation_token: nil,
          expiration_date: nil
        )
      end

      it "認証状態が更新されないこと" do
        expect { notification_target_user.activate }.to_not change(notification_target_user, :confirmation_status)
      end

      it "認証トークンが更新されないこと" do
        expect { notification_target_user.activate }.to_not change(notification_target_user, :confirmation_token)
      end

      it "有効期限が更新されないこと" do
        expect { notification_target_user.activate }.to_not change(notification_target_user, :expiration_date)
      end
    end
  end

  describe "#reset_email_confirmation" do
    let(:notification_target_user) do
      create(
        :notification_target_user,
        user: user,
        confirmation_status: :unconfirmed,
        confirmation_token: "existing_token",
        expiration_date: 1.day.ago
      )
    end

    # 明示的にセットしたトークン(confirmation_token属性)と有効期限(expiration_date属性)をメソッドの実行で更新されるか確認したいため、
    # set_email_confirmationコールバックメソッドをスキップしてトークンと有効期限が自動でセットされないようにする
    include_context "skip call back set_email_confirmation"

    context "認証状態(confirmation_status属性)が未認証(unconfirmed)の場合" do
      it "認証トークンと有効期限が新しい値に更新されること" do
        expect(notification_target_user).to receive(:set_email_confirmation).and_call_original

        notification_target_user.reset_email_confirmation

        expect(notification_target_user.confirmation_token).to_not eq("existing_token")
        expect(notification_target_user.expiration_date).to be > Time.current
      end

      it "有効期限が正しく設定されていること" do
        notification_target_user.reset_email_confirmation

        expect(notification_target_user.expiration_date).
          to be_within(1.second).of(Time.current + NotificationTargetUser::EMAIL_CONFIRMATION_LIMIT.minutes)
      end
    end

    context "認証状態(confirmation_status属性)が認証済み(confirmed)の場合" do
      let(:notification_target_user) do
        create(
          :notification_target_user,
          user: user,
          confirmation_status: :confirmed,
          confirmation_token: nil,
          expiration_date: nil
        )
      end

      it "認証トークンが更新されないこと" do
        expect { notification_target_user.reset_email_confirmation }.to_not change(notification_target_user, :confirmation_token)
      end

      it "有効期限が更新されないこと" do
        expect { notification_target_user.reset_email_confirmation }.to_not change(notification_target_user, :expiration_date)
      end
    end
  end

  describe "コールバック" do
    describe "#downcase_email" do
      let(:notification_target_user) { build(:notification_target_user, user: user, email: "TEST-NT-USER@EXAMPLE.COM") }

      it "メールアドレスが大文字のときは小文字に変換して保存すること" do
        expect { notification_target_user.save }.
          to change(notification_target_user, :email).from("TEST-NT-USER@EXAMPLE.COM").to("test-nt-user@example.com")
      end
    end

    describe "#set_email_confirmation" do
      context "未認証の通知対象ユーザーを作成する場合" do
        let(:notification_target_user) { build(:notification_target_user, user: user, confirmation_status: "unconfirmed") }

        before do
          expect(notification_target_user.unconfirmed?).to be_truthy
          notification_target_user.save
        end

        it "認証トークン(confirmation_token属性)がセットされること" do
          expect(notification_target_user.confirmation_token).to_not be_nil
        end

        it "有効期限(expiration_date属性)が正しい値でセットされること" do
          expect(notification_target_user.expiration_date).
            to be_within(1.second).of(Time.current + NotificationTargetUser::EMAIL_CONFIRMATION_LIMIT.minutes)
        end
      end

      context "認証済みの通知対象ユーザーを作成する場合" do
        let(:notification_target_user) { build(:notification_target_user, user: user, confirmation_status: "confirmed") }

        before do
          expect(notification_target_user.confirmed?).to be_truthy
          notification_target_user.save
        end

        it "認証トークン(confirmation_token属性)がセットされないこと" do
          expect(notification_target_user.confirmation_token).to be_nil
        end

        it "有効期限(expiration_date属性)がセットされないこと" do
          expect(notification_target_user.expiration_date).to be_nil
        end
      end
    end
  end

  describe "アソシエーション" do
    let(:association) { described_class.reflect_on_association(model) }

    subject { association.macro }

    context "Userモデルとの関係性" do
      let(:model) { :user }

      it { is_expected.to eq(:belongs_to) }
    end
  end

  describe "スコープ" do
    describe "old_created" do
      let!(:notification_target_user_newest) { create(:notification_target_user, user: user, created_at: Time.current) }
      let!(:notification_target_user_new) { create(:notification_target_user, user: user, created_at: 1.day.ago) }
      let!(:notification_target_user_old) { create(:notification_target_user, user: user, created_at: 2.days.ago) }

      it "作成日時が古い順にソートすること" do
        expect(NotificationTargetUser.old_created).
          to eq([notification_target_user_old, notification_target_user_new, notification_target_user_newest])
      end
    end
  end

  # hashid-railsを使用したIDハッシュ化に対するテスト
  describe "#hashid" do
    let(:notification_target_user) { create(:notification_target_user, id: 1, user: user) }

    it "有効な通知対象ユーザーのハッシュIDを返すこと" do
      # 通知対象ユーザーIDをハッシュ化（整数→文字列）できているか検証
      hashid = notification_target_user.hashid
      expect(hashid).to be_a(String)
      # ハッシュ化したIDを元のIDにデコードできているかを検証
      decode_id = notification_target_user.class.decode_id(hashid)
      expect(decode_id).to eq(notification_target_user.id)
    end
  end
end
