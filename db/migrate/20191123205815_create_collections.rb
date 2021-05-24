class CreateCollections < ActiveRecord::Migration[5.2]
  def change
    create_table :collections do |t|
      t.string :name
      t.references :user, index: true, foreign_key: true

      t.timestamps
    end

    create_join_table :collections, :restaurants do |t|
      t.index :collection_id
      t.index :restaurant_id
    end
  end
end
