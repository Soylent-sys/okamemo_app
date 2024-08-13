FactoryBot.define do
  factory :item do
    user { nil }
    category { nil }
    name { "テストアイテム" }
    hiragana { "てすとあいてむ" }
  end
end
