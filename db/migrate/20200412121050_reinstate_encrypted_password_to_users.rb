class ReinstateEncryptedPasswordToUsers < ActiveRecord::Migration[5.2]
  def up
    # Commit 2a0c9fb2ea6ab11cd0e5e0c0b3467da7331e96d0 removed the encrypted_password column
    # from the DB schema without a corresponding migration, somehow, leaving development and
    # production DBs out of sync. Since we're going to need encrypted_password again soon,
    # let's add it back in the case where it doesn't already exist.
    unless column_exists? :users, :encrypted_password
      add_column :users, :encrypted_password, :string, default: "", null: false, after: 'uid'
    end
  end

  def down
    remove_column :users, :encrypted_password if column_exists? :users, :encrypted_password
  end
end
