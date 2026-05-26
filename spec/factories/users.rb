FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "テストユーザー#{n}" }
    sequence(:email) { |n| "test-email#{n}@example.com" }
    password { "Password1" }
    confirmed_at { Time.current }

    trait :unactivated do
      confirmed_at { nil }
    end

    trait :master_admin do
      admin { true }
      email { ENV["ADMIN_USER_EMAIL"] }
    end

    trait :admin do
      admin { true }
    end
  end
end
