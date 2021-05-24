class CreateRestaurants < ActiveRecord::Migration[5.2]
  def change
    create_table :restaurants do |t|
      t.string :opentable_id
      t.decimal :longitude
      t.decimal :latitude
      t.string :name
      t.json :details

      t.timestamps
    end
  end
end
