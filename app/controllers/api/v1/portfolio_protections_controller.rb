class Api::V1::PortfolioProtectionsController < Api::BaseController
  before_action :set_protection, only: [:show, :update, :emergency_stop, :clear_emergency_stop]
  
  def index
    protections = current_user.portfolio_protections.includes(:user)
    
    render_success({
      protections: protections.map(&:risk_status_report)
    })
  end
  
  def show
    account_data = fetch_account_data(@protection.account_id)
    render_success(@protection.risk_status_report(account_data))
  end
  
  def create
    # Validate account ownership before creating protection
    account_id = protection_params[:account_id]
    if account_id.present? && !validate_account_ownership(account_id)
      render_error('Invalid account ID', :forbidden)
      return
    end
    
    protection = current_user.portfolio_protections.build(protection_params)
    
    if protection.save
      render_success(
        protection.risk_status_report({}), 
        'Portfolio protection created successfully',
        :created
      )
    else
      render_error('Failed to create portfolio protection', :unprocessable_entity, protection.errors.full_messages)
    end
  end
  
  def update
    if @protection.update(protection_params)
      account_data = fetch_account_data(@protection.account_id)
      render_success(
        @protection.risk_status_report(account_data),
        'Portfolio protection updated successfully'
      )
    else
      render_error('Failed to update portfolio protection', :unprocessable_entity, @protection.errors.full_messages)
    end
  end
  
  def status
    account_id = params[:account_id]
    protection = current_user.portfolio_protection_for(account_id)
    
    begin
      risk_service = RiskManagementService.new(current_user, account_id)
      portfolio_status = risk_service.portfolio_status
      
      render_success({
        protection: protection.risk_status_report(portfolio_status),
        portfolio_status: portfolio_status,
        emergency_stop_active: risk_service.emergency_stop_active?,
        trading_allowed: !risk_service.emergency_stop_active? && protection.active?
      })
    rescue => e
      render_error("Failed to get portfolio status: #{e.message}")
    end
  end
  
  def emergency_stop
    reason = params[:reason] || 'Manual emergency stop triggered'
    triggered_by = params[:triggered_by] || current_user.email
    
    begin
      @protection.activate_emergency_stop!(reason, triggered_by)
      
      # Also trigger the cache-based emergency stop
      risk_service = RiskManagementService.new(current_user, @protection.account_id)
      risk_service.emergency_stop!(reason)
      
      render_success(
        { 
          protection: @protection.reload.risk_status_report({}),
          message: "Emergency stop activated for account #{@protection.account_id}"
        },
        'Emergency stop activated successfully'
      )
    rescue => e
      render_error("Failed to activate emergency stop: #{e.message}")
    end
  end
  
  def clear_emergency_stop
    cleared_by = params[:cleared_by] || current_user.email
    
    # Require confirmation for clearing emergency stop
    unless params[:confirm] == 'true'
      render_error('Emergency stop clearance requires confirmation (confirm=true)', :bad_request)
      return
    end
    
    begin
      @protection.clear_emergency_stop!(cleared_by)
      
      # Clear the cache-based emergency stop
      risk_service = RiskManagementService.new(current_user, @protection.account_id)
      risk_service.clear_emergency_stop!(cleared_by)
      
      render_success(
        {
          protection: @protection.reload.risk_status_report({}),
          message: "Emergency stop cleared for account #{@protection.account_id}"
        },
        'Emergency stop cleared successfully'
      )
    rescue => e
      render_error("Failed to clear emergency stop: #{e.message}")
    end
  end
  
  def validate_trade
    unless params[:order].present?
      render_error('Order parameters required for validation')
      return
    end
    
    account_id = params[:account_id] || params.dig(:order, :account_id)
    unless account_id.present?
      render_error('Account ID required for trade validation')
      return
    end
    
    begin
      risk_service = RiskManagementService.new(current_user, account_id)
      validation_result = risk_service.validate_trade(order_params)
      
      render_success({
        allowed: validation_result[:allowed],
        violations: validation_result[:violations],
        account_data: validation_result[:account_data],
        calculations: validation_result[:calculations],
        timestamp: Time.current
      })
    rescue => e
      render_error("Trade validation failed: #{e.message}")
    end
  end
  
  private
  
  def set_protection
    @protection = current_user.portfolio_protections.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error('Portfolio protection not found', :not_found)
  end
  
  def protection_params
    params.require(:portfolio_protection).permit(
      :account_id,
      :cash_reserve_percentage,
      :max_daily_loss_percentage,
      :max_single_trade_percentage,
      :max_portfolio_exposure_percentage,
      :max_position_concentration_percentage,
      :max_daily_trades,
      :trailing_stop_percentage,
      :email_alerts_enabled,
      :sms_alerts_enabled,
      :alert_phone_number,
      :active
    )
  end
  
  def validate_account_ownership(account_id)
    # Fetch user's accounts from TastyTrade API and verify ownership
    api_service = Tastytrade::ApiService.new(current_user)
    accounts = api_service.get_accounts
    
    # Check if the provided account_id belongs to the current user
    accounts['data']['accounts'].any? { |account| account['account-number'] == account_id }
  rescue => e
    Rails.logger.error "Failed to validate account ownership: #{e.message}"
    false
  end
  
  def order_params
    params.require(:order).permit(
      :symbol, :quantity, :order_type, :action, :price, :stop_price, :time_in_force
    )
  end
  
  def fetch_account_data(account_id)
    api_service = Tastytrade::ApiService.new(current_user)
    risk_service = RiskManagementService.new(current_user, account_id)
    risk_service.portfolio_status
  rescue => e
    Rails.logger.error "Failed to fetch account data: #{e.message}"
    {}
  end
end