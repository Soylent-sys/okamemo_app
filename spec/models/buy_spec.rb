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
end
