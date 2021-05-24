class AddSaltToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :partner_auth_salt, :string
  end
end
