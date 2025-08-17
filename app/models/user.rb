class User < ApplicationRecord
  has_secure_password

  has_many :orders, dependent: :destroy
  has_many :positions, dependent: :destroy
  has_many :strategies, dependent: :destroy
  has_many :portfolio_protections, dependent: :destroy
  has_many :trade_scan_results, dependent: :destroy
  has_many :sandbox_test_results, dependent: :destroy

  belongs_to :subscription_tier, optional: true

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, :last_name, presence: true
  validates :encrypted_tastytrade_username, :encrypted_tastytrade_password, presence: true
  validates :subscription_status, inclusion: { in: %w[trial active past_due canceled suspended] }
  validates :password_reset_token, uniqueness: true, allow_nil: true

  scope :active, -> { where(active: true) }
  scope :admins, -> { where(admin: true) }
  scope :trial_users, -> { where(subscription_status: "trial") }
  scope :paying_users, -> { where(subscription_status: "active") }

  def full_name
    "#{first_name} #{last_name}"
  end

  def tastytrade_authenticated?
    # Check OAuth token first (preferred method)
    if tastytrade_oauth_token.present? && tastytrade_oauth_expires_at.present?
      return tastytrade_oauth_expires_at > Time.current
    end
    
    # Fallback to username/password authentication
    username = tastytrade_username
    return false if username.nil?
    Rails.cache.exist?("tastytrade_token_#{username}")
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

  # TastyTrade credential encryption/decryption
  def tastytrade_username=(username)
    return if username.blank?

    cipher = OpenSSL::Cipher.new("AES-256-CBC")
    cipher.encrypt
    cipher.key = encryption_key
    self.tastytrade_credentials_iv = Base64.encode64(cipher.random_iv)
    cipher.iv = Base64.decode64(self.tastytrade_credentials_iv)

    self.encrypted_tastytrade_username = Base64.encode64(cipher.update(username) + cipher.final)
  end

  def tastytrade_username
    return nil if encrypted_tastytrade_username.blank? || tastytrade_credentials_iv.blank?

    begin
      cipher = OpenSSL::Cipher.new("AES-256-CBC")
      cipher.decrypt
      cipher.key = encryption_key
      cipher.iv = Base64.decode64(tastytrade_credentials_iv)

      decrypted = cipher.update(Base64.decode64(encrypted_tastytrade_username)) + cipher.final
      decrypted
    rescue OpenSSL::Cipher::CipherError => e
      Rails.logger.error "Failed to decrypt TastyTrade username for user #{id}: #{e.message}"
      nil
    end
  end

  def tastytrade_password=(password)
    return if password.blank?

    cipher = OpenSSL::Cipher.new("AES-256-CBC")
    cipher.encrypt
    cipher.key = encryption_key
    # Use same IV as username for consistency
    self.tastytrade_credentials_iv ||= Base64.encode64(cipher.random_iv)
    cipher.iv = Base64.decode64(self.tastytrade_credentials_iv)

    self.encrypted_tastytrade_password = Base64.encode64(cipher.update(password) + cipher.final)
  end

  def tastytrade_password
    return nil if encrypted_tastytrade_password.blank? || tastytrade_credentials_iv.blank?

    begin
      cipher = OpenSSL::Cipher.new("AES-256-CBC")
      cipher.decrypt
      cipher.key = encryption_key
      cipher.iv = Base64.decode64(tastytrade_credentials_iv)

      decrypted = cipher.update(Base64.decode64(encrypted_tastytrade_password)) + cipher.final
      decrypted
    rescue OpenSSL::Cipher::CipherError => e
      Rails.logger.error "Failed to decrypt TastyTrade password for user #{id}: #{e.message}"
      nil
    end
  end

  def tastytrade_account_id
    # TastyTrade uses username as account identifier
    tastytrade_username
  end

  # Subscription management methods
  def on_trial?
    subscription_status == "trial" && trial_active?
  end

  def trial_active?
    trial_ends_at.present? && trial_ends_at > Time.current
  end

  def trial_expired?
    trial_ends_at.present? && trial_ends_at <= Time.current
  end

  def subscription_active?
    %w[trial active].include?(subscription_status) && !subscription_expired?
  end

  def subscription_expired?
    return false if on_trial?
    subscription_ends_at.present? && subscription_ends_at <= Time.current
  end

  def can_trade?
    subscription_active? && !has_active_emergency_stops?
  end

  def daily_trades_remaining
    return Float::INFINITY if subscription_tier&.unlimited_trades?

    max_trades = subscription_tier&.max_daily_trades || 0
    today_trades = orders.where(created_at: Date.current.beginning_of_day..Date.current.end_of_day).count
    [ max_trades - today_trades, 0 ].max
  end

  def can_place_trade?(trade_amount = 0)
    return false unless can_trade?
    return false if daily_trades_remaining <= 0

    # Check trading capital limits
    if subscription_tier&.max_trading_capital.present? && trade_amount > 0
      return false if trade_amount > subscription_tier.max_trading_capital
    end

    true
  end

  def subscription_tier_name
    subscription_tier&.name || "No Subscription"
  end

  def days_until_trial_ends
    return 0 unless trial_active?
    ((trial_ends_at - Time.current) / 1.day).ceil
  end

  def initialize_trial
    return if trial_ends_at.present?

    self.trial_ends_at = 14.days.from_now
    self.subscription_status = "trial"
    save!
  end

  # MFA (Multi-Factor Authentication) methods
  def mfa_enabled?
    !!mfa_enabled
  end

  def enable_mfa!
    self.mfa_secret = ROTP::Base32.random
    self.mfa_backup_codes = generate_backup_codes
    self.mfa_enabled = true
    save!
  end

  def disable_mfa!
    self.mfa_enabled = false
    self.mfa_secret = nil
    self.mfa_backup_codes = nil
    save!
  end

  def mfa_qr_code
    return nil unless mfa_secret

    totp = ROTP::TOTP.new(mfa_secret, issuer: "OptionBotPro")
    provisioning_uri = totp.provisioning_uri(email)

    RQRCode::QRCode.new(provisioning_uri)
  end

  def verify_mfa_code(code)
    return false unless mfa_enabled? && mfa_secret

    # Check TOTP code
    totp = ROTP::TOTP.new(mfa_secret)
    return true if totp.verify(code, drift_behind: 30, drift_ahead: 30)

    # Check backup codes
    verify_backup_code(code)
  end

  def verify_mfa_setup_code(code)
    # For verification during setup (before MFA is enabled)
    return false unless mfa_secret.present?
    totp = ROTP::TOTP.new(mfa_secret)
    totp.verify(code, drift_behind: 30, drift_ahead: 30)
  end

  def verify_backup_code(code)
    return false unless mfa_backup_codes.present?

    codes = JSON.parse(mfa_backup_codes)
    if codes.include?(code.to_s.downcase)
      # Remove used backup code
      codes.delete(code.to_s.downcase)
      self.mfa_backup_codes = codes.to_json
      save!
      return true
    end

    false
  end

  def generate_backup_codes
    codes = []
    8.times do
      codes << SecureRandom.hex(4).downcase
    end
    codes.to_json
  end

  def backup_codes_array
    return [] unless mfa_backup_codes.present?
    JSON.parse(mfa_backup_codes)
  end

  def remaining_backup_codes
    backup_codes_array.count
  end

  # Password reset methods
  def password_reset_expired?
    return true unless password_reset_sent_at
    password_reset_sent_at < 2.hours.ago
  end

  def clear_password_reset!
    self.password_reset_token = nil
    self.password_reset_sent_at = nil
    self.password_reset_required = false
    save!
  end

  private

  def encryption_key
    # Use Rails' secret key base with user's ID for per-user encryption
    key_material = "#{Rails.application.secret_key_base}-user-#{id}"
    Digest::SHA256.digest(key_material)
  end
end
