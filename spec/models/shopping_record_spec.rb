require 'rails_helper'

RSpec.describe ShoppingRecord, type: :model do
  let(:user) { create(:user) }

  context "お買い物の登録ができる場合" do
    it "ユーザーIDとタイトルがあれば有効な状態であること" do
      shopping_record = ShoppingRecord.new(
        user: user,
        title: "テストのお買い物"
      )
      expect(shopping_record).to be_valid
    end
  end

  context "お買い物の登録ができない場合" do
    it "ユーザーIDがなければ無効な状態であること" do
      shopping_record = ShoppingRecord.new(user: nil)
      shopping_record.valid?
      expect(shopping_record.errors.of_kind?(:user, :blank)).to be_truthy
    end

    it "タイトルがなければ無効な状態であること" do
      shopping_record = ShoppingRecord.new(title: nil)
      shopping_record.valid?
      expect(shopping_record.errors.of_kind?(:title, :blank)).to be_truthy
    end

    it "タイトルが空文字のときは無効な状態であること" do
      shopping_record = ShoppingRecord.new(title: nil)
      shopping_record.valid?
      expect(shopping_record.errors.of_kind?(:title, :blank)).to be_truthy
    end

    it "タイトルが40文字を超えたら無効な状態であること" do
      shopping_record = ShoppingRecord.new(title: "a" * 41)
      shopping_record.valid?
      expect(shopping_record.errors.of_kind?(:title, :too_long)).to be_truthy
    end
  end

  describe "boolean型カラムのデフォルト値" do
    let(:shopping_record) { ShoppingRecord.new }

    it "お買い物完了状態(closed属性)の値は指定がなければ未完了(false)であること" do
      expect(shopping_record.closed).to eq false
    end
  end

  describe ".first_record_by_month" do
    context "引数のユーザーに完了済みのお買い物が存在する場合" do
      let(:time_current) { Time.current }
      let!(:shopping_record_now_1) { create(:shopping_record, closed: true, user: user, updated_at: time_current) }
      let!(:shopping_record_now_2) { create(:shopping_record, closed: true, user: user, updated_at: time_current + ten_second) }
      let(:ten_second) { 10 }
      let!(:shopping_record_one_month_ago) do
        create(:shopping_record, closed: true, user: user, updated_at: time_current - 1.month)
      end
      let!(:opened_shopping_record) { create(:shopping_record, closed: false, user: user, updated_at: time_current - 2.month) }
      let(:other_user) { create(:user) }
      let!(:other_user_create_shopping_record) do
        create(:shopping_record, closed: true, user: other_user, updated_at: time_current - 3.month)
      end

      it "引数のユーザーの月毎に完了している最初のお買い物を返すこと" do
        shopping_records = ShoppingRecord.first_record_by_month(user)

        expect(shopping_records).to contain_exactly(shopping_record_now_1, shopping_record_one_month_ago)
      end
    end

    context "引数のユーザーに完了済みのお買い物が存在しない場合" do
      let(:non_record_user) { create(:user) }

      it "空の配列を返すこと" do
        expect(ShoppingRecord.first_record_by_month(non_record_user)).to be_empty
      end
    end
  end

  describe ".extract_one_month" do
    let(:time_current) { Time.current }
    let!(:shopping_record_now_1) { create(:shopping_record, closed: true, user: user, updated_at: time_current) }
    let!(:shopping_record_now_2) { create(:shopping_record, closed: true, user: user, updated_at: time_current) }
    let!(:shopping_record_one_month_ago) do
      create(:shopping_record, closed: true, user: user, updated_at: time_current - 1.month)
    end
    let!(:opened_shopping_record) { create(:shopping_record, closed: false, user: user, updated_at: time_current) }
    let(:other_user) { create(:user) }
    let!(:other_user_shopping_record) do
      create(:shopping_record, closed: true, user: other_user, updated_at: time_current)
    end

    context "第一引数のユーザーが第二引数の指定年月（:date_ymフォーマット変換後の年月）に完了しているお買い物を持っている場合" do
      it "引数のユーザーおよび引数の指定年月の完了している全てのお買い物を返すこと" do
        shopping_records = ShoppingRecord.extract_one_month(user, time_current.to_fs(:date_ym))

        expect(shopping_records).to contain_exactly(shopping_record_now_1, shopping_record_now_2)
      end
    end

    context "第一引数のユーザーが第二引数の指定年月（:date_ymフォーマット変換後の年月）に完了しているお買い物を持たない場合" do
      let(:non_record_month) { time_current - 2.month }

      it "空の配列を返すこと" do
        expect(ShoppingRecord.extract_one_month(user, non_record_month.to_fs(:date_ym))).to be_empty
      end
    end
  end

  describe "アソシエーション" do
    let(:association) { described_class.reflect_on_association(model) }

    subject { association.macro }

    context "Userモデルとの関係性" do
      let(:model) { :user }

      it { is_expected.to eq :belongs_to }
    end

    context "ShoppingLocationモデルとの関係性" do
      let(:model) { :shopping_location }

      it { is_expected.to eq :has_one }
    end

    context "Buyモデルとの関係性" do
      let(:model) { :buys }

      it { is_expected.to eq :has_many }
    end
  end

  describe "dependent:" do
    let(:shopping_record) { create(:shopping_record, user: user) }

    describe ":delete" do
      context "ShoppingLocationモデル" do
        it "お買い物を削除するとそのお買い物に属するお買い物場所も削除されること" do
          create(:shopping_location, shopping_record: shopping_record)

          expect { shopping_record.destroy }.to change { ShoppingLocation.count }.by(-1)
        end
      end
    end

    describe ":delete_all" do
      context "Buyモデル" do
        it "お買い物を削除するとそのお買い物に属する購入記録も削除されること" do
          create(:buy, user: user, shopping_record: shopping_record)

          expect { shopping_record.destroy }.to change { Buy.count }.by(-1)
        end
      end
    end
  end

  describe "スコープ" do
    describe "opened" do
      let!(:opened_shopping_record) { create(:shopping_record, user: user, closed: false) }
      let!(:closed_shopping_record) { create(:shopping_record, user: user, closed: true) }

      it "未完了（closed: false）のお買い物を返すこと" do
        expect(ShoppingRecord.opened).to contain_exactly(opened_shopping_record)
      end

      it "お買い物が存在しない場合は空の配列を返すこと" do
        ShoppingRecord.delete_all
        expect(ShoppingRecord.opened).to be_empty
      end
    end

    describe "closed" do
      let!(:opened_shopping_record) { create(:shopping_record, user: user, closed: false) }
      let!(:closed_shopping_record) { create(:shopping_record, user: user, closed: true) }

      it "完了済み（closed: true）のお買い物を返すこと" do
        expect(ShoppingRecord.closed).to contain_exactly(closed_shopping_record)
      end

      it "お買い物が存在しない場合は空の配列を返すこと" do
        ShoppingRecord.delete_all
        expect(ShoppingRecord.closed).to be_empty
      end
    end

    describe "recent_updated" do
      let!(:shopping_record_updated_old) { create(:shopping_record, user: user, updated_at: Time.current - 1.day) }
      let!(:shopping_record_updated_new) { create(:shopping_record, user: user, updated_at: Time.current) }

      it "更新日時（updated_at）の降順（新しい順）でお買い物を返すこと" do
        expect(ShoppingRecord.recent_updated).to eq [shopping_record_updated_new, shopping_record_updated_old]
      end

      it "お買い物が存在しない場合は空の配列を返すこと" do
        ShoppingRecord.delete_all
        expect(ShoppingRecord.recent_updated).to be_empty
      end
    end
  end
end
