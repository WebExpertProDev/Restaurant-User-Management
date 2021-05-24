class AddYelpIdToRestaurant < ActiveRecord::Migration[5.2]
  def change
    add_column :restaurants, :yelp_id, :string
  end
end
