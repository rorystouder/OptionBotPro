class CreatePositions < ActiveRecord::Migration[8.0]
  def change
    create_table :positions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :symbol, null: false
      t.integer :quantity, null: false
      t.decimal :average_price, precision: 10, scale: 4, null: false
      t.decimal :current_price, precision: 10, scale: 4
      t.string :tastytrade_account_id, null: false
      t.datetime :last_updated_at

      t.timestamps
    end

    add_index :positions, [:user_id, :symbol], unique: true
    add_index :positions, :symbol
    add_index :positions, :tastytrade_account_id
    add_index :positions, :last_updated_at
  end
end