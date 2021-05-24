class AddCredDefaultsToUsers < ActiveRecord::Migration[5.2]
  def change
    change_column_default :users, :has_tock_creds, from: nil, to: false
    change_column_default :users, :has_yelp_creds, from: nil, to: false
    change_column_default :users, :has_opentable_creds, from: nil, to: false
    change_column_default :users, :has_resy_creds, from: nil, to: false
  end
end
