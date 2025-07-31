class CreateTradeScanResults < ActiveRecord::Migration[8.0]
  def change
    create_table :trade_scan_results do |t|
      t.references :user, null: false, foreign_key: true
      t.datetime :scan_timestamp
      t.integer :trades_found
      t.text :scan_data

      t.timestamps
    end
  end
end
