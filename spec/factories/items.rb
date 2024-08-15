FactoryBot.define do
  factory :item do
    user { nil }
    category { nil }
    name { "テストアイテム" }
    hiragana { "てすとあいてむ" }
  end

  trait :item_1 do
    name { "テストアイテム1" }
    hiragana { "てすとあいてむいち" }
  end

  trait :item_2 do
    name { "テストアイテム2" }
    hiragana { "てすとあいてむに" }
  end

  trait :item_3 do
    name { "テストアイテム3" }
    hiragana { "てすとあいてむさん" }
  end
end
