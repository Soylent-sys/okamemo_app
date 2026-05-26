class AddIndexToCategories < ActiveRecord::Migration[7.0]
  def change
    add_index :categories, :name,     unique: true
    add_index :categories, :hiragana, unique: true
  end
end
