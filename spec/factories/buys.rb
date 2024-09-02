FactoryBot.define do
  factory :buy do
    user { nil }
    shopping_record { nil }
    sequence(:item_name) { |n| "テストアイテム#{n}" }
    sequence(:item_hiragana) { |n| "てすとあいてむ#{n}" }
    purchased { false }
  end
end
