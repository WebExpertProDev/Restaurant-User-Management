class AddIsCancelledToReservationsTable < ActiveRecord::Migration[5.2]
  def change
    add_column :reservations, :is_cancelled, :boolean, default: false
    add_index :reservations, :is_cancelled
  end
end
