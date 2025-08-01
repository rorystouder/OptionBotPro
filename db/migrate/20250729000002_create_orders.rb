class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :symbol, null: false
      t.integer :quantity, null: false
      t.string :order_type, null: false
      t.string :action, null: false
      t.decimal :price, precision: 10, scale: 4
      t.decimal :stop_price, precision: 10, scale: 4
      t.string :time_in_force, default: 'day', null: false
      t.string :status, default: 'pending', null: false
      t.string :tastytrade_order_id
      t.string :tastytrade_account_id
      t.integer :filled_quantity, default: 0
      t.decimal :average_fill_price, precision: 10, scale: 4
      t.text :rejection_reason
      t.datetime :submitted_at
      t.datetime :filled_at
      t.datetime :cancelled_at

      t.timestamps
    end

    add_index :orders, [:user_id, :status]
    add_index :orders, :symbol
    add_index :orders, :tastytrade_order_id, unique: true
    add_index :orders, :status
    add_index :orders, :created_at
  end
end