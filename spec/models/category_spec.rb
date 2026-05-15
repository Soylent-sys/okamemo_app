require 'rails_helper'

RSpec.describe Category, type: :model do
  context "カテゴリーの登録ができる場合" do
    it "カテゴリー名とカテゴリー名（ひらがな）があれば有効な状態であること" do
      category = Category.new(
        name: "テストカテゴリー",
        hiragana: "てすとかてごりー"
      )
      expect(category).to be_valid
    end
  end

  context "カテゴリーの登録ができない場合" do
    it "カテゴリー名がなければ無効な状態であること" do
      category = Category.new(name: nil)
      category.valid?
      expect(category.errors.of_kind?(:name, :blank)).to be_truthy
    end

    it "カテゴリー名が空文字のときは無効な状態であること" do
      category = Category.new(name: "")
      category.valid?
      expect(category.errors.of_kind?(:name, :blank)).to be_truthy
    end

    it "カテゴリー名が20文字を超えたら無効な状態であること" do
      category = Category.new(name: "a" * 21)
      category.valid?
      expect(category.errors.of_kind?(:name, :too_long)).to be_truthy
    end

    it "カテゴリー名が重複しているときは無効な状態であること" do
      Category.create(
        name: "テストカテゴリー",
        hiragana: "てすとかてごりー1"
      )
      category = Category.new(
        name: "テストカテゴリー",
        hiragana: "てすとかてごりー2"
      )
      category.valid?
      expect(category.errors.of_kind?(:name, :taken)).to be_truthy
    end

    it "カテゴリー名（ひらがな）がなければ無効な状態であること" do
      category = Category.new(hiragana: nil)
      category.valid?
      expect(category.errors.of_kind?(:hiragana, :blank)).to be_truthy
    end

    it "カテゴリー名（ひらがな）が空文字のときは無効な状態であること" do
      category = Category.new(hiragana: "")
      category.valid?
      expect(category.errors.of_kind?(:hiragana, :blank)).to be_truthy
    end

    # アプリ内では登録しないためフォーマットは指定していない
    it "カテゴリー名（ひらがな）が20文字を超えたら無効な状態であること" do
      category = Category.new(hiragana: "a" * 21)
      category.valid?
      expect(category.errors.of_kind?(:hiragana, :too_long)).to be_truthy
    end

    it "カテゴリー名（ひらがな）が重複しているときは無効な状態であること" do
      Category.create(
        name: "テストカテゴリー1",
        hiragana: "てすとかてごりー"
      )
      category = Category.new(
        name: "テストカテゴリー2",
        hiragana: "てすとかてごりー"
      )
      category.valid?
      expect(category.errors.of_kind?(:hiragana, :taken)).to be_truthy
    end
  end

  describe ".created_item_categories" do
    let(:current_user) { create(:user, id: 1) }

    context "引数ユーザーの作成したアイテムが存在する場合" do
      let(:other_user) { create(:user, id: 2) }
      let(:category1) { create(:category, id: 1) }
      let(:category2) { create(:category, id: 2) }
      let(:category3) { create(:category, id: 3) }
      # Itemモデル登録時のvalidateメソッドにマスター管理ユーザーが必要
      let!(:master_user) { create(:user, :master_admin) }
      let!(:current_user_create_item1) { create(:item, user: current_user, category: category1) }
      let!(:current_user_create_item2) { create(:item, user: current_user, category: category2) }
      let!(:other_user_create_item) { create(:item, user: other_user, category: category3) }

      it "引数ユーザーの作成したアイテムが存在するカテゴリーを返すこと" do
        array = Category.created_item_categories(current_user.id)

        expect(array).to contain_exactly(category1, category2)
      end
    end

    context "引数ユーザーの作成したアイテムが存在しない場合" do
      let(:empty_array) { [] }

      it "空の配列を返すこと" do
        array = Category.created_item_categories(current_user.id)

        expect(array).to eq(empty_array)
      end
    end
  end

  describe "アソシエーション" do
    let(:association) { described_class.reflect_on_association(model) }

    subject { association.macro }

    context "Itemモデルとの関係性" do
      let(:model) { :items }

      it { is_expected.to eq(:has_many) }
    end
  end

  describe "dependent: :delete_all" do
    let(:category) { create(:category) }

    context "Itemモデル" do
      let(:user) { create(:user) }
      # Itemモデル登録時のvalidateメソッドにマスター管理ユーザーが必要
      let!(:master_user) { create(:user, :master_admin) }

      it "カテゴリーを削除するとそのカテゴリーに属するアイテムも削除されること" do
        create(:item, user: user, category: category)

        expect { category.destroy }.to change { Item.count }.by(-1)
      end
    end
  end
end
