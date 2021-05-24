class AddResyIdToRestaurant < ActiveRecord::Migration[5.2]
  def change
    add_column :restaurants, :resy_id, :string
  end
end
