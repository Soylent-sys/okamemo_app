require 'rails_helper'

RSpec.describe Buy, type: :model do
  include_context "shopping record setup"

  context "購入記録の登録ができる場合" do
    it "ユーザーID、お買い物ID、アイテム名、アイテム名（ひらがな）があれば有効な状態であること" do
      buy = Buy.new(
        user: user,
        shopping_record: shopping_record,
        item_name: "テストアイテム",
        item_hiragana: "てすとあいてむ"
      )
      expect(buy).to be_valid
    end
  end

  context "購入記録の登録ができない場合" do
    it "ユーザーIDがなければ無効な状態であること" do
      buy = Buy.new(user: nil)
      buy.valid?
      expect(buy.errors.of_kind?(:user, :blank)).to be_truthy
    end

    it "お買い物IDがなければ無効な状態であること" do
      buy = Buy.new(shopping_record: nil)
      buy.valid?
      expect(buy.errors.of_kind?(:shopping_record, :blank)).to be_truthy
    end

    it "アイテム名がなければ無効な状態であること" do
      buy = Buy.new(item_name: nil)
      buy.valid?
      expect(buy.errors.of_kind?(:item_name, :blank)).to be_truthy
    end

    it "アイテム名が空文字のときは無効な状態であること" do
      buy = Buy.new(item_name: "")
      buy.valid?
      expect(buy.errors.of_kind?(:item_name, :blank)).to be_truthy
    end

    it "アイテム名（ひらがな）がなければ無効な状態であること" do
      buy = Buy.new(item_hiragana: nil)
      buy.valid?
      expect(buy.errors.of_kind?(:item_hiragana, :blank)).to be_truthy
    end

    it "アイテム名（ひらがな）が空文字のときは無効な状態であること" do
      buy = Buy.new(item_hiragana: "")
      buy.valid?
      expect(buy.errors.of_kind?(:item_hiragana, :blank)).to be_truthy
    end
  end

  describe "boolean型カラム" do
    describe "purchased属性" do
      let(:buy) { Buy.new }

      it "購入状態(purchased属性)の値は指定がなければ未購入(false)であること" do
        expect(buy.purchased).to eq false
      end

      it "購入状態(purchased属性)の値をtrueに設定できること" do
        buy.purchased = true
        expect(buy.purchased).to be_truthy
      end

      it "購入状態(purchased属性)の値をfalseに設定できること" do
        buy.purchased = false
        expect(buy.purchased).to be_falsey
      end

      context "purchased属性がtrueのとき" do
        before { buy.purchased = true }

        it "purchased?メソッドでtrueを返すこと" do
          expect(buy.purchased?).to be_truthy
        end
      end

      context "purchased属性がfalseのとき" do
        before { buy.purchased = false }

        it "purchased?メソッドでfalseを返すこと" do
          expect(buy.purchased?).to be_falsey
        end
      end
    end
  end

  describe ".last_bought_times" do
    # Itemモデル登録時のvalidateメソッドにマスター管理ユーザーが必要
    let!(:master_user) { create :user, :master_admin }
    let(:user) { create :user }
    let(:category) { create :category }
    let(:user_item1) { create(:item, user: user, category: category, name: "テストアイテム1") }
    let(:shopping_record) { create(:shopping_record, :closed, user: user) }

    context "ユーザー指定のテスト" do
      let(:other_user) { create :user }
      let(:user_item2) { create(:item, user: user, category: category, name: "テストアイテム2") }
      let(:other_user_item) { create(:item, user: other_user, category: category) }
      let(:other_shopping_record) { create(:shopping_record, :closed, user: other_user) }
      let!(:user_buy1) { create(:buy, :purchased, user: user, shopping_record: shopping_record, item_name: user_item1.name) }
      let!(:user_buy2) { create(:buy, :purchased, user: user, shopping_record: shopping_record, item_name: user_item2.name) }
      let!(:other_user_buy) do
        create(:buy, :purchased, user: other_user, shopping_record: other_shopping_record, item_name: other_user.name)
      end

      it "引数ユーザーに紐付くBuyレコードのkey:アイテム名 value:更新日時のハッシュを返すこと" do
        hash = Buy.last_bought_times(user)

        expect(hash.keys).to contain_exactly(user_buy1.item_name, user_buy2.item_name)
        expect(hash[user_buy1.item_name]).to eq user_buy1.updated_at
        expect(hash[user_buy2.item_name]).to eq user_buy2.updated_at
      end
    end

    context "purchasedスコープのテスト" do
      let(:user_item2) { create(:item, user: user, category: category, name: "テストアイテム2") }
      let(:unclosed_shopping_record) { create(:shopping_record, user: user, closed: false) }
      let!(:user_purchased_buy) do
        create(:buy, user: user, shopping_record: shopping_record, item_name: user_item1.name, purchased: true)
      end
      let!(:user_no_purchased_buy) do
        create(:buy, user: user, shopping_record: unclosed_shopping_record, item_name: user_item2.name, purchased: false)
      end

      it "purchased: trueのBuyレコードのkey:アイテム名 value:更新日時のハッシュを返すこと" do
        hash = Buy.last_bought_times(user)

        expect(hash.keys).to contain_exactly(user_purchased_buy.item_name)
        expect(hash[user_purchased_buy.item_name]).to eq user_purchased_buy.updated_at
      end
    end

    context "value:更新日時のテスト" do
      let(:old_shopping_record) { create(:shopping_record, :closed, user: user) }
      let!(:new_buy) do
        create(
          :buy, :purchased,
          user: user,
          shopping_record: shopping_record,
          item_name: user_item1.name,
          updated_at: Time.current
        )
      end
      let!(:old_buy) do
        create(
          :buy, :purchased,
          user: user,
          shopping_record: old_shopping_record,
          item_name: user_item1.name,
          updated_at: 1.minutes.ago
        )
      end

      it "keyに対応するvalueは最新の更新日時であること" do
        hash = Buy.last_bought_times(user)

        expect(hash[user_item1.name]).to eq new_buy.updated_at
      end
    end

    context "カテゴリーを跨いだ同名アイテムのBuyレコードが存在する場合" do
      let(:other_category) { create(:category) }
      let(:other_category_item) { create(:item, user: user, category: other_category, name: user_item1.name) }
      let(:old_shopping_record) { create(:shopping_record, :closed, user: user) }
      let!(:new_buy) do
        create(
          :buy, :purchased,
          user: user,
          shopping_record: shopping_record,
          item_name: user_item1.name,
          updated_at: Time.current
        )
      end
      let!(:old_buy) do
        create(
          :buy, :purchased,
          user: user,
          shopping_record: old_shopping_record,
          item_name: user_item1.name,
          updated_at: 1.minutes.ago
        )
      end

      it "最新更新日時のレコードのvalue:更新日時であること" do
        hash = Buy.last_bought_times(user)

        expect(hash.keys).to contain_exactly(user_item1.name)
        expect(hash[user_item1.name]).to eq new_buy.updated_at
      end
    end

    context "引数ユーザーに purchased: true のBuyレコードが存在しない場合" do
      let!(:no_purchased_buy) do
        create(:buy, user: user, shopping_record: shopping_record, item_name: user_item1.name, purchased: false)
      end

      it "空の配列を返すこと" do
        expect(Buy.last_bought_times(user)).to be_empty
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

    context "ShoppingRecprdモデルとの関係性" do
      let(:model) { :shopping_record }

      it { is_expected.to eq :belongs_to }
    end
  end

  describe "スコープ" do
    let!(:purchased_buy) { create(:buy, user: user, shopping_record: shopping_record, purchased: true) }
    let!(:unpurchased_buy) { create(:buy, user: user, shopping_record: shopping_record, purchased: false) }

    describe "purchased" do
      it "購入済み(purchased: true)の購入記録を返すこと" do
        expect(Buy.purchased).to contain_exactly(purchased_buy)
      end

      it "購入記録が存在しない場合は空の配列を返すこと" do
        Buy.delete_all
        expect(Buy.purchased).to be_empty
      end
    end

    describe "unpurchased" do
      it "未購入(unpurchased: false)の購入記録を返す" do
        expect(Buy.unpurchased).to contain_exactly(unpurchased_buy)
      end

      it "購入記録が存在しない場合は空の配列を返すこと" do
        Buy.delete_all
        expect(Buy.unpurchased).to be_empty
      end
    end
  end

  # hashid-railsを使用したIDハッシュ化に対するテスト
  describe "#hashid" do
    let(:buy) { create(:buy, id: 1, user: user, shopping_record: shopping_record) }

    it "有効な購入記録のハッシュIDを返すこと" do
      # 購入記録IDをハッシュ化（整数→文字列）できているか検証
      hashid = buy.hashid
      expect(hashid).to be_a(String)
      # ハッシュ化したIDを元のIDにデコードできているかを検証
      decode_id = buy.class.decode_id(hashid)
      expect(decode_id).to eq buy.id
    end
  end
end
