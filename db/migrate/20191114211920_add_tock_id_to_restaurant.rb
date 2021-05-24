class AddTockIdToRestaurant < ActiveRecord::Migration[5.2]
  def change
    add_column :restaurants, :tock_id, :string
  end
end
