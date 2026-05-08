require 'rails_helper'

RSpec.describe ShoppingRecordsHelper, type: :helper do
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
