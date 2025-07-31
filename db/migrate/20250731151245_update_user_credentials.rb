class UpdateUserCredentials < ActiveRecord::Migration[8.0]
  def change
    # Add encrypted TastyTrade credentials
    add_column :users, :encrypted_tastytrade_username, :string
    add_column :users, :encrypted_tastytrade_password, :string
    add_column :users, :tastytrade_credentials_iv, :string
    
    # Remove the old customer ID field (after we migrate existing data)
    # We'll do this in a separate migration to be safe
    remove_index :users, :tastytrade_customer_id
    remove_column :users, :tastytrade_customer_id, :string
    
    # Add index for performance
    add_index :users, :encrypted_tastytrade_username
  end
end
