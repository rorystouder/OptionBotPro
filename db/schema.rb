# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_07_31_152642) do
  create_table "order_legs", force: :cascade do |t|
    t.integer "order_id", null: false
    t.string "symbol", null: false
    t.integer "quantity", null: false
    t.string "action", null: false
    t.decimal "price", precision: 10, scale: 4
    t.integer "leg_number", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id", "leg_number"], name: "index_order_legs_on_order_id_and_leg_number", unique: true
    t.index ["order_id"], name: "index_order_legs_on_order_id"
    t.index ["symbol"], name: "index_order_legs_on_symbol"
  end

  create_table "orders", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "symbol", null: false
    t.integer "quantity", null: false
    t.string "order_type", null: false
    t.string "action", null: false
    t.decimal "price", precision: 10, scale: 4
    t.decimal "stop_price", precision: 10, scale: 4
    t.string "time_in_force", default: "day", null: false
    t.string "status", default: "pending", null: false
    t.string "tastytrade_order_id"
    t.string "tastytrade_account_id"
    t.integer "filled_quantity", default: 0
    t.decimal "average_fill_price", precision: 10, scale: 4
    t.text "rejection_reason"
    t.datetime "submitted_at"
    t.datetime "filled_at"
    t.datetime "cancelled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "strategy"
    t.string "legs"
    t.date "expiration"
    t.decimal "expected_credit"
    t.decimal "max_loss"
    t.decimal "pop"
    t.text "thesis"
    t.decimal "model_score"
    t.decimal "momentum_z"
    t.decimal "flow_z"
    t.index ["created_at"], name: "index_orders_on_created_at"
    t.index ["status"], name: "index_orders_on_status"
    t.index ["symbol"], name: "index_orders_on_symbol"
    t.index ["tastytrade_order_id"], name: "index_orders_on_tastytrade_order_id", unique: true
    t.index ["user_id", "status"], name: "index_orders_on_user_id_and_status"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "portfolio_protections", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "account_id", null: false
    t.decimal "cash_reserve_percentage", precision: 5, scale: 2, default: "25.0", null: false
    t.decimal "max_daily_loss_percentage", precision: 5, scale: 2, default: "5.0", null: false
    t.decimal "max_single_trade_percentage", precision: 5, scale: 2, default: "10.0", null: false
    t.decimal "max_portfolio_exposure_percentage", precision: 5, scale: 2, default: "75.0", null: false
    t.boolean "active", default: true, null: false
    t.datetime "emergency_stop_triggered_at"
    t.string "emergency_stop_reason"
    t.string "emergency_stop_triggered_by"
    t.datetime "emergency_stop_cleared_at"
    t.string "emergency_stop_cleared_by"
    t.decimal "max_position_concentration_percentage", precision: 5, scale: 2, default: "20.0"
    t.integer "max_daily_trades", default: 50
    t.decimal "trailing_stop_percentage", precision: 5, scale: 2, default: "2.0"
    t.boolean "email_alerts_enabled", default: true
    t.boolean "sms_alerts_enabled", default: false
    t.string "alert_phone_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_portfolio_protections_on_account_id"
    t.index ["active"], name: "index_portfolio_protections_on_active"
    t.index ["emergency_stop_triggered_at"], name: "index_portfolio_protections_on_emergency_stop_triggered_at"
    t.index ["user_id", "account_id"], name: "index_portfolio_protections_on_user_id_and_account_id", unique: true
    t.index ["user_id"], name: "index_portfolio_protections_on_user_id"
    t.check_constraint "cash_reserve_percentage >= 20.0 AND cash_reserve_percentage <= 50.0", name: "cash_reserve_range_check"
    t.check_constraint "max_daily_loss_percentage > 0 AND max_daily_loss_percentage <= 15.0", name: "daily_loss_range_check"
    t.check_constraint "max_portfolio_exposure_percentage >= 50.0 AND max_portfolio_exposure_percentage <= 85.0", name: "exposure_range_check"
    t.check_constraint "max_single_trade_percentage > 0 AND max_single_trade_percentage <= 20.0", name: "single_trade_range_check"
  end

  create_table "positions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "symbol", null: false
    t.integer "quantity", null: false
    t.decimal "average_price", precision: 10, scale: 4, null: false
    t.decimal "current_price", precision: 10, scale: 4
    t.string "tastytrade_account_id", null: false
    t.datetime "last_updated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["last_updated_at"], name: "index_positions_on_last_updated_at"
    t.index ["symbol"], name: "index_positions_on_symbol"
    t.index ["tastytrade_account_id"], name: "index_positions_on_tastytrade_account_id"
    t.index ["user_id", "symbol"], name: "index_positions_on_user_id_and_symbol", unique: true
    t.index ["user_id"], name: "index_positions_on_user_id"
  end

  create_table "sandbox_test_results", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "test_timestamp"
    t.integer "total_tests"
    t.integer "passed_tests"
    t.integer "failed_tests"
    t.decimal "success_rate"
    t.text "test_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sandbox_test_results_on_user_id"
  end

  create_table "subscription_tiers", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.decimal "price_monthly", precision: 8, scale: 2, null: false
    t.integer "max_daily_trades"
    t.decimal "max_trading_capital", precision: 12, scale: 2
    t.integer "max_accounts", default: 1
    t.text "features"
    t.text "description"
    t.boolean "active", default: true
    t.integer "sort_order", default: 0
    t.string "stripe_price_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_subscription_tiers_on_active"
    t.index ["slug"], name: "index_subscription_tiers_on_slug", unique: true
    t.index ["sort_order"], name: "index_subscription_tiers_on_sort_order"
  end

  create_table "trade_scan_results", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "scan_timestamp"
    t.integer "trades_found"
    t.text "scan_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_trade_scan_results_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_tastytrade_username"
    t.string "encrypted_tastytrade_password"
    t.string "tastytrade_credentials_iv"
    t.integer "subscription_tier_id"
    t.string "subscription_status", default: "trial"
    t.datetime "subscription_started_at"
    t.datetime "subscription_ends_at"
    t.string "stripe_customer_id"
    t.string "stripe_subscription_id"
    t.datetime "trial_ends_at"
    t.index ["active"], name: "index_users_on_active"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["encrypted_tastytrade_username"], name: "index_users_on_encrypted_tastytrade_username"
    t.index ["stripe_customer_id"], name: "index_users_on_stripe_customer_id"
    t.index ["stripe_subscription_id"], name: "index_users_on_stripe_subscription_id"
    t.index ["subscription_status"], name: "index_users_on_subscription_status"
    t.index ["subscription_tier_id"], name: "index_users_on_subscription_tier_id"
  end

  add_foreign_key "order_legs", "orders"
  add_foreign_key "orders", "users"
  add_foreign_key "portfolio_protections", "users"
  add_foreign_key "positions", "users"
  add_foreign_key "sandbox_test_results", "users"
  add_foreign_key "trade_scan_results", "users"
  add_foreign_key "users", "subscription_tiers"
end
