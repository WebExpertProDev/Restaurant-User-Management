class AddColumnNumberToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :number, :string
    remove_column :users, :reset_password_token
    remove_column :users, :allow_password_change
    remove_column :users, :remember_created_at
    remove_column :users, :confirmation_token
    remove_column :users, :confirmed_at
    remove_column :users, :confirmation_sent_at
    remove_column :users, :unconfirmed_email

    # remove_index "confirmation_token", name: "index_users_on_confirmation_token"
    # remove_index "reset_password_token", name: "index_users_on_reset_password_token"
  end
end
