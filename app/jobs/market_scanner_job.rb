class MarketScannerJob < ApplicationJob
  queue_as :default

  # Run every 5 minutes during market hours
  def perform(user_id)
    user = User.find(user_id)

    # Check if user is authenticated with TastyTrade
    unless user.tastytrade_authenticated?
      Rails.logger.warn "User #{user.id} not authenticated with TastyTrade, skipping scan"
      return
    end

    # Check if trading is enabled for user
    if user.has_active_emergency_stops?
      Rails.logger.info "User #{user.id} has active emergency stops, skipping scan"
      return
    end

    # Check if markets are open
    unless market_hours?
      Rails.logger.info "Markets closed, skipping scan for user #{user.id}"
      return
    end

    scanner = MarketScannerService.new(user: user)
    selected_trades = scanner.scan_for_opportunities

    if selected_trades.any?
      Rails.logger.info "Found #{selected_trades.size} trades for user #{user.id}"

      # Store scan results
      store_scan_results(user, selected_trades)

      # Notify user of opportunities (if configured)
      notify_user_of_opportunities(user, selected_trades) if user.wants_trade_notifications?

      # Auto-execute if enabled
      if user.auto_trading_enabled?
        execute_selected_trades(user, selected_trades)
      end
    else
      Rails.logger.info "No trades found meeting criteria for user #{user.id}"
    end

  rescue => e
    Rails.logger.error "MarketScannerJob failed for user #{user.id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  private

  def market_hours?
    # Simple market hours check (9:30 AM - 4:00 PM ET, Monday-Friday)
    now = Time.current.in_time_zone('Eastern Time (US & Canada)')

    # Check if it's a weekday
    return false unless now.wday.between?(1, 5)

    # Check if it's within market hours
    market_open = now.beginning_of_day + 9.hours + 30.minutes
    market_close = now.beginning_of_day + 16.hours

    now.between?(market_open, market_close)
  end

  def store_scan_results(user, trades)
    scan_result = TradeScanResult.create!(
      user: user,
      scan_timestamp: Time.current,
      trades_found: trades.size,
      scan_data: trades.to_json
    )

    Rails.logger.info "Stored scan results #{scan_result.id} for user #{user.id}"
  end

  def notify_user_of_opportunities(user, trades)
    # Send notification about trading opportunities
    # TODO: Implement email/SMS notifications
    Rails.logger.info "Would notify user #{user.id} of #{trades.size} opportunities"
  end

  def execute_selected_trades(user, trades)
    Rails.logger.info "Auto-executing #{trades.size} trades for user #{user.id}"

    executor = TradeExecutorService.new(user: user)

    trades.each do |trade|
      begin
        result = executor.execute_trade(trade)
        Rails.logger.info "Executed trade #{trade[:symbol]} #{trade[:strategy]} for user #{user.id}: #{result}"
      rescue => e
        Rails.logger.error "Failed to execute trade #{trade[:symbol]} for user #{user.id}: #{e.message}"
      end
    end
  end
end