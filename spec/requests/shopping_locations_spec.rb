require 'rails_helper'

RSpec.describe "ShoppingLocations", type: :request do
  # デベロッパーツール等を使ったポスト先URLの編集（:hashid部分）を利用した
  # 他ユーザーのお買い物場所に対しての不正アクセスに対するテスト
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:other_user_shopping_record) { create(:shopping_record, :closed, user: other_user) }
  let!(:other_user_shopping_location) do
    create(:shopping_location, shopping_record: other_user_shopping_record, latitude: 1.5, longitude: 1.5)
  end

  before do
    sign_in_as_request user
  end

  describe "PUT /shopping_locations/:hashid" do
    context "他ユーザーのshopping_locationに対する送信をした場合" do
      it "お買い物履歴の年月一覧画面へリダイレクトして更新しないこと" do
        expect do
          put shopping_location_path(other_user_shopping_location.hashid),
            params: { shopping_location: { latitude: 2, longitude: 2 } }
        end.to_not change { other_user_shopping_location.reload.attributes.slice("latitude", "longitude") }

        expect(response).to redirect_to(shopping_result_group_url)
        follow_redirect!

        expect(flash[:error]).to include "処理中に問題が発生しました。履歴一覧ページに戻ります。"
      end
    end
  end

  describe "DELETE /shopping_locations/:hashid" do
    context "他ユーザーのshopping_locationに対する送信をした場合" do
      it "お買い物履歴の年月一覧画面へリダイレクトして削除しないこと" do
        expect do
          delete shopping_location_path(other_user_shopping_location.hashid)
        end.to_not change { ShoppingLocation.count }

        expect(response).to redirect_to(shopping_result_group_url)
        follow_redirect!

        expect(flash[:error]).to include "処理中に問題が発生しました。履歴一覧ページに戻ります。"
      end
    end
  end
end
