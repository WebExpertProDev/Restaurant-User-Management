class AddUniqueCollectionRestaurantPairIndex < ActiveRecord::Migration[5.2]
  def change
    add_index :collections_restaurants, [:collection_id, :restaurant_id], unique: true, name: 'index_collections_restaurants'
  end
end
