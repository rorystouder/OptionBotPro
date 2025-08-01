class CreatePortfolioProtections < ActiveRecord::Migration[8.0]
  def change
    create_table :portfolio_protections do |t|
      t.references :user, null: false, foreign_key: true
      t.string :account_id, null: false

      # Core protection settings
      t.decimal :cash_reserve_percentage, precision: 5, scale: 2, default: 25.0, null: false
      t.decimal :max_daily_loss_percentage, precision: 5, scale: 2, default: 5.0, null: false
      t.decimal :max_single_trade_percentage, precision: 5, scale: 2, default: 10.0, null: false
      t.decimal :max_portfolio_exposure_percentage, precision: 5, scale: 2, default: 75.0, null: false

      # Status flags
      t.boolean :active, default: true, null: false

      # Emergency stop tracking
      t.datetime :emergency_stop_triggered_at
      t.string :emergency_stop_reason
      t.string :emergency_stop_triggered_by
      t.datetime :emergency_stop_cleared_at
      t.string :emergency_stop_cleared_by

      # Additional risk settings
      t.decimal :max_position_concentration_percentage, precision: 5, scale: 2, default: 20.0
      t.integer :max_daily_trades, default: 50
      t.decimal :trailing_stop_percentage, precision: 5, scale: 2, default: 2.0

      # Notification settings
      t.boolean :email_alerts_enabled, default: true
      t.boolean :sms_alerts_enabled, default: false
      t.string :alert_phone_number

      t.timestamps
    end

    add_index :portfolio_protections, [:user_id, :account_id], unique: true
    add_index :portfolio_protections, :account_id
    add_index :portfolio_protections, :active
    add_index :portfolio_protections, :emergency_stop_triggered_at

    # Add constraints to ensure safe values
    add_check_constraint :portfolio_protections,
      "cash_reserve_percentage >= 20.0 AND cash_reserve_percentage <= 50.0",
      name: "cash_reserve_range_check"

    add_check_constraint :portfolio_protections,
      "max_daily_loss_percentage > 0 AND max_daily_loss_percentage <= 15.0",
      name: "daily_loss_range_check"

    add_check_constraint :portfolio_protections,
      "max_single_trade_percentage > 0 AND max_single_trade_percentage <= 20.0",
      name: "single_trade_range_check"

    add_check_constraint :portfolio_protections,
      "max_portfolio_exposure_percentage >= 50.0 AND max_portfolio_exposure_percentage <= 85.0",
      name: "exposure_range_check"
  end
end