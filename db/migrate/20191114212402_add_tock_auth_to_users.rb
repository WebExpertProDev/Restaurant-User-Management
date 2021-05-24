class AddTockAuthToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :has_tock_creds, :boolean
    add_column :users, :tock_auth_data, :json
    add_column :users, :tock_user_data, :json
  end
end
