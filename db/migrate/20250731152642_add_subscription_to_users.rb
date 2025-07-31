class AddSubscriptionToUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :subscription_tier, null: true, foreign_key: true
    add_column :users, :subscription_status, :string, default: 'trial'
    add_column :users, :subscription_started_at, :datetime
    add_column :users, :subscription_ends_at, :datetime
    add_column :users, :stripe_customer_id, :string
    add_column :users, :stripe_subscription_id, :string
    add_column :users, :trial_ends_at, :datetime
    
    add_index :users, :subscription_status
    add_index :users, :stripe_customer_id
    add_index :users, :stripe_subscription_id
  end
end
