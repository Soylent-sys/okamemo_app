# Userモデルの初期データ（管理ユーザー）
User.create!(
  name: "管理ユーザー",
  admin: true,
  email: "#{ENV['ADMIN_USER_EMAIL']}",
  password: "#{ENV['ADMIN_USER_PASSWORD']}",
  confirmed_at: Time.now
)

# Categoryモデルのデータ
Category.create!(
  [
    {
      name: "おまとめ",
      hiragana: "おまとめ"
    },
    {
      name: "主食類",
      hiragana: "おこめ・ぱん"
    },
    {
      name: "麺類",
      hiragana: "めん"
    },
    {
      name: "野菜",
      hiragana: "やさい"
    },
    {
      name: "生野菜",
      hiragana: "なまやさい"
    },
    {
      name: "キノコ類",
      hiragana: "きのこ"
    },
    {
      name: "果物",
      hiragana: "くだもの"
    },
    {
      name: "肉",
      hiragana: "にく"
    },
    {
      name: "海産物",
      hiragana: "かいさんぶつ"
    },
    {
      name: "卵",
      hiragana: "たまご"
    },
    {
      name: "乳製品",
      hiragana: "にゅうせいひん"
    },
    {
      name: "大豆製品",
      hiragana: "だいず"
    },
    {
      name: "粉製品",
      hiragana: "こな"
    },
    {
      name: "調味料",
      hiragana: "ちょうみりょう"
    },
    {
      name: "油",
      hiragana: "あぶら"
    },
    {
      name: "甘い物",
      hiragana: "あまいもの"
    },
    {
      name: "飲み物",
      hiragana: "のみもの"
    },
    {
      name: "お風呂用品",
      hiragana: "おふろ"
    },
    {
      name: "歯磨き用品",
      hiragana: "はみがき"
    },
    {
      name: "コスメ",
      hiragana: "けしょうひん"
    },
    {
      name: "洗濯用品",
      hiragana: "せんたく"
    },
    {
      name: "キッチン用品",
      hiragana: "だいどころ"
    },
    {
      name: "ペーパー類",
      hiragana: "ちりがみ"
    },
    {
      name: "ペット用品",
      hiragana: "ぺっと"
    },
    {
      name: "その他",
      hiragana: "そのほか"
    }
  ]
)
