class ChangeDatatypeOfShoppingLocations < ActiveRecord::Migration[7.0]
  def change
    change_column :shopping_locations, :latitude, :float, limit: 53
    change_column :shopping_locations, :longitude, :float, limit: 53
  end
end
