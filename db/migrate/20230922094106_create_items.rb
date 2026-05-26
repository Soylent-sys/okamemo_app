class CreateItems < ActiveRecord::Migration[7.0]
  def change
    create_table :items do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.string :name,     null: false, default: ""
      t.string :hiragana, null: false, default: ""

      t.timestamps
    end
  end
end
