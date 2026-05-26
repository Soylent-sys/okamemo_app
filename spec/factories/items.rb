FactoryBot.define do
  factory :item do
    user { nil }
    category { nil }
    sequence(:name) { |n| "テストアイテム#{n}" }
    sequence(:hiragana) { |n| "てすとあいてむ#{n}" }
  end
end
