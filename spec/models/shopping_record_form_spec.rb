require 'rails_helper'

RSpec.describe ShoppingRecordForm, type: :model do
  let(:user) { create(:user) }

  context "フォームが有効になる場合" do
    it "ユーザーID、タイトル、ハッシュ化されたIDの配列があれば有効な状態であること" do
      shopping_record_form = ShoppingRecordForm.new(
        user_id: user.id,
        title: "テストのお買い物",
        hashids: ["hashid1", "hashid2"]
      )
      expect(shopping_record_form).to be_valid
    end
  end

  context "フォームが無効になる場合" do
    let(:shopping_record_form) { ShoppingRecordForm.new(user_id: user.id) }
    # user_idはshopping_recordsコントローラーで確実に設定される（ユーザー入力による設定はない）ため
    # user_idが無い場合のテストケースは不要

    it "タイトルがなければ無効な状態であること" do
      shopping_record_form.title = nil
      shopping_record_form.valid?
      expect(shopping_record_form.errors.of_kind?(:title, :blank)).to be_truthy
    end

    it "タイトルが空文字のときは無効な状態であること" do
      shopping_record_form.title = ""
      shopping_record_form.valid?
      expect(shopping_record_form.errors.of_kind?(:title, :blank)).to be_truthy
    end

    it "タイトルが40文字を超えたら無効な状態であること" do
      shopping_record_form.title = "a" * 41
      shopping_record_form.valid?
      expect(shopping_record_form.errors.of_kind?(:title, :too_long)).to be_truthy
    end

    it "ハッシュ化されたIDの配列が空のときは無効な状態であること" do
      shopping_record_form.hashids = []
      shopping_record_form.valid?
      expect(shopping_record_form.errors.of_kind?(:hashids, :too_short)).to be_truthy
    end

    it "ハッシュ化されたIDの配列の要素数が20を超えるときは無効な状態であること" do
      hashed_ids = Array.new(21) { |n| "hashid_#{n}" }
      shopping_record_form.hashids = hashed_ids
      shopping_record_form.valid?
      expect(shopping_record_form.errors.of_kind?(:hashids, :too_long)).to be_truthy
    end
  end

  describe "カスタムバリデーション" do
    describe "#check_count" do
      let!(:five_opened_shopping_records) { create_list(:shopping_record, 5, user: user, closed: false) }

      it "未完了のお買い物が5つを超えたら無効な状態であること" do
        shopping_record_form = ShoppingRecordForm.new(
          user_id: user.id,
          title: "テストお買い物",
          hashids: ["hashid"]
        )
        shopping_record_form.valid?
        error_message = "の登録数が最大数（#{ShoppingRecordForm::SHOPPING_REGISTRATION_MAXIMUM_COUNT}つ）に達しています。"
        expect(shopping_record_form.errors.of_kind?(:shopping_record, error_message)).to be_truthy
      end
    end

    describe "#guest_check_count" do
      let(:guest_user) { User.guest }
      let(:shopping_record_form) { ShoppingRecordForm.new(user_id: guest_user.id, title: "テストお買い物", hashids: ["hashid"]) }
      let(:error_message) do
        "ゲストユーザーが登録できるお買い物は履歴を含めて#{ShoppingRecordForm::GUEST_SHOPPING_MAXIMUM_COUNT}件までです。" \
        "新しく登録する場合は登録済みのお買い物またはお買い物履歴を削除してください。"
      end

      context "既存の未完了と完了済みのお買い物が混在する場合" do
        let!(:five_opened_shopping_records) { create_list(:shopping_record, 5, user: guest_user, closed: false) }
        let!(:fifteen_closed_shopping_records) { create_list(:shopping_record, 15, user: guest_user, closed: true) }

        it "未完了と完了済みのお買い物の合計数が20件を超えたら無効な状態であること" do
          shopping_record_form.valid?
          expect(shopping_record_form.errors.of_kind?(:base, error_message)).to be_truthy
        end
      end

      context "既存のお買い物が完了済みのみの場合" do
        let!(:twenty_closed_shopping_records) { create_list(:shopping_record, 20, user: guest_user, closed: true) }

        it "お買い物の件数が20件を超えたら無効な状態であること" do
          shopping_record_form.valid?
          expect(shopping_record_form.errors.of_kind?(:base, error_message)).to be_truthy
        end
      end
    end
  end

  describe "#save" do
    let(:category) { create(:category) }
    let(:item1) { create(:item, user: user, category: category, name: "テストアイテム", hiragana: "てすとあいてむ") }
    let(:item2) { create(:item, user: user, category: category, name: "テストアイテム2", hiragana: "てすとあいてむ2") }
    # Itemモデル登録時のvalidateメソッドにマスター管理ユーザーが必要
    let!(:master_user) { create(:user, :master_admin) }
    let(:form) do
      ShoppingRecordForm.new(
        user_id: user.id,
        title: "テストのお買い物",
        # saveメソッド実行時のhashids属性はItemモデルのhashidを使用する
        hashids: [item1.hashid, item2.hashid]
      )
    end

    context "フォームが有効な場合" do
      it "フォームのタイトルを持つお買い物(ShoppingRecord)とハッシュ化したIDに対応するアイテムの購入記録(Buy)が保存されること" do
        expect { form.save }.to change { ShoppingRecord.count }.by(1).
          and change { Buy.count }.by(2)
        expect(ShoppingRecord.last.title).to eq "テストのお買い物"
        expect(Buy.second_to_last.item_name).to eq "テストアイテム"
        expect(Buy.second_to_last.item_hiragana).to eq "てすとあいてむ"
        expect(Buy.last.item_name).to eq "テストアイテム2"
        expect(Buy.last.item_hiragana).to eq "てすとあいてむ2"
      end
    end

    # フォームが無効な場合はsaveを実行するコントローラー上のvalid?メソッドによってsaveは実行されない
    # この仕様のつきsaveメソッド内ではバリデーションの検証はしないのでフォームが無効な場合のテストケースは不要

    context "トランザクションが失敗した場合" do
      let(:no_record) { 0 }

      it "お買い物(ShoppingRecord)と購入記録(Buy)が保存されないこと" do
        # saveメソッドではShoppingRecrd → Buyの順でcreate!が実行されるので
        # ShoppingRecord.create!が実行済みの状態でBuy.create!にエラーを発生させて
        # 両方のモデルのレコードが保存されていないことをテストする
        allow(Buy).to receive(:create!).and_raise(ActiveRecord::RecordNotSaved, "errors")

        expect { form.save }.to raise_error(ActiveRecord::RecordNotSaved)
        expect(ShoppingRecord.count).to eq no_record
        expect(Buy.count).to eq no_record
      end
    end
  end

  describe "#update_shopping_record" do
    let(:shopping_record) { create(:shopping_record, user: user, closed: false) }
    let!(:buy1) { create(:buy, user: user, shopping_record: shopping_record, purchased: false) }
    let!(:buy2) { create(:buy, user: user, shopping_record: shopping_record, purchased: false) }
    let(:form) do
      ShoppingRecordForm.new(
        # update_shopping_recordメソッドではshopping_record_hashid属性を使用する
        shopping_record_hashid: shopping_record.hashid,
        # update_shopping_recordメソッド実行時のhashids属性はBuyモデルのhashidを使用する
        hashids: [buy1.hashid]
      )
    end

    context "トランザクションが成功した場合" do
      it "お買い物(ShoppingRecord)を完了(closed)状態に、hashidsに対応した購入記録(Buy)を完了(purchased)状態に変更すること" do
        form.update_shopping_record(user)

        expect(shopping_record.reload.closed?).to be_truthy
        expect(buy1.reload.purchased?).to be_truthy
        expect(buy2.reload.purchased?).to be_falsey
      end
    end

    context "トランザクションが失敗した場合" do
      it "お買い物(ShoppingRecord)と購入記録(Buy)の状態(closed、purchased)が変更されないこと" do
        # update_shopping_recordメソッドではBuy(のインスタンス) → ShoppingRecrd(のインスタンス)の順でupdate!が実行されるので
        # Buy(のインスタンス).update!が実行済みの状態でShoppingRecord(のインスタンス).update!にエラーを発生させて
        # 両方のモデルのレコードが更新されていないことをテストする
        allow_any_instance_of(ShoppingRecord).to receive(:update!).and_raise(ActiveRecord::RecordNotSaved, "errors")

        expect { form.update_shopping_record(user) }.to raise_error(ActiveRecord::RecordNotSaved)
        expect(shopping_record.reload.closed?).to be_falsey
        expect(buy1.reload.purchased?).to be_falsey
      end
    end
  end

  describe "#wish_items" do
    let(:category) { create(:category) }
    let(:wish_item1) { create(:item, user: user, category: category, name: "テストアイテム", hiragana: "てすとあいてむ") }
    let(:wish_item2) { create(:item, user: user, category: category, name: "テストアイテム2", hiragana: "てすとあいてむ2") }
    let(:no_wish_item) { create(:item, user: user, category: category, name: "テストアイテム3", hiragana: "てすとあいてむ3") }
    # Itemモデル登録時のvalidateメソッドにマスター管理ユーザーが必要
    let!(:master_user) { create(:user, :master_admin) }
    let(:form) do
      ShoppingRecordForm.new(
        user_id: user.id,
        title: "テストのお買い物",
        # wish_itemsメソッド実行時のhashids属性はItemモデルのhashidを使用する
        hashids: [wish_item1.hashid, wish_item2.hashid]
      )
    end

    # アプリのフローにおいてこのメソッドが使用されるときは
    # formに必ず正常に動作するhashidsが格納されるため異常系のテストケースは不要
    it "formのhashidsを基にItemモデルの配列を返すこと" do
      items = form.wish_items

      expect(items).to contain_exactly(wish_item1, wish_item2)
    end
  end
end
