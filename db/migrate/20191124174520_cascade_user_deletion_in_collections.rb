class CascadeUserDeletionInCollections < ActiveRecord::Migration[5.2]
  def change
      remove_foreign_key :collections, :users
      add_foreign_key :collections, :users, index: true, on_delete: :cascade
  end
end
