class AddUniqueConstraintToShoppingLocations < ActiveRecord::Migration[7.0]
  def change
    change_table :shopping_locations, bulk: true do |t|
      t.remove_foreign_key :shopping_records
      t.remove_index name: "index_shopping_locations_on_shopping_record_id"
      t.index :shopping_record_id, unique: true
      t.foreign_key :shopping_records
    end
  end
end
