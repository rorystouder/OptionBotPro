class AddOAuthFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :tastytrade_oauth_token, :text
    add_column :users, :tastytrade_oauth_refresh_token, :text
    add_column :users, :tastytrade_oauth_expires_at, :datetime
  end
end
