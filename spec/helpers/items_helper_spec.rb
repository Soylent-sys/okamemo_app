require 'rails_helper'

RSpec.describe ItemsHelper, type: :helper do
  describe "#my_items" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:category) { create(:category) }
    let(:other_category) { create(:category) }
    # Itemモデル登録時のvalidateメソッドにマスター管理ユーザーが必要
    let!(:master_user) { create(:user, :master_admin) }

    # メソッド内でcurrent_userを使用するためサインインが必要
    before do
      sign_in user
    end

    context "引数がサインイン中のユーザーの作成アイテムが存在するカテゴリーの場合" do
      context "カテゴリー名が おまとめ の場合" do
        let(:category_omatome) { create(:category, name: "おまとめ", hiragana: "おまとめ") }
        let!(:item_omatome1) { create(:item, id: 1, user: user, category: category_omatome, name: "イ", hiragana: "い") }
        let!(:item_omatome2) { create(:item, id: 2, user: user, category: category_omatome, name: "ア", hiragana: "あ") }
        let!(:other_category_item) do
          create(:item, user: user, category: other_category, name: "別カテゴリーのアイテム", hiragana: "べつかてごりーのあいてむ")
        end
        let!(:other_user_item) do
          create(:item, user: other_user, category: category, name: "別ユーザーのアイテム", hiragana: "べつゆーざーのあいてむ")
        end

        it "ユーザーが作成した おまとめ カテゴリーに属するアイテムをidの昇順で返すこと" do
          items = helper.my_items(category_omatome)

          expect(items).to eq [item_omatome1, item_omatome2]
          expect(items).to_not include other_category_item
          expect(items).to_not include other_user_item
        end
      end

      context "カテゴリー名が おまとめ 以外の場合" do
        let!(:item_a) { create(:item, user: user, category: category, name: "ア", hiragana: "あ") }
        let!(:item_i) { create(:item, user: user, category: category, name: "イ", hiragana: "い") }
        let!(:other_category_item) do
          create(:item, user: user, category: other_category, name: "別カテゴリーのアイテム", hiragana: "べつかてごりーのあいてむ")
        end
        let!(:other_user_item) do
          create(:item, user: other_user, category: category, name: "別ユーザーのアイテム", hiragana: "べつゆーざーのあいてむ")
        end

        it "ユーザーが作成したカテゴリーに属するアイテムをアイテム（ひらがな名）(hiragana属性)の昇順で返すこと" do
          items = helper.my_items(category)

          expect(items).to eq [item_a, item_i]
          expect(items).to_not include other_category_item
          expect(items).to_not include other_user_item
        end
      end
    end

    context "引数がサインイン中のユーザーの作成アイテムが存在しないカテゴリーの場合" do
      let!(:no_items_category) { create(:category) }

      it "空の配列を返すこと" do
        items = helper.my_items(no_items_category)

        expect(items).to be_empty
      end
    end
  end
end
