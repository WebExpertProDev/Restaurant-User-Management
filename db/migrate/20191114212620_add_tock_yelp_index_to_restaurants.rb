class AddTockYelpIndexToRestaurants < ActiveRecord::Migration[5.2]
  def change
    add_index :restaurants, :tock_id, unique: true
    add_index :restaurants, :yelp_id, unique: true
  end
end
