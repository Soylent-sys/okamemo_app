# Userモデルの初期データ（管理ユーザー）
master_admin_user = User.find_by(email: "#{ENV['ADMIN_USER_EMAIL']}")
if master_admin_user.nil?
  User.create!(
    name: "マスター管理ユーザー",
    admin: true,
    email: "#{ENV['ADMIN_USER_EMAIL']}",
    password: "#{ENV['ADMIN_USER_PASSWORD']}",
    confirmed_at: Time.now
  )
end

# Categoryモデルのデータ
categories = [
  [ 1, "おまとめ", "おまとめ" ],
  [ 2, "主食類", "おこめ・ぱん" ],
  [ 3, "麺類", "めん" ],
  [ 4, "野菜", "やさい" ],
  [ 5, "生野菜", "なまやさい" ],
  [ 6, "キノコ類", "きのこ" ],
  [ 7, "果物", "くだもの" ],
  [ 8, "肉", "にく" ],
  [ 9, "海産物", "かいさんぶつ" ],
  [ 10, "卵", "たまご" ],
  [ 11, "乳製品", "にゅうせいひん" ],
  [ 12, "大豆製品", "だいず" ],
  [ 13, "粉製品", "こな" ],
  [ 14, "調味料", "ちょうみりょう" ],
  [ 15, "油", "あぶら" ],
  [ 16, "甘い物", "あまいもの" ],
  [ 17, "飲み物", "のみもの" ],
  [ 18, "お風呂用品", "おふろ" ],
  [ 19, "歯磨き用品", "はみがき" ],
  [ 20, "コスメ", "けしょうひん" ],
  [ 21, "洗濯用品", "せんたく" ],
  [ 22, "キッチン用品", "だいどころ" ],
  [ 23, "ペーパー類", "ちりがみ" ],
  [ 24, "ペット用品", "ぺっと" ],
  [ 25, "その他", "そのほか" ]
]

categories.each do |id, name, hiragana|
  Category.find_or_create_by!(id: id, name: name, hiragana: hiragana)
end

# Itemモデルの初期データ
master_admin_user ||= User.find_by(email: "#{ENV['ADMIN_USER_EMAIL']}")

items = [
  [ master_admin_user.id, 1, "ご飯のおかず", "ごはんのおかず" ],
  [ master_admin_user.id, 1, "野菜", "やさい" ],
  [ master_admin_user.id, 1, "果物", "くだもの" ],
  [ master_admin_user.id, 1, "肉", "にく" ],
  [ master_admin_user.id, 1, "魚介", "ぎょかい" ],
  [ master_admin_user.id, 1, "お惣菜", "おそうざい" ],
  [ master_admin_user.id, 1, "食用油", "しょくようあぶら" ],
  [ master_admin_user.id, 1, "冷凍食品", "れいとうしょくひん" ],
  [ master_admin_user.id, 1, "インスタント", "いんすたんと" ],
  [ master_admin_user.id, 1, "薬", "くすり" ],
  [ master_admin_user.id, 1, "サプリメント", "さぷりめんと" ],
  [ master_admin_user.id, 1, "お菓子", "おかし" ],
  [ master_admin_user.id, 1, "洋菓子", "ようがし" ],
  [ master_admin_user.id, 1, "和菓子", "わがし" ],
  [ master_admin_user.id, 2, "お米", "おこめ" ],
  [ master_admin_user.id, 2, "お餅", "おもち" ],
  [ master_admin_user.id, 2, "パン", "ぱん" ],
  [ master_admin_user.id, 3, "うどん", "うどん" ],
  [ master_admin_user.id, 3, "素麺", "そうめん" ],
  [ master_admin_user.id, 3, "蕎麦", "そば" ],
  [ master_admin_user.id, 3, "ラーメン", "らーめん" ],
  [ master_admin_user.id, 3, "焼きそば", "やきそば" ],
  [ master_admin_user.id, 3, "パスタ", "ぱすた" ],
  [ master_admin_user.id, 4, "カブ", "かぶ" ],
  [ master_admin_user.id, 4, "キャベツ", "きゃべつ" ],
  [ master_admin_user.id, 4, "ごぼう", "ごぼう" ],
  [ master_admin_user.id, 4, "さつま芋", "さつまいも" ],
  [ master_admin_user.id, 4, "里芋", "さといも" ],
  [ master_admin_user.id, 4, "じゃが芋", "じゃがいも" ],
  [ master_admin_user.id, 4, "生姜", "しょうが" ],
  [ master_admin_user.id, 4, "大根", "だいこん" ],
  [ master_admin_user.id, 4, "玉ねぎ", "たまねぎ" ],
  [ master_admin_user.id, 4, "長芋", "ながいも" ],
  [ master_admin_user.id, 4, "長ネギ", "ながねぎ" ],
  [ master_admin_user.id, 4, "ナス", "なす" ],
  [ master_admin_user.id, 4, "人参", "にんじん" ],
  [ master_admin_user.id, 4, "ニンニク", "にんにく" ],
  [ master_admin_user.id, 4, "白菜", "はくさい" ],
  [ master_admin_user.id, 4, "ピーマン", "ぴーまん" ],
  [ master_admin_user.id, 4, "もやし", "もやし" ],
  [ master_admin_user.id, 4, "レンコン", "れんこん" ],
  [ master_admin_user.id, 5, "きゅうり", "きゅうり" ],
  [ master_admin_user.id, 5, "トマト", "とまと" ],
  [ master_admin_user.id, 5, "レタス", "れたす" ],
  [ master_admin_user.id, 6, "エノキ", "えのき" ],
  [ master_admin_user.id, 6, "エリンギ", "えりんぎ" ],
  [ master_admin_user.id, 6, "椎茸", "しいたけ" ],
  [ master_admin_user.id, 6, "しめじ", "しめじ" ],
  [ master_admin_user.id, 6, "舞茸", "まいたけ" ],
  [ master_admin_user.id, 7, "イチゴ", "いちご" ],
  [ master_admin_user.id, 7, "オレンジ", "おれんじ" ],
  [ master_admin_user.id, 7, "キウイ", "きうい" ],
  [ master_admin_user.id, 7, "グレープフルーツ", "ぐれーぷふるーつ" ],
  [ master_admin_user.id, 7, "梨", "なし" ],
  [ master_admin_user.id, 7, "バナナ", "ばなな" ],
  [ master_admin_user.id, 7, "ぶどう", "ぶどう" ],
  [ master_admin_user.id, 7, "みかん", "みかん" ],
  [ master_admin_user.id, 7, "メロン", "めろん" ],
  [ master_admin_user.id, 7, "桃", "もも" ],
  [ master_admin_user.id, 7, "リンゴ", "りんご" ],
  [ master_admin_user.id, 7, "レモン", "れもん" ],
  [ master_admin_user.id, 8, "ウインナー", "ういんなー" ],
  [ master_admin_user.id, 8, "牛肉", "ぎゅうにく" ],
  [ master_admin_user.id, 8, "牛ひき肉", "ぎゅうひきにく" ],
  [ master_admin_user.id, 8, "鶏肉", "とりにく" ],
  [ master_admin_user.id, 8, "鶏ひき肉", "とりひきにく" ],
  [ master_admin_user.id, 8, "ハム", "はむ" ],
  [ master_admin_user.id, 8, "豚肉", "ぶたにく" ],
  [ master_admin_user.id, 8, "豚ひき肉", "ぶたひきにく" ],
  [ master_admin_user.id, 8, "ベーコン", "べーこん" ],
  [ master_admin_user.id, 9, "イカ", "いか" ],
  [ master_admin_user.id, 9, "エビ", "えび" ],
  [ master_admin_user.id, 9, "お刺し身", "おさしみ" ],
  [ master_admin_user.id, 9, "貝", "かい" ],
  [ master_admin_user.id, 9, "昆布", "こんぶ" ],
  [ master_admin_user.id, 9, "魚の干物", "さかなのひもの" ],
  [ master_admin_user.id, 9, "タコ", "たこ" ],
  [ master_admin_user.id, 9, "生魚", "なまざかな" ],
  [ master_admin_user.id, 9, "ワカメ", "わかめ" ],
  [ master_admin_user.id, 10, "温泉卵", "おんせんたまご" ],
  [ master_admin_user.id, 10, "生卵", "なまたまご" ],
  [ master_admin_user.id, 11, "牛乳", "ぎゅうにゅう" ],
  [ master_admin_user.id, 11, "バター", "ばたー" ],
  [ master_admin_user.id, 11, "マーガリン", "まーがりん" ],
  [ master_admin_user.id, 11, "ヨーグルト", "よーぐると" ],
  [ master_admin_user.id, 12, "油揚げ", "あぶらあげ" ],
  [ master_admin_user.id, 12, "豆腐", "とうふ" ],
  [ master_admin_user.id, 12, "納豆", "なっとう" ],
  [ master_admin_user.id, 13, "小麦粉", "こむぎこ" ],
  [ master_admin_user.id, 13, "片栗粉", "かたくりこ" ],
  [ master_admin_user.id, 14, "お酢", "おす" ],
  [ master_admin_user.id, 14, "カレー粉", "かれーこ" ],
  [ master_admin_user.id, 14, "ケチャップ", "けちゃっぷ" ],
  [ master_admin_user.id, 14, "コショウ", "こしょう" ],
  [ master_admin_user.id, 14, "砂糖", "さとう" ],
  [ master_admin_user.id, 14, "塩", "しお" ],
  [ master_admin_user.id, 14, "しょうゆ", "しょうゆ" ],
  [ master_admin_user.id, 14, "ソース", "そーす" ],
  [ master_admin_user.id, 14, "出汁", "だし" ],
  [ master_admin_user.id, 14, "マヨネーズ", "まよねーず" ],
  [ master_admin_user.id, 14, "味噌", "みそ" ],
  [ master_admin_user.id, 14, "みりん", "みりん" ],
  [ master_admin_user.id, 14, "料理酒", "りょうりしゅ" ],
  [ master_admin_user.id, 14, "わさび", "わさび" ],
  [ master_admin_user.id, 15, "オリーブオイル", "おりーぶおいる" ],
  [ master_admin_user.id, 15, "ごま油", "ごまあぶら" ],
  [ master_admin_user.id, 15, "こめ油", "こめあぶら" ],
  [ master_admin_user.id, 15, "サラダ油", "さらだあぶら" ],
  [ master_admin_user.id, 15, "ドレッシング", "どれっしんぐ" ],
  [ master_admin_user.id, 16, "飴", "あめ" ],
  [ master_admin_user.id, 16, "菓子パン", "かしぱん" ],
  [ master_admin_user.id, 16, "カステラ", "かすてら" ],
  [ master_admin_user.id, 16, "ケーキ", "けーき" ],
  [ master_admin_user.id, 16, "チョコレート", "ちょこれーと" ],
  [ master_admin_user.id, 16, "たい焼き", "たいやき" ],
  [ master_admin_user.id, 16, "大福", "だいふく" ],
  [ master_admin_user.id, 16, "団子", "だんご" ],
  [ master_admin_user.id, 16, "どら焼き", "どらやき" ],
  [ master_admin_user.id, 16, "プリン", "ぷりん" ],
  [ master_admin_user.id, 17, "お酒", "おさけ" ],
  [ master_admin_user.id, 17, "お茶", "おちゃ" ],
  [ master_admin_user.id, 17, "ジュース", "じゅーす" ],
  [ master_admin_user.id, 17, "水", "みず" ],
  [ master_admin_user.id, 18, "シャンプー", "しゃんぷー" ],
  [ master_admin_user.id, 18, "石鹸", "せっけん" ],
  [ master_admin_user.id, 18, "洗顔料", "せんがんりょう" ],
  [ master_admin_user.id, 18, "ボディソープ", "ぼでぃそーぷ" ],
  [ master_admin_user.id, 18, "ボディタオル", "ぼでぃたおる" ],
  [ master_admin_user.id, 18, "リンス", "りんす" ],
  [ master_admin_user.id, 19, "歯ブラシ", "はぶらし" ],
  [ master_admin_user.id, 19, "歯磨き粉", "はみがきこ" ],
  [ master_admin_user.id, 20, "口紅", "くちべに" ],
  [ master_admin_user.id, 20, "クレンジング", "くれんじんぐ" ],
  [ master_admin_user.id, 20, "化粧水", "けしょうすい" ],
  [ master_admin_user.id, 20, "ファンデーション", "ふぁんでーしょん" ],
  [ master_admin_user.id, 21, "柔軟剤", "じゅうなんざい" ],
  [ master_admin_user.id, 21, "洗濯洗剤", "せんたくせんざい" ],
  [ master_admin_user.id, 21, "漂白剤", "ひょうはくざい" ],
  [ master_admin_user.id, 22, "アルミホイル", "あるみほいる" ],
  [ master_admin_user.id, 22, "キッチン洗剤", "きっちんせんざい" ],
  [ master_admin_user.id, 22, "スポンジ", "すぽんじ" ],
  [ master_admin_user.id, 22, "ラップ", "らっぷ" ],
  [ master_admin_user.id, 23, "ウェットティッシュ", "うぇっとてぃっしゅ" ],
  [ master_admin_user.id, 23, "キッチンペーパー", "きっちんぺーぱー" ],
  [ master_admin_user.id, 23, "ティッシュ", "てぃっしゅ" ],
  [ master_admin_user.id, 23, "トイレットペーパー", "といれっとぺーぱー" ],
  [ master_admin_user.id, 24, "エサ", "えさ" ],
  [ master_admin_user.id, 24, "トイレ砂", "といれすな" ]
]

items.each do |user_id, category_id, name, hiragana|
  Item.find_or_create_by!(user_id: user_id, category_id: category_id, name: name, hiragana: hiragana)
end

# NotificationTargetUserモデルの初期データ
nt_user = NotificationTargetUser.find_or_create_by!(
  user_id: master_admin_user.id,
  name: "テスト通知対象ユーザー",
  email: "sr_mail_preview@okamemo.test",
  confirmation_status: :confirmed,
)

nt_user.update!(
  confirmation_token: nil,
  expiration_date: nil,
)

NotificationTargetUser.find_or_create_by!(
  user_id: master_admin_user.id,
  name: "非アクティブテスト通知対象ユーザー",
  email: "ntu_mail_preview@okamemo.test",
  confirmation_status: :unconfirmed,
)

# ShoppingRecordモデルの初期データ
test_sr = ShoppingRecord.find_or_create_by!(
  user_id: master_admin_user.id,
  title: "test shopping",
  closed: true,
)

# Buyモデルの初期データ
buys = [
  [ master_admin_user.id, test_sr.id, "野菜", "やさい", true ],
  [ master_admin_user.id, test_sr.id, "果物", "くだもの", false ],
  [ master_admin_user.id, test_sr.id, "肉", "にく", true ],
  [ master_admin_user.id, test_sr.id, "お惣菜", "おそうざい", false ],
]

buys.each do |user_id, shopping_record_id, item_name, item_hiragana, purchased|
  Buy.find_or_create_by!(
    user_id: user_id,
    shopping_record_id: shopping_record_id,
    item_name: item_name,
    item_hiragana: item_hiragana,
    purchased: purchased
  )
end
