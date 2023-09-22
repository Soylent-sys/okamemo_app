class AddIndexToItems < ActiveRecord::Migration[7.0]
  def change
    add_index :items, [:name, :user_id, :category_id],     unique: true
    add_index :items, [:hiragana, :user_id, :category_id], unique: true
  end
end
