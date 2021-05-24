class AddUniqueCollectionNameAndUser < ActiveRecord::Migration[5.2]
  def change
    add_index :collections, [:name, :user_id], unique: true, name: 'index_name_user_on_collections'
  end
end
