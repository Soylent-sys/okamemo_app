require 'rails_helper'

RSpec.describe Item, type: :model do
  let(:user) { create(:user) }
  let(:category) { create(:category) }
  # Itemモデル登録時のvalidateメソッドにマスター管理ユーザーが必要
  let!(:master_user) { create(:user, :master_admin) }

  context "アイテムの登録ができる場合" do
    let(:name) { "テストアイテム" }
    let(:hiragana) { "てすとあいてむ" }

    it "ユーザーIDとカテゴリーIDとアイテム名とアイテム名（ひらがな）があれば有効な状態であること" do
      item = Item.new(
        user: user,
        category: category,
        name: name,
        hiragana: hiragana
      )
      expect(item).to be_valid
    end

    it "アイテム名（ひらがな）は半角数字を含んでも有効な状態であること" do
      item = Item.new(
        user: user,
        category: category,
        name: name,
        hiragana: "てすとあいてむ123"
      )
      expect(item).to be_valid
    end
  end

  context "アイテムの登録ができない場合" do
    it "ユーザーIDがなければ無効な状態であること" do
      item = Item.new(user: nil)
      item.valid?
      expect(item.errors.of_kind?(:user, :blank)).to be_truthy
    end

    it "カテゴリーIDがなければ無効な状態であること" do
      item = Item.new(category: nil)
      item.valid?
      expect(item.errors.of_kind?(:category, :blank)).to be_truthy
    end

    it "アイテム名がなければ無効な状態であること" do
      item = Item.new(name: nil)
      item.valid?
      expect(item.errors.of_kind?(:name, :blank)).to be_truthy
    end

    it "アイテム名が空文字のときは無効な状態であること" do
      item = Item.new(name: "")
      item.valid?
      expect(item.errors.of_kind?(:name, :blank)).to be_truthy
    end

    it "アイテム名が20文字を超えたら無効な状態であること" do
      item = Item.new(name: "a" * 21)
      item.valid?
      expect(item.errors.of_kind?(:name, :too_long)).to be_truthy
    end

    it "同じユーザー、同じカテゴリー内でアイテム名が重複しているときは無効な状態であること" do
      Item.create(
        user: user,
        category: category,
        name: "テストアイテム",
        hiragana: "てすとあいてむ"
      )
      item = Item.new(
        user: user,
        category: category,
        name: "テストアイテム",
        hiragana: "べつのてすとあいてむ"
      )
      item.valid?
      expect(item.errors.of_kind?(:name, :taken)).to be_truthy
    end

    it "アイテム名（ひらがな）がなければ無効な状態であること" do
      item = Item.new(hiragana: nil)
      item.valid?
      expect(item.errors.of_kind?(:hiragana, :blank)).to be_truthy
    end

    it "アイテム名（ひらがな）が空文字のときは無効な状態であること" do
      item = Item.new(hiragana: "")
      item.valid?
      expect(item.errors.of_kind?(:hiragana, :blank)).to be_truthy
    end

    it "アイテム名（ひらがな）に全角数字が含まれていたら無効な状態であること" do
      item = Item.new(hiragana: "てすとあいてむ１２３")
      item.valid?
      expect(item.errors.of_kind?(:hiragana, :invalid)).to be_truthy
    end

    it "アイテム名（ひらがな）に半角英文字が含まれていたら無効な状態であること" do
      item = Item.new(hiragana: "てすとあいてむa")
      item.valid?
      expect(item.errors.of_kind?(:hiragana, :invalid)).to be_truthy
    end

    it "アイテム名（ひらがな）に全角英文字が含まれていたら無効な状態であること" do
      item = Item.new(hiragana: "てすとあいてむＡ")
      item.valid?
      expect(item.errors.of_kind?(:hiragana, :invalid)).to be_truthy
    end

    it "アイテム名（ひらがな）に半角カタカナが含まれていたら無効な状態であること" do
      item = Item.new(hiragana: "ﾃｽﾄあいてむ")
      item.valid?
      expect(item.errors.of_kind?(:hiragana, :invalid)).to be_truthy
    end

    it "アイテム名（ひらがな）に全角カタカナが含まれていたら無効な状態であること" do
      item = Item.new(hiragana: "テストあいてむ")
      item.valid?
      expect(item.errors.of_kind?(:hiragana, :invalid)).to be_truthy
    end

    it "アイテム名（ひらがな）に半角特殊文字が含まれていたら無効な状態であること" do
      item = Item.new(hiragana: "てすとあいてむ!")
      item.valid?
      expect(item.errors.of_kind?(:hiragana, :invalid)).to be_truthy
    end

    it "アイテム名（ひらがな）に全角特殊文字が含まれていたら無効な状態であること" do
      item = Item.new(hiragana: "てすとあいてむ＠")
      item.valid?
      expect(item.errors.of_kind?(:hiragana, :invalid)).to be_truthy
    end

    it "アイテム名（ひらがな）に漢字が含まれていたら無効な状態であること" do
      item = Item.new(hiragana: "無効なてすとあいてむ")
      item.valid?
      expect(item.errors.of_kind?(:hiragana, :invalid)).to be_truthy
    end

    it "アイテム名（ひらがな）が20文字を超えたら無効な状態であること" do
      item = Item.new(hiragana: "あ" * 21)
      item.valid?
      expect(item.errors.of_kind?(:hiragana, :too_long)).to be_truthy
    end

    it "同じユーザー、同じカテゴリー内でアイテム名（ひらがな）が重複しているときは無効な状態であること" do
      Item.create(
        user: user,
        category: category,
        name: "テストアイテム",
        hiragana: "てすとあいてむ"
      )
      item = Item.new(
        user: user,
        category: category,
        name: "別のテストアイテム",
        hiragana: "てすとあいてむ"
      )
      item.valid?
      expect(item.errors.of_kind?(:hiragana, :taken)).to be_truthy
    end
  end

  describe "カスタムバリデーション" do
    describe "#same_preset_item" do
      let!(:preset_item) do
        Item.create(
          user: master_user,
          category: category,
          name: "デフォルトアイテム",
          hiragana: "でふぉるとあいてむ"
        )
      end

      it "同じカテゴリー内でマスター管理ユーザーの作成したアイテム名と重複すると無効な状態であること" do
        item = Item.new(
          user: user,
          category: category,
          name: "デフォルトアイテム",
          hiragana: "べつのでふぉるとあいてむ"
        )
        item.valid?
        expect(item.errors.of_kind?(:name, "が同じカテゴリーに存在するデフォルトアイテムと重複しています。")).to be_truthy
      end

      it "同じカテゴリー内でマスター管理ユーザーの作成したアイテム名（ひらがな）と重複すると無効な状態であること" do
        item = Item.new(
          user: user,
          category: category,
          name: "別のデフォルトアイテム",
          hiragana: "でふぉるとあいてむ"
        )
        item.valid?
        expect(item.errors.of_kind?(:hiragana, "が同じカテゴリーに存在するデフォルトアイテムと重複しています。")).to be_truthy
      end
    end

    describe "#check_count" do
      context "一般ユーザーの場合" do
        let!(:user_items) { create_list(:item, 150, user: user, category: category) }

        it "アイテムの作成数が150個を超えたら無効な状態であること" do
          item = Item.new(
            user: user,
            category: category,
            name: "151個目のアイテム",
            hiragana: "151こめのあいてむ"
          )
          item.valid?
          error_message = "登録できるアイテムは#{Item::ITEM_MAXIMUM_COUNT}個までです。新しく登録する場合は登録済みアイテムを削除してください。"
          expect(item.errors.of_kind?(:base, error_message)).to be_truthy
        end
      end

      context "マスター管理ユーザーの場合" do
        let!(:master_user_items) { create_list(:item, 150, user: master_user, category: category) }

        it "アイテムの作成数が150個を超えても有効な状態であること" do
          item = Item.new(
            user: master_user,
            category: category,
            name: "151個目のアイテム",
            hiragana: "151こめのあいてむ"
          )
          item.valid?
          expect(item).to be_valid
        end
      end
    end

    describe "#guest_check_count" do
      context "ゲストユーザーの場合" do
        let(:guest_user) { User.guest }
        let!(:guest_user_items) { create_list(:item, 10, user: guest_user, category: category) }

        it "アイテムの作成数が10個を超えたら無効な状態であること" do
          expect(guest_user.guest?).to be_truthy

          item = Item.new(
            user: guest_user,
            category: category,
            name: "11個目のアイテム",
            hiragana: "11こめのあいてむ"
          )
          item.valid?
          error_message = "ゲストユーザーが登録できるアイテムは#{Item::GUEST_ITEM_MAXIMUM_COUNT}個までです。新しく登録する場合は登録済みアイテムを削除してください。"
          expect(item.errors.of_kind?(:base, error_message)).to be_truthy
        end
      end

      context "ゲストユーザー以外の場合" do
        let!(:user_items) { create_list(:item, 10, user: user, category: category) }

        it "アイテムの作成数が10個を超えても有効な状態であること" do
          expect(user.guest?).to be_falsey

          item = Item.new(
            user: user,
            category: category,
            name: "11個目のアイテム",
            hiragana: "11こめのあいてむ"
          )
          item.valid?
          expect(item).to be_valid
        end
      end
    end
  end

  describe "同じ値の許可" do
    context "一般ユーザー同士の重複" do
      let(:other_user) { create(:user) }

      before do
        expect(user.id).to_not eq other_user.id
      end

      it "別の一般ユーザーが同じアイテム名を使うことを許可すること" do
        Item.create(
          user: user,
          category: category,
          name: "テストアイテム",
          hiragana: "てすとあいてむ"
        )
        other_item = Item.new(
          user: other_user,
          category: category,
          name: "テストアイテム",
          hiragana: "べつのてすとあいてむ"
        )

        expect(other_item).to be_valid
      end

      it "別の一般ユーザーが同じアイテム名（ひらがな）を使うことを許可すること" do
        Item.create(
          user: user,
          category: category,
          name: "テストアイテム",
          hiragana: "てすとあいてむ"
        )
        other_item = Item.new(
          user: other_user,
          category: category,
          name: "別のテストアイテム",
          hiragana: "てすとあいてむ"
        )

        expect(other_item).to be_valid
      end
    end

    context "カテゴリー間の重複" do
      let(:other_category) { create(:category) }

      before do
        expect(category.id).to_not eq other_category.id
      end

      it "別のカテゴリーであれば同じアイテム名を使うことを許可すること" do
        Item.create(
          user: user,
          category: category,
          name: "テストアイテム",
          hiragana: "てすとあいてむ"
        )
        other_item = Item.new(
          user: user,
          category: other_category,
          name: "テストアイテム",
          hiragana: "べつのてすとあいてむ"
        )

        expect(other_item).to be_valid
      end

      it "別のカテゴリーであれば同じアイテム名（ひらがな）を使うことを許可すること" do
        Item.create(
          user: user,
          category: category,
          name: "テストアイテム",
          hiragana: "てすとあいてむ"
        )
        other_item = Item.new(
          user: user,
          category: other_category,
          name: "別のテストアイテム",
          hiragana: "てすとあいてむ"
        )

        expect(other_item).to be_valid
      end
    end
  end

  describe ".available_items" do
    let(:other_user) { create(:user) }
    let!(:master_user_create_item) { create(:item, user: master_user, category: category) }
    let!(:user_create_item) { create(:item, user: user, category: category) }
    let!(:other_user_create_item) { create(:item, user: other_user, category: category) }

    it "引数のユーザーとマスター管理ユーザーに紐付くアイテムを返すこと" do
      items = Item.available_items(user.id)

      expect(items).to contain_exactly(master_user_create_item, user_create_item)
    end
  end

  describe ".available_items_grouped_by_category" do
    context "グルーピングのテスト" do
      let(:other_user) { create(:user) }
      let(:category2) { create(:category) }
      let!(:no_item_category) { create(:category) }
      let!(:c1_master_user_create_item) { create(:item, user: master_user, category: category) }
      let!(:c2_master_user_create_item) { create(:item, user: master_user, category: category2) }
      let!(:c1_user_create_item) { create(:item, user: user, category: category) }
      let!(:c2_user_create_item) { create(:item, user: user, category: category2) }
      let!(:c1_other_user_create_item) { create(:item, user: other_user, category: category) }
      let!(:c2_other_user_create_item) { create(:item, user: other_user, category: category2) }

      it "key:引数ユーザーとマスター管理ユーザーのアイテムが存在するカテゴリー value:引数ユーザーとマスター管理ユーザーに紐付くアイテム のハッシュを返すこと" do
        hash = Item.available_items_grouped_by_category(user.id)

        expect(hash.keys).to contain_exactly(category, category2)
        expect(hash[category]).to contain_exactly(c1_master_user_create_item, c1_user_create_item)
        expect(hash[category2]).to contain_exactly(c2_master_user_create_item, c2_user_create_item)
      end
    end

    context "ソート順のテスト" do
      let!(:item1) { create(:item, user: user, category: category, hiragana: "あすぱら") }
      let!(:item2) { create(:item, user: user, category: category, hiragana: "いも") }
      let!(:item3) { create(:item, user: user, category: category, hiragana: "うど") }

      it "valueの配列がhiraganaの昇順でソートされていること" do
        hash = Item.available_items_grouped_by_category(user.id)

        expect(hash[category]).to eq([item1, item2, item3])
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

    context "Categoryモデルとの関係性" do
      let(:model) { :category }

      it { is_expected.to eq :belongs_to }
    end
  end

  describe "スコープ" do
    describe "sorted" do
      let!(:first_item) { create(:item, user: user, category: category1, name: "アイテム1", hiragana: "あ") }
      let!(:second_item) { create(:item, user: user, category: category1, name: "アイテム2", hiragana: "い") }
      let!(:third_item) { create(:item, user: user, category: category2, name: "アイテム1", hiragana: "あ") }
      let(:category1) { create(:category, id: 1) }
      let(:category2) { create(:category, id: 2) }

      it "カテゴリーIDの昇順、アイテム名（ひらがな）の昇順でアイテムを返すこと" do
        expect(Item.sorted).to eq [first_item, second_item, third_item]
      end

      it "アイテムが存在しない場合は空の配列を返すこと" do
        Item.delete_all
        expect(Item.sorted).to be_empty
      end
    end

    describe "preset" do
      let(:guest_user) { User.guest }
      let!(:master_user_create_item) { create(:item, user: master_user, category: category) }
      let!(:general_user_create_item) { create(:item, user: user, category: category) }
      let!(:guest_user_create_item) { create(:item, user: guest_user, category: category) }

      it "マスター管理ユーザーが作成したアイテムのみ返すこと" do
        expect(Item.preset).to eq [master_user_create_item]
      end

      it "マスター管理ユーザーのアイテムが存在しない場合は空の配列を返すこと" do
        master_user_create_item.destroy
        expect(Item.preset).to be_empty
      end
    end
  end

  # hashid-railsを使用したIDハッシュ化に対するテスト
  describe "#hashid" do
    let(:item) { create(:item, id: 1, user: user, category: category) }

    it "有効なアイテムのハッシュIDを返すこと" do
      # アイテムIDをハッシュ化（整数→文字列）できているか検証
      hashid = item.hashid
      expect(hashid).to be_a(String)
      # ハッシュ化したIDを元のIDにデコードできているかを検証
      decode_id = item.class.decode_id(hashid)
      expect(decode_id).to eq item.id
    end
  end
end
