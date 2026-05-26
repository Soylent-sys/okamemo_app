class AddIndexToBuys < ActiveRecord::Migration[7.0]
  def change
    add_index :buys, :item_name
    add_index :buys, :item_hiragana
  end
end
