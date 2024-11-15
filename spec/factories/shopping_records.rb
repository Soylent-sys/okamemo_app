FactoryBot.define do
  factory :shopping_record do
    user { nil }
    sequence(:title) { |n| "テストのお買い物#{n}" }
    closed { false }

    trait :closed do
      closed { true }
    end

    trait :with_sequential_updated_at do
      transient do
        start_date { Time.current }
      end

      sequence(:updated_at) { |n| start_date - n.months }
    end
  end
end
