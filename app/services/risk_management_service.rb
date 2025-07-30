class RiskManagementService
  include ActiveModel::Model
  include ActiveModel::Attributes
  
  # Risk Management Constants - NEVER CHANGE THESE WITHOUT CAREFUL CONSIDERATION
  MINIMUM_CASH_RESERVE_PERCENTAGE = 25.0  # Must keep 25% of buying power in reserve
  MAX_SINGLE_TRADE_PERCENTAGE = 10.0      # No single trade can exceed 10% of portfolio
  MAX_DAILY_LOSS_PERCENTAGE = 5.0         # Stop all trading if daily loss exceeds 5%
  MAX_TOTAL_EXPOSURE_PERCENTAGE = 75.0    # Maximum portfolio exposure (inverse of reserve)
  
  def initialize(user, account_id)
    @user = user
    @account_id = account_id
    @api_service = Tastytrade::ApiService.new(user)
  end
  
  # Main method to validate if a trade can be placed
  def can_place_trade?(order_params)
    result = validate_trade(order_params)
    
    # Log all risk management decisions
    log_risk_decision(order_params, result)
    
    result[:allowed]
  end
  
  # Comprehensive trade validation
  def validate_trade(order_params)
    result = {
      allowed: false,
      violations: [],
      account_data: {},
      calculations: {}
    }
    
    begin
      # Get current account data
      account_data = fetch_account_data
      result[:account_data] = account_data
      
      # Calculate trade requirements
      trade_cost = calculate_trade_cost(order_params)
      result[:calculations] = {
        trade_cost: trade_cost,
        current_buying_power: account_data[:buying_power],
        cash_reserve_required: account_data[:buying_power] * (MINIMUM_CASH_RESERVE_PERCENTAGE / 100.0),
        available_for_trading: account_data[:buying_power] * (MAX_TOTAL_EXPOSURE_PERCENTAGE / 100.0)
      }
      
      # Run all risk checks
      check_cash_reserve(result, trade_cost)
      check_single_trade_limit(result, trade_cost, account_data[:total_portfolio_value])
      check_daily_loss_limit(result, account_data)
      check_position_concentration(result, order_params, account_data)
      check_maximum_exposure(result, trade_cost)
      check_account_restrictions(result, account_data)
      
      # Trade is allowed only if no violations
      result[:allowed] = result[:violations].empty?
      
    rescue => e
      Rails.logger.error "Risk Management Error: #{e.message}"
      result[:violations] << "Risk management system error - trade blocked for safety"
    end
    
    result
  end
  
  # Get current portfolio status for dashboard
  def portfolio_status
    account_data = fetch_account_data
    
    {
      buying_power: account_data[:buying_power],
      cash_reserve_required: account_data[:buying_power] * (MINIMUM_CASH_RESERVE_PERCENTAGE / 100.0),
      available_for_trading: account_data[:buying_power] * (MAX_TOTAL_EXPOSURE_PERCENTAGE / 100.0),
      current_exposure: account_data[:total_portfolio_value] - account_data[:cash_balance],
      exposure_percentage: calculate_exposure_percentage(account_data),
      daily_pnl: account_data[:daily_pnl] || 0,
      daily_pnl_percentage: calculate_daily_pnl_percentage(account_data),
      risk_status: determine_risk_status(account_data)
    }
  end
  
  # Emergency stop - kills all trading activity
  def emergency_stop!(reason)
    Rails.logger.error "EMERGENCY STOP TRIGGERED: #{reason}"
    
    # Set emergency flag in cache
    Rails.cache.write("emergency_stop_#{@user.id}", {
      triggered_at: Time.current,
      reason: reason,
      triggered_by: 'risk_management_system'
    })
    
    # Cancel all pending orders
    cancel_all_pending_orders
    
    # Send alert (implement notification system)
    send_emergency_alert(reason)
    
    true
  end
  
  # Check if emergency stop is active
  def emergency_stop_active?
    Rails.cache.exist?("emergency_stop_#{@user.id}")
  end
  
  # Clear emergency stop (manual intervention required)
  def clear_emergency_stop!(authorized_by)
    Rails.logger.info "Emergency stop cleared by: #{authorized_by}"
    Rails.cache.delete("emergency_stop_#{@user.id}")
  end
  
  private
  
  def fetch_account_data
    account_info = @api_service.get_account(@account_id)
    balances = @api_service.get_balances(@account_id)
    positions = @api_service.get_positions(@account_id)
    
    account_data = account_info.dig('data') || {}
    balance_data = balances.dig('data') || {}
    position_data = positions.dig('data', 'items') || []
    
    {
      buying_power: balance_data['buying-power'].to_f,
      cash_balance: balance_data['cash-balance'].to_f,
      day_trading_buying_power: balance_data['day-trading-buying-power'].to_f,
      maintenance_requirement: balance_data['maintenance-requirement'].to_f,
      total_portfolio_value: calculate_total_portfolio_value(balance_data, position_data),
      daily_pnl: balance_data['daily-pnl'].to_f,
      positions: position_data
    }
  end
  
  def calculate_trade_cost(order_params)
    if order_params[:order_type] == 'market'
      # For market orders, estimate cost based on current quote
      symbol = order_params[:symbol]
      quantity = order_params[:quantity].to_i
      
      begin
        quote = @api_service.get_quote(symbol)
        price = order_params[:action].include?('buy') ? 
                quote.dig('data', 'ask').to_f : 
                quote.dig('data', 'bid').to_f
        return (price * quantity).abs
      rescue
        # If we can't get quote, use a conservative estimate
        return order_params[:price].to_f * quantity if order_params[:price]
        return 1000.0 # Conservative fallback
      end
    else
      # For limit orders, use the specified price
      price = order_params[:price].to_f
      quantity = order_params[:quantity].to_i
      (price * quantity).abs
    end
  end
  
  def check_cash_reserve(result, trade_cost)
    required_reserve = result[:account_data][:buying_power] * (MINIMUM_CASH_RESERVE_PERCENTAGE / 100.0)
    available_after_trade = result[:account_data][:buying_power] - trade_cost
    
    if available_after_trade < required_reserve
      result[:violations] << "Trade would violate cash reserve requirement (must keep #{MINIMUM_CASH_RESERVE_PERCENTAGE}% reserve)"
      result[:violations] << "Required reserve: $#{required_reserve.round(2)}, Available after trade: $#{available_after_trade.round(2)}"
    end
  end
  
  def check_single_trade_limit(result, trade_cost, portfolio_value)
    max_trade_size = portfolio_value * (MAX_SINGLE_TRADE_PERCENTAGE / 100.0)
    
    if trade_cost > max_trade_size
      result[:violations] << "Trade size exceeds maximum single trade limit (#{MAX_SINGLE_TRADE_PERCENTAGE}% of portfolio)"
      result[:violations] << "Max allowed: $#{max_trade_size.round(2)}, Requested: $#{trade_cost.round(2)}"
    end
  end
  
  def check_daily_loss_limit(result, account_data)
    daily_pnl = account_data[:daily_pnl]
    portfolio_value = account_data[:total_portfolio_value]
    
    if daily_pnl < 0
      daily_loss_percentage = (daily_pnl.abs / portfolio_value) * 100
      
      if daily_loss_percentage >= MAX_DAILY_LOSS_PERCENTAGE
        result[:violations] << "Daily loss limit exceeded (#{MAX_DAILY_LOSS_PERCENTAGE}%)"
        result[:violations] << "Current daily loss: #{daily_loss_percentage.round(2)}%"
        
        # Trigger emergency stop for severe losses
        emergency_stop!("Daily loss limit exceeded: #{daily_loss_percentage.round(2)}%")
      end
    end
  end
  
  def check_position_concentration(result, order_params, account_data)
    symbol = order_params[:symbol]
    current_positions = account_data[:positions]
    
    # Check if this would create over-concentration in a single symbol
    current_exposure = current_positions
      .select { |pos| pos['symbol'] == symbol }
      .sum { |pos| pos['market-value'].to_f.abs }
    
    trade_cost = calculate_trade_cost(order_params)
    total_exposure = current_exposure + trade_cost
    max_single_symbol = account_data[:total_portfolio_value] * 0.20 # 20% max per symbol
    
    if total_exposure > max_single_symbol
      result[:violations] << "Trade would create over-concentration in #{symbol} (max 20% per symbol)"
    end
  end
  
  def check_maximum_exposure(result, trade_cost)
    current_exposure = result[:account_data][:total_portfolio_value] - result[:account_data][:cash_balance]
    new_exposure = current_exposure + trade_cost
    max_exposure = result[:account_data][:total_portfolio_value] * (MAX_TOTAL_EXPOSURE_PERCENTAGE / 100.0)
    
    if new_exposure > max_exposure
      result[:violations] << "Trade would exceed maximum portfolio exposure (#{MAX_TOTAL_EXPOSURE_PERCENTAGE}%)"
    end
  end
  
  def check_account_restrictions(result, account_data)
    # Check for pattern day trader restrictions
    if account_data[:buying_power] < 25000 && account_data[:day_trading_buying_power] <= 0
      result[:violations] << "Pattern Day Trader restriction - insufficient day trading buying power"
    end
    
    # Check for maintenance requirements
    if account_data[:maintenance_requirement] > account_data[:cash_balance] * 0.8
      result[:violations] << "Account approaching maintenance requirement limit"
    end
  end
  
  def calculate_total_portfolio_value(balance_data, position_data)
    cash_value = balance_data['cash-balance'].to_f
    position_value = position_data.sum { |pos| pos['market-value'].to_f }
    cash_value + position_value
  end
  
  def calculate_exposure_percentage(account_data)
    return 0 if account_data[:total_portfolio_value] <= 0
    
    current_exposure = account_data[:total_portfolio_value] - account_data[:cash_balance]
    (current_exposure / account_data[:total_portfolio_value]) * 100
  end
  
  def calculate_daily_pnl_percentage(account_data)
    return 0 if account_data[:total_portfolio_value] <= 0
    
    (account_data[:daily_pnl] / account_data[:total_portfolio_value]) * 100
  end
  
  def determine_risk_status(account_data)
    daily_pnl_pct = calculate_daily_pnl_percentage(account_data)
    exposure_pct = calculate_exposure_percentage(account_data)
    
    if daily_pnl_pct <= -3.0 || exposure_pct >= 90.0
      'high_risk'
    elsif daily_pnl_pct <= -1.0 || exposure_pct >= 80.0
      'medium_risk'
    else
      'low_risk'
    end
  end
  
  def cancel_all_pending_orders
    begin
      orders = @api_service.get_orders(@account_id, { status: 'working' })
      pending_orders = orders.dig('data', 'items') || []
      
      pending_orders.each do |order|
        @api_service.cancel_order(@account_id, order['id'])
        Rails.logger.info "Cancelled order #{order['id']} due to emergency stop"
      end
    rescue => e
      Rails.logger.error "Failed to cancel orders during emergency stop: #{e.message}"
    end
  end
  
  def send_emergency_alert(reason)
    # Implement your preferred notification method
    # Email, SMS, Slack, Discord, etc.
    Rails.logger.critical "EMERGENCY TRADING HALT: #{reason} - User: #{@user.email}"
    
    # You could integrate with notification services here
    # NotificationService.send_emergency_alert(@user, reason)
  end
  
  def log_risk_decision(order_params, result)
    log_data = {
      user_id: @user.id,
      account_id: @account_id,
      timestamp: Time.current,
      order_params: order_params,
      decision: result[:allowed] ? 'APPROVED' : 'REJECTED',
      violations: result[:violations],
      account_snapshot: result[:account_data],
      calculations: result[:calculations]
    }
    
    # Log to Rails logger
    Rails.logger.info "RISK_DECISION: #{log_data.to_json}"
    
    # You could also log to a dedicated risk management table
    # RiskDecision.create!(log_data)
  end
end