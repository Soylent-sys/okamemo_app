class CreateShoppingRecords < ActiveRecord::Migration[7.0]
  def change
    create_table :shopping_records do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false, default: ""
      t.boolean :closed, null: false, default: false

      t.timestamps
    end
  end
end
