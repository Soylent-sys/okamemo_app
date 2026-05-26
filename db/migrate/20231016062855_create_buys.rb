class CreateBuys < ActiveRecord::Migration[7.0]
  def change
    create_table :buys do |t|
      t.references :user, null: false, foreign_key: true
      t.references :shopping_record, null: false, foreign_key: true
      t.string :item_name,     null: false, default: ""
      t.string :item_hiragana, null: false, default: ""
      t.boolean :purchased, null: false, default: false

      t.timestamps
    end
  end
end
