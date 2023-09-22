FactoryBot.define do
  factory :item do
    user { nil }
    category { nil }
    name { "MyString" }
    hiragana { "MyString" }
  end
end
