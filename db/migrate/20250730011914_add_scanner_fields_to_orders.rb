class AddScannerFieldsToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :strategy, :string
    add_column :orders, :legs, :string
    add_column :orders, :expiration, :date
    add_column :orders, :expected_credit, :decimal
    add_column :orders, :max_loss, :decimal
    add_column :orders, :pop, :decimal
    add_column :orders, :thesis, :text
    add_column :orders, :model_score, :decimal
    add_column :orders, :momentum_z, :decimal
    add_column :orders, :flow_z, :decimal
  end
end
