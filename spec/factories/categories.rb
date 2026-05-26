FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "テストカテゴリー#{n}" }
    sequence(:hiragana) { |n| "てすとかてごりー#{n}" }
  end
end
