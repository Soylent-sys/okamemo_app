require 'rails_helper'

RSpec.describe ShoppingRecordsHelper, type: :helper do
  describe "#categoy_items" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let!(:master_user) { create(:user, :master_admin) }
    let(:category) { create(:category) }
    let(:other_category) { create(:category) }
    let!(:other_category_item) do
      create(:item, user: user, category: other_category, name: "別カテゴリーのアイテム", hiragana: "べつかてごりーのあいてむ")
    end
    let!(:other_user_item) do
      create(:item, user: other_user, category: category, name: "別ユーザーのアイテム", hiragana: "べつゆーざーのあいてむ")
    end
    # デフォルトアイテムとは：マスター管理ユーザーが作成したアイテム
    let!(:other_category_default_item) do
      create(:item, user: master_user, category: other_category, name: "別カテゴリーのデフォルトアイテム", hiragana: "べつかてごりーのでふぉるとあいてむ")
    end

    # メソッド内でcurrent_userを使用するためサインインが必要
    before do
      sign_in user
    end

    context "引数がサインイン中のユーザーの作成アイテムが存在するカテゴリーの場合" do
      context "カテゴリー名が おまとめ の場合" do
        let(:category_omatome) { create(:category, name: "おまとめ", hiragana: "おまとめ") }
        let!(:default_item_omatome) do
          create(:item, id: 1, user: master_user, category: category_omatome, name: "ウ", hiragana: "う")
        end
        let!(:item_omatome1) { create(:item, id: 2, user: user, category: category_omatome, name: "イ", hiragana: "い") }
        let!(:item_omatome2) { create(:item, id: 3, user: user, category: category_omatome, name: "ア", hiragana: "あ") }

        it "おまとめ カテゴリーに属するデフォルトアイテムとユーザーが作成したアイテムをidの昇順で返すこと" do
          items = helper.categoy_items(category_omatome)

          expect(items).to eq [default_item_omatome, item_omatome1, item_omatome2]
          expect(items).to_not include other_category_item
          expect(items).to_not include other_user_item
          expect(items).to_not include other_category_default_item
        end
      end

      context "カテゴリー名が おまとめ 以外の場合" do
        let!(:default_item_u) do
          create(:item, user: master_user, category: category, name: "ウ", hiragana: "う")
        end
        let!(:item_a) { create(:item, user: user, category: category, name: "ア", hiragana: "あ") }
        let!(:item_i) { create(:item, user: user, category: category, name: "イ", hiragana: "い") }

        it "カテゴリーに属するデフォルトアイテムとユーザーが作成したアイテムをアイテム（ひらがな名）(hiragana属性)の昇順で返すこと" do
          items = helper.categoy_items(category)

          expect(items).to eq [item_a, item_i, default_item_u]
          expect(items).to_not include other_category_item
          expect(items).to_not include other_user_item
          expect(items).to_not include other_category_default_item
        end
      end

      context "デフォルトアイテムが存在しない場合" do
        let!(:item1) { create(:item, user: user, category: category, name: "テストアイテム1", hiragana: "てすとあいてむ1") }
        let!(:item2) { create(:item, user: user, category: category, name: "テストアイテム2", hiragana: "てすとあいてむ2") }

        it "カテゴリーに属するユーザーが作成したアイテムを返すこと" do
          items = helper.categoy_items(category)

          expect(items).to eq [item1, item2]
          expect(items).to_not include other_category_item
          expect(items).to_not include other_user_item
          expect(items).to_not include other_category_default_item
        end
      end
    end

    context "引数がサインイン中のユーザーの作成アイテムが存在しないカテゴリーの場合" do
      context "デフォルトアイテムが存在する場合" do
        context "カテゴリー名が おまとめ の場合" do
          let(:category_omatome) { create(:category, name: "おまとめ", hiragana: "おまとめ") }
          let!(:default_item_omatome1) do
            create(:item, id: 1, user: master_user, category: category_omatome, name: "イ", hiragana: "い")
          end
          let!(:default_item_omatome2) do
            create(:item, id: 2, user: master_user, category: category_omatome, name: "ア", hiragana: "あ")
          end

          it "おまとめ カテゴリーに属するデフォルトアイテムをidの昇順で返すこと" do
            items = helper.categoy_items(category_omatome)

            expect(items).to eq [default_item_omatome1, default_item_omatome2]
            expect(items).to_not include other_category_item
            expect(items).to_not include other_user_item
            expect(items).to_not include other_category_default_item
          end
        end

        context "カテゴリー名が おまとめ 以外の場合" do
          let!(:default_item_a) { create(:item, user: master_user, category: category, name: "ア", hiragana: "あ") }
          let!(:default_item_i) { create(:item, user: master_user, category: category, name: "イ", hiragana: "い") }

          it "カテゴリーに属するデフォルトアイテムをアイテム（ひらがな名）(hiragana属性)の昇順で返すこと" do
            items = helper.categoy_items(category)

            expect(items).to eq [default_item_a, default_item_i]
            expect(items).to_not include other_category_item
            expect(items).to_not include other_user_item
            expect(items).to_not include other_category_default_item
          end
        end
      end

      context "デフォルトアイテムが存在しない場合" do
        let!(:no_items_category) { create(:category) }

        it "空の配列を返すこと" do
          items = helper.categoy_items(no_items_category)

          expect(items).to be_empty
        end
      end
    end
  end

  describe "#shopping_title" do
    let(:shopping_record_form) { double(ShoppingRecordForm, title: title) }

    context "タイトルが存在しない場合" do
      let(:title) { "" }

      it "本日の日付を加えたデフォルトタイトルを返すこと" do
        expected_title = "#{Date.today.to_fs(:date_ja)}のお買い物"
        expect(helper.shopping_title(shopping_record_form)).to eq expected_title
      end
    end

    context "タイトルが存在する場合" do
      let(:title) { "テストタイトル" }

      it "タイトルの値を返すこと" do
        expect(helper.shopping_title(shopping_record_form)).to eq "テストタイトル"
      end
    end
  end

  describe "#last_bought_day" do
    let(:user) { create(:user) }
    let(:category) { create(:category) }
    # Itemモデル登録時のvalidateメソッドにマスター管理ユーザーが必要
    let!(:master_user) { create(:user, :master_admin) }
    let!(:item) { create(:item, user: user, category: category) }

    # メソッド内でcurrent_userを使用するためサインインが必要
    before do
      sign_in user
    end

    context "Buyモデルにユーザーに紐づいた引数アイテム名のレコードが存在しない場合" do
      it "\"購入記録なし\"を返すこと" do
        expect(helper.last_bought_day(item)).to eq "購入記録なし"
      end
    end

    context "Buyモデルにユーザーに紐づいた引数アイテム名のレコードが存在する場合" do
      let(:shopping_record) { create(:shopping_record, :closed, user: user) }
      let(:buy_attributes) do
        { user: user, shopping_record: shopping_record, item_name: item.name }
      end
      let!(:buy) { create(:buy, :purchased, buy_attributes.merge(updated_at: buy_updated_at)) }

      context "最後に更新されたレコードの更新日が今日の場合" do
        let(:buy_updated_at) { Time.current }
        let!(:before_buy) { create(:buy, :purchased, buy_attributes.merge(updated_at: 1.day.ago)) }

        it "\"今日購入してます\"を返すこと" do
          expect(helper.last_bought_day(item)).to eq "今日購入してます"
        end
      end

      context "最後に更新されたレコードの更新日が昨日の場合" do
        let(:buy_updated_at) { 1.day.ago }
        let!(:before_buy) { create(:buy, :purchased, buy_attributes.merge(updated_at: 2.day.ago)) }

        it "\"昨日購入してます\"を返すこと" do
          expect(helper.last_bought_day(item)).to eq "昨日購入してます"
        end
      end

      context "最後に更新されたレコードの更新日が6日前以内の場合" do
        let(:buy_updated_at) { 6.day.ago }
        let!(:before_buy) { create(:buy, :purchased, buy_attributes.merge(updated_at: 7.day.ago)) }

        it "購入した日が何日前かを返すこと" do
          last_bought_day = buy.updated_at
          expected_output = "#{(Date.current - last_bought_day.to_date).to_i}日前に購入"
          expect(helper.last_bought_day(item)).to eq expected_output
        end
      end

      context "最後に更新されたレコードの更新日が7日以上前の場合" do
        let(:buy_updated_at) { 7.day.ago }

        it "購入した日付を返すこと" do
          last_bought_day = buy.updated_at.to_fs(:date_ymd)
          expected_output = "#{last_bought_day} 購入"
          expect(helper.last_bought_day(item)).to eq expected_output
        end
      end
    end
  end

  describe "#wish_items" do
    let(:user) { create(:user) }
    let(:category) { create(:category) }
    # Itemモデル登録時のvalidateメソッドにマスター管理ユーザーが必要
    let!(:master_user) { create(:user, :master_admin) }
    let!(:item1) { create(:item, user: user, category: category) }
    let!(:item2) { create(:item, user: user, category: category) }

    # アプリのフローにおいて引数に渡されるのはShoppingRecordFormオブジェクトのみのため
    # その他が引数に渡されるテストケースは不要
    it "引数オブジェクトのhashidsを基にItemモデルの配列を返すこと" do
      shopping_record_form = double(ShoppingRecordForm, hashids: [item1.hashid, item2.hashid])
      expect(helper.wish_items(shopping_record_form)).to contain_exactly(item1, item2)
    end
  end

  describe "#bought_items" do
    let(:user) { create(:user) }
    let(:shopping_record) { create(:shopping_record, user: user) }
    let!(:buy1) { create(:buy, user: user, shopping_record: shopping_record) }
    let!(:buy2) { create(:buy, user: user, shopping_record: shopping_record) }

    # アプリのフローにおいて引数に渡されるのはShoppingRecordFormオブジェクトのみのため
    # その他が引数に渡されるテストケースは不要
    it "引数オブジェクトのhashidsを基にBuyモデルの配列を返すこと" do
      shopping_record_form = double(ShoppingRecordForm, hashids: [buy1.hashid, buy2.hashid])
      expect(helper.bought_items(shopping_record_form)).to contain_exactly(buy1, buy2)
    end
  end

  describe "#no_bought_items" do
    let(:user) { create(:user) }
    let(:shopping_record) { create(:shopping_record, user: user) }
    let!(:buy1) { create(:buy, user: user, shopping_record: shopping_record) }
    let!(:buy2) { create(:buy, user: user, shopping_record: shopping_record) }
    let(:shopping_record_form) { double(ShoppingRecordForm, shopping_record_hashid: shopping_record.hashid, hashids: hashids) }

    # メソッド内でcurrent_userを使用するためサインインが必要
    before do
      sign_in user
    end

    # アプリのフローにおいて引数に渡されるのはShoppingRecordFormオブジェクトのみのため
    # その他が引数に渡されるテストケースは不要
    context "引数オブジェクトのhashids属性が存在する場合" do
      let(:hashids) { [buy1.hashid] }

      it "引数オブジェクトのshopping_record_hashidに対応するお買い物(ShoppingRecord)からhashidsに該当しないBuyモデルの配列を返すこと" do
        expect(helper.no_bought_items(shopping_record_form)).to contain_exactly(buy2)
      end
    end

    context "引数オブジェクトのhashids属性が空の場合" do
      let(:hashids) { [] }

      it "引数オブジェクトのshopping_record_hashidに対応するお買い物(ShoppingRecord)に属するすべてのBuyモデルの配列を返すこと" do
        expect(helper.no_bought_items(shopping_record_form)).to contain_exactly(buy1, buy2)
      end
    end
  end

  describe "#updated_at_change_format_ja" do
    # アプリのフローにおいて引数に渡されるのはShoppingRecordオブジェクトのみのため
    # その他が引数に渡されるテストケースは不要
    it "引数オブジェクトのupdated_at属性の値を'%Y年 %-m月'フォーマットに変換すること" do
      shopping_record = double(ShoppingRecord, updated_at: Time.zone.local(2024, 1, 1, 0, 0, 0))
      expect(helper.updated_at_change_format_ja(shopping_record)).to eq "2024年 1月"
    end
  end

  describe "#updated_at_change_format_ym" do
    # アプリのフローにおいて引数に渡されるのはShoppingRecordオブジェクトのみのため
    # その他が引数に渡されるテストケースは不要
    it "引数オブジェクトのupdated_at属性の値を'%Y-%m'フォーマットに変換すること" do
      shopping_record = double(ShoppingRecord, updated_at: Time.zone.local(2024, 1, 1, 0, 0, 0))
      expect(helper.updated_at_change_format_ym(shopping_record)).to eq "2024-01"
    end
  end

  describe "#date_change_format_ja" do
    # アプリのフローにおいて引数に渡されるのは決まったフォーマットの params のみのため
    # その他が引数に渡されるテストケースは不要
    it "'%Y-%m'で渡された年月を'%Y年%-m月'の形に変換すること" do
      params_date = "2024-01"
      expect(helper.date_change_format_ja(params_date)).to eq "2024年1月"
    end
  end

  describe "#display_name_of_category_or_item" do
    let(:user) { create(:user, hiragana_view: hiragana_view_flag) }
    let(:category) { double(Category, name: "テストカテゴリー", hiragana: "てすとかてごりー") }
    let(:item) { double(Item, name: "テストアイテム", hiragana: "てすとあいてむ") }

    # メソッド内でcurrent_userを使用するためサインインが必要
    before do
      sign_in user
    end

    # アプリのフローにおいて引数に渡されるのはCategoryとItemオブジェクトのみのため
    # その他が引数に渡されるテストケースは不要
    context "ユーザーのひらがなモード(hiragana_view属性)がON(true)の場合" do
      let(:hiragana_view_flag) { true }

      context "引数がカテゴリーの場合" do
        it "カテゴリーのひらがな名を返すこと" do
          expect(user.hiragana_view).to be_truthy
          expect(helper.display_name_of_category_or_item(category)).to eq "てすとかてごりー"
        end
      end

      context "引数がアイテムの場合" do
        it "アイテムのひらがな名を返すこと" do
          expect(user.hiragana_view).to be_truthy
          expect(helper.display_name_of_category_or_item(item)).to eq "てすとあいてむ"
        end
      end
    end

    context "ユーザーのひらがなモード(hiragana_view属性)がOFF(false)の場合" do
      let(:hiragana_view_flag) { false }

      context "引数がカテゴリーの場合" do
        it "カテゴリー名を返すこと" do
          expect(user.hiragana_view).to be_falsey
          expect(helper.display_name_of_category_or_item(category)).to eq "テストカテゴリー"
        end
      end

      context "引数がアイテムの場合" do
        it "アイテム名を返すこと" do
          expect(user.hiragana_view).to be_falsey
          expect(helper.display_name_of_category_or_item(item)).to eq "テストアイテム"
        end
      end
    end
  end

  describe "#display_item_name_of_buy" do
    let(:user) { create(:user, hiragana_view: hiragana_view_flag) }
    let(:buy) { double(Buy, item_name: "テストバイ", item_hiragana: "てすとばい") }

    # メソッド内でcurrent_userを使用するためサインインが必要
    before do
      sign_in user
    end

    # アプリのフローにおいて引数に渡されるのはBuyオブジェクトのみのため
    # その他が引数に渡されるテストケースは不要
    context "ユーザーのひらがなモード(hiragana_view属性)がON(true)の場合" do
      let(:hiragana_view_flag) { true }

      it "引数の購入記録のアイテム名（ひらがな）を返すこと" do
        expect(user.hiragana_view).to be_truthy
        expect(helper.display_item_name_of_buy(buy)).to eq "てすとばい"
      end
    end

    context "ユーザーのひらがなモード(hiragana_view属性)がOFF(false)の場合" do
      let(:hiragana_view_flag) { false }

      it "引数の購入記録のアイテム名を返すこと" do
        expect(user.hiragana_view).to be_falsey
        expect(helper.display_item_name_of_buy(buy)).to eq "テストバイ"
      end
    end
  end
end
