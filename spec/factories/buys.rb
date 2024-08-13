FactoryBot.define do
  factory :buy do
    user { nil }
    shopping_record { nil }
    item_name { "テストアイテム" }
    item_hiragana { "てすとあいてむ" }
    purchased { false }
  end
end
