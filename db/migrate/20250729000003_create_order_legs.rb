class CreateOrderLegs < ActiveRecord::Migration[8.0]
  def change
    create_table :order_legs do |t|
      t.references :order, null: false, foreign_key: true
      t.string :symbol, null: false
      t.integer :quantity, null: false
      t.string :action, null: false
      t.decimal :price, precision: 10, scale: 4
      t.integer :leg_number, null: false

      t.timestamps
    end

    add_index :order_legs, [:order_id, :leg_number], unique: true
    add_index :order_legs, :symbol
  end
end