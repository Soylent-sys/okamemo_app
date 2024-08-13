FactoryBot.define do
  factory :notification_target_user do
    user { nil }
    name { "テスト通知対象ユーザー" }
    email { "test-notification-target@example.com" }
    confirmation_status { :confirmed }
  end
end
