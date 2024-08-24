FactoryBot.define do
  factory :shopping_record do
    user { nil }
    sequence(:title) { |n| "テストのお買い物#{n}" }
    closed { false }

    trait :closed do
      closed { true }
    end
  end
end
