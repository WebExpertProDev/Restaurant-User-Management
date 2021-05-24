class AddRestaurantsUsersJoinTable < ActiveRecord::Migration[5.2]
  def change
    create_table :restaurants_users do |t|
      t.references :restaurant, index: true, foreign_key: true
      t.references :user, index: true, foreign_key: { on_delete: :cascade }
    end
  end
end
