class CreateReservations < ActiveRecord::Migration[5.2]
  def change
    create_table :reservations do |t|
      t.references :user, index: true, foreign_key: true
      t.string :partner, index: true
      t.json :partner_reservation_details
      t.datetime :reservation_date
      t.string :confirmation_id, unique: true
      t.integer :cover
      t.boolean :is_past

      t.timestamps
    end
  end
end
