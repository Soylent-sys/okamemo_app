require 'rails_helper'

RSpec.describe ShoppingLocation, type: :model do
  let(:user) { create(:user) }
  let(:shopping_record) { create(:shopping_record, user: user) }

  context "お買い物場所の登録ができる場合" do
    it "お買い物ID、緯度、経度があれば有効な状態であること" do
      shopping_location = ShoppingLocation.new(
        shopping_record: shopping_record,
        latitude: 1.23456789,
        longitude: 1.23456789
      )
      expect(shopping_location).to be_valid
    end
  end

  context "お買い物場所の登録ができない場合" do
    it "お買い物IDがなければ無効な状態であること" do
      shopping_location = ShoppingLocation.new(shopping_record: nil)
      shopping_location.valid?
      expect(shopping_location.errors.of_kind?(:shopping_record, :blank)).to be_truthy
    end

    it "お買い物IDが重複したら無効な状態であること" do
      ShoppingLocation.create(
        shopping_record: shopping_record,
        latitude: 1.23456789,
        longitude: 1.23456789
      )
      shopping_location = ShoppingLocation.new(
        shopping_record: shopping_record,
        latitude: 12.3456789,
        longitude: 12.3456789
      )
      shopping_location.valid?
      expect(shopping_location.errors.of_kind?(:shopping_record_id, :taken)).to be_truthy
    end

    it "緯度がなければ無効な状態であること" do
      shopping_location = ShoppingLocation.new(latitude: nil)
      shopping_location.valid?
      expect(shopping_location.errors.of_kind?(:latitude, :blank)).to be_truthy
    end

    it "経度がなければ無効な状態であること" do
      shopping_location = ShoppingLocation.new(longitude: nil)
      shopping_location.valid?
      expect(shopping_location.errors.of_kind?(:longitude, :blank)).to be_truthy
    end
  end

  # GoogleMapAPIによるマッピング機能の使用に必要十分な緯度・経度の精度
  # 小数点以下6桁（1メートル以内の精度）を確実にDBに保存することをテストする
  describe "緯度・経度の精度" do
    let(:latitude) { 35.689487123 }
    let(:longitude) { 139.691706789 }
    let!(:shopping_location) do
      create(:shopping_location, shopping_record: shopping_record, latitude: latitude, longitude: longitude)
    end

    it "許容される精度の範囲内で緯度が保存されること" do
      expect(shopping_location.latitude).to be_within(0.0000001).of(latitude)
    end

    it "許容される精度の範囲内で経度が保存されること" do
      expect(shopping_location.longitude).to be_within(0.0000001).of(longitude)
    end
  end

  describe "アソシエーション" do
    let(:association) { described_class.reflect_on_association(model) }

    subject { association.macro }

    context "ShoppingRecordモデルとの関係性" do
      let(:model) { :shopping_record }

      it { is_expected.to eq :belongs_to }
    end
  end
end
