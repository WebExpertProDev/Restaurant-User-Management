class AddColumnOpentableUsernameToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :has_opentable_creds, :boolean
    add_column :users, :opentable_auth_data, :json
    add_column :users, :opentable_user_data, :json
  end
end
