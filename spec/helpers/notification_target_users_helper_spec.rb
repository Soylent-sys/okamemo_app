require 'rails_helper'

RSpec.describe NotificationTargetUsersHelper, type: :helper do
  describe "#disabled_if_limited" do
    let(:maximum_count) { NotificationTargetUser::NOTIFICATION_TARGET_USER_MUXIMUM_COUNT }

    context "通知対象ユーザー数が上限に達している場合" do
      it "disabled の文字列を返すこと" do
        notification_target_users = double("notification_target_users", count: maximum_count)
        result = helper.disabled_if_limited(notification_target_users)
        expect(result).to eq "disabled"
      end
    end

    context "通知対象ユーザー数が上限を超えている場合" do
      it "disabled の文字列を返すこと" do
        notification_target_users = double("notification_target_users", count: maximum_count + 1)
        result = helper.disabled_if_limited(notification_target_users)
        expect(result).to eq "disabled"
      end
    end

    context "通知対象ユーザー数が上限に満たない場合" do
      it "nil を返すこと" do
        notification_target_users = double("notification_target_users", count: maximum_count - 1)
        result = helper.disabled_if_limited(notification_target_users)
        expect(result).to be_nil
      end
    end
  end
end
