FactoryBot.define do
  factory :shopping_record do
    user { nil }
    title { "テストのお買い物" }
    closed { false }
  end
end
