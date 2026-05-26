FactoryBot.define do
  factory :notification_target_user do
    user { nil }
    sequence(:name) { |n| "テスト通知対象ユーザー#{n}" }
    sequence(:email) { |n| "test-notification-target#{n}@example.com" }
    confirmation_status { :confirmed }

    trait :unconfirmed do
      confirmation_status { :unconfirmed }
    end
  end
end
