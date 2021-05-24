class AddIndexToRestaurant < ActiveRecord::Migration[5.2]
  def change
    add_index :restaurants, :opentable_id, unique: true
    add_index :restaurants, :resy_id, unique: true
  end
end
