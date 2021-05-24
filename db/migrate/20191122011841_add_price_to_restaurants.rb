class AddPriceToRestaurants < ActiveRecord::Migration[5.2]
  def change
    add_column :restaurants, :price_band, :integer
    add_column :restaurants, :cuisines, :text, array: true
    add_column :restaurants, :neighborhood, :string
  end
end
