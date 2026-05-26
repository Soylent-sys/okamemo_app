class CreateShoppingLocations < ActiveRecord::Migration[7.0]
  def change
    create_table :shopping_locations do |t|
      t.references :shopping_record, null: false, foreign_key: true
      t.float :latitude,  null: false
      t.float :longitude, null: false

      t.timestamps
    end
  end
end
