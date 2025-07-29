class Api::V1::AccountsController < Api::BaseController
  def index
    api_service = Tastytrade::ApiService.new(current_user)
    accounts = api_service.get_accounts
    
    render_success(accounts)
  rescue => e
    render_error("Failed to fetch accounts: #{e.message}")
  end
  
  def show
    api_service = Tastytrade::ApiService.new(current_user)
    account = api_service.get_account(params[:id])
    
    render_success(account)
  rescue => e
    render_error("Failed to fetch account: #{e.message}")
  end
  
  def balances
    api_service = Tastytrade::ApiService.new(current_user)
    balances = api_service.get_balances(params[:id])
    
    render_success(balances)
  rescue => e
    render_error("Failed to fetch balances: #{e.message}")
  end
end