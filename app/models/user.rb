class User < ApplicationRecord
  has_secure_password
  
  has_many :orders, dependent: :destroy
  has_many :positions, dependent: :destroy
  has_many :strategies, dependent: :destroy
  has_many :portfolio_protections, dependent: :destroy
  has_many :trade_scan_results, dependent: :destroy
  has_many :sandbox_test_results, dependent: :destroy
  
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, :last_name, presence: true
  validates :tastytrade_customer_id, presence: true
  
  scope :active, -> { where(active: true) }
  
  def full_name
    "#{first_name} #{last_name}"
  end
  
  def tastytrade_authenticated?
    Rails.cache.exist?("tastytrade_token_#{email}")
  end
  
  # Get or create portfolio protection for an account
  def portfolio_protection_for(account_id)
    portfolio_protections.find_or_create_by(account_id: account_id) do |protection|
      # Set conservative defaults for new protections
      protection.cash_reserve_percentage = 25.0
      protection.max_daily_loss_percentage = 5.0
      protection.max_single_trade_percentage = 10.0
      protection.max_portfolio_exposure_percentage = 75.0
      protection.active = true
    end
  end
  
  # Check if any emergency stops are active
  def has_active_emergency_stops?
    portfolio_protections.any?(&:emergency_stop_active?)
  end
  
  # Get all active portfolio protections
  def active_portfolio_protections
    portfolio_protections.active
  end
  
  # Scanner and trading preferences
  def wants_trade_notifications?
    # TODO: Add user preference field
    false
  end
  
  def auto_trading_enabled?
    # TODO: Add user preference field
    false
  end
  
  def tastytrade_account_id
    # For now, use customer ID as account ID
    # TODO: Handle multiple accounts per user
    tastytrade_customer_id
  end
end