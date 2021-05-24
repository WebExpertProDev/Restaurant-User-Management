class AddColumnResyUsernameToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :has_resy_creds, :boolean
    add_column :users, :resy_auth_data, :json
    add_column :users, :resy_user_data, :json

    add_column :users, :has_yelp_creds, :boolean
    add_column :users, :yelp_auth_data, :json
    add_column :users, :yelp_user_data, :json
  end
end
