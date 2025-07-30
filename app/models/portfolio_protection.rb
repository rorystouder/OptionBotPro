class PortfolioProtection < ApplicationRecord
  belongs_to :user
  
  validates :account_id, presence: true
  validates :max_daily_loss_percentage, presence: true, 
            numericality: { greater_than: 0, less_than_or_equal_to: 10 }
  validates :cash_reserve_percentage, presence: true,
            numericality: { greater_than_or_equal_to: 25, less_than_or_equal_to: 50 }
  validates :max_single_trade_percentage, presence: true,
            numericality: { greater_than: 0, less_than_or_equal_to: 15 }
  validates :max_portfolio_exposure_percentage, presence: true,
            numericality: { greater_than: 50, less_than_or_equal_to: 80 }
  
  # Default safety settings - these are conservative for automated trading
  before_validation :set_defaults, on: :create
  
  scope :active, -> { where(active: true) }
  scope :for_account, ->(account_id) { where(account_id: account_id) }
  
  def self.for_user_account(user, account_id)
    find_or_create_by(user: user, account_id: account_id) do |protection|
      protection.set_defaults
    end
  end
  
  # Check if emergency stop is active for this protection setting
  def emergency_stop_active?
    emergency_stop_triggered_at.present? && 
    emergency_stop_triggered_at > 24.hours.ago
  end
  
  # Activate emergency stop
  def activate_emergency_stop!(reason, triggered_by = 'system')
    update!(
      emergency_stop_triggered_at: Time.current,
      emergency_stop_reason: reason,
      emergency_stop_triggered_by: triggered_by,
      active: false
    )
    
    Rails.logger.critical "EMERGENCY STOP ACTIVATED - User: #{user.email}, Account: #{account_id}, Reason: #{reason}"
  end
  
  # Clear emergency stop (requires manual intervention)
  def clear_emergency_stop!(cleared_by)
    update!(
      emergency_stop_triggered_at: nil,
      emergency_stop_reason: nil,
      emergency_stop_triggered_by: nil,
      emergency_stop_cleared_by: cleared_by,
      emergency_stop_cleared_at: Time.current,
      active: true
    )
    
    Rails.logger.info "EMERGENCY STOP CLEARED - User: #{user.email}, Account: #{account_id}, Cleared by: #{cleared_by}"
  end
  
  # Calculate available buying power after reserves
  def available_buying_power(total_buying_power)
    return 0 if total_buying_power <= 0
    
    available = total_buying_power * ((100 - cash_reserve_percentage) / 100.0)
    [available, 0].max
  end
  
  # Calculate maximum trade size
  def max_trade_size(portfolio_value)
    return 0 if portfolio_value <= 0
    
    portfolio_value * (max_single_trade_percentage / 100.0)
  end
  
  # Check if daily loss limit is breached
  def daily_loss_limit_breached?(daily_pnl, portfolio_value)
    return false if daily_pnl >= 0 || portfolio_value <= 0
    
    daily_loss_percentage = (daily_pnl.abs / portfolio_value) * 100
    daily_loss_percentage >= max_daily_loss_percentage
  end
  
  # Generate risk status report
  def risk_status_report(account_data)
    {
      protection_id: id,
      account_id: account_id,
      active: active,
      emergency_stop_active: emergency_stop_active?,
      settings: {
        cash_reserve_percentage: cash_reserve_percentage,
        max_daily_loss_percentage: max_daily_loss_percentage,
        max_single_trade_percentage: max_single_trade_percentage,
        max_portfolio_exposure_percentage: max_portfolio_exposure_percentage
      },
      current_status: calculate_current_status(account_data),
      violations: check_current_violations(account_data),
      last_updated: updated_at
    }
  end
  
  private
  
  def set_defaults
    self.cash_reserve_percentage ||= 25.0              # Must keep 25% cash reserve
    self.max_daily_loss_percentage ||= 5.0             # Stop trading at 5% daily loss
    self.max_single_trade_percentage ||= 10.0          # No trade larger than 10% of portfolio
    self.max_portfolio_exposure_percentage ||= 75.0    # Maximum 75% portfolio exposure
    self.active ||= true
    self.created_at ||= Time.current
  end
  
  def calculate_current_status(account_data)
    return {} unless account_data
    
    buying_power = account_data[:buying_power] || 0
    portfolio_value = account_data[:total_portfolio_value] || 0
    daily_pnl = account_data[:daily_pnl] || 0
    cash_balance = account_data[:cash_balance] || 0
    
    current_exposure = portfolio_value - cash_balance
    exposure_percentage = portfolio_value > 0 ? (current_exposure / portfolio_value) * 100 : 0
    daily_pnl_percentage = portfolio_value > 0 ? (daily_pnl / portfolio_value) * 100 : 0
    cash_reserve_percentage_actual = buying_power > 0 ? (cash_balance / buying_power) * 100 : 0
    
    {
      available_for_trading: available_buying_power(buying_power),
      current_exposure_percentage: exposure_percentage.round(2),
      daily_pnl_percentage: daily_pnl_percentage.round(2),
      cash_reserve_percentage_actual: cash_reserve_percentage_actual.round(2),
      max_single_trade_amount: max_trade_size(portfolio_value).round(2)
    }
  end
  
  def check_current_violations(account_data)
    violations = []
    return violations unless account_data
    
    status = calculate_current_status(account_data)
    
    # Check cash reserve violation
    if status[:cash_reserve_percentage_actual] < cash_reserve_percentage
      violations << "Cash reserve below required #{cash_reserve_percentage}% (current: #{status[:cash_reserve_percentage_actual]}%)"
    end
    
    # Check exposure violation
    if status[:current_exposure_percentage] > max_portfolio_exposure_percentage
      violations << "Portfolio exposure exceeds maximum #{max_portfolio_exposure_percentage}% (current: #{status[:current_exposure_percentage]}%)"
    end
    
    # Check daily loss violation
    if status[:daily_pnl_percentage] <= -max_daily_loss_percentage
      violations << "Daily loss exceeds maximum #{max_daily_loss_percentage}% (current: #{status[:daily_pnl_percentage]}%)"
    end
    
    violations
  end
end