class CreateSubscriptionTiers < ActiveRecord::Migration[8.0]
  def change
    create_table :subscription_tiers do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.decimal :price_monthly, precision: 8, scale: 2, null: false
      t.integer :max_daily_trades
      t.decimal :max_trading_capital, precision: 12, scale: 2
      t.integer :max_accounts, default: 1
      t.text :features
      t.text :description
      t.boolean :active, default: true
      t.integer :sort_order, default: 0
      t.string :stripe_price_id

      t.timestamps
    end

    add_index :subscription_tiers, :slug, unique: true
    add_index :subscription_tiers, :active
    add_index :subscription_tiers, :sort_order
  end
end
