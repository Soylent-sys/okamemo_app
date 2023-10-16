FactoryBot.define do
  factory :buy do
    user { nil }
    shopping_record { nil }
    item_name { "MyString" }
    item_hiragana { "MyString" }
    purchased { false }
  end
end
