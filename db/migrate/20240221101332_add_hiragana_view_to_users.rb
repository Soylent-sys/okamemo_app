class AddHiraganaViewToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :hiragana_view, :boolean, default: false, null: false
  end
end
