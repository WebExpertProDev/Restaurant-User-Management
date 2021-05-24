class CreateRestaurantQueryCenters < ActiveRecord::Migration[5.2]
  def change
    create_table :restaurant_query_centers do |t|
      t.decimal :longitude
      t.decimal :latitude
      t.datetime :last_query_time

      t.timestamps
    end
  end
end
