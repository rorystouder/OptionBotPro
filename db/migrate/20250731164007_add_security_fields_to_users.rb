class AddSecurityFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :password_reset_required, :boolean, default: false
    add_column :users, :password_reset_token, :string
    add_column :users, :password_reset_sent_at, :datetime
    add_column :users, :mfa_enabled, :boolean, default: false
    add_column :users, :mfa_secret, :string
    add_column :users, :mfa_backup_codes, :text

    add_index :users, :password_reset_token, unique: true
    add_index :users, :mfa_enabled
  end
end
