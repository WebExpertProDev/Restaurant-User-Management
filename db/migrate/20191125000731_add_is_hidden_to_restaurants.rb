class AddIsHiddenToRestaurants < ActiveRecord::Migration[5.2]
  def change
    add_column :restaurants, :is_hidden, :boolean, default: false
    add_index :restaurants, :is_hidden
  end
end
