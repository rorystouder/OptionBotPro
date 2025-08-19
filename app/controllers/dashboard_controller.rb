class DashboardController < ApplicationController
  before_action :skip_mfa_in_development, only: [ :index ]

  def index
    @user = current_user
    @tastytrade_authenticated = current_user.tastytrade_authenticated?

    if @tastytrade_authenticated
      fetch_tastytrade_data
    else
      # Use local database records if not connected to TastyTrade
      @recent_orders = current_user.orders.includes(:legs).order(created_at: :desc).limit(10)
      @positions = current_user.positions.where.not(quantity: 0).order(:symbol)
      @portfolio_summary = calculate_portfolio_summary
      @accounts = []
    end
  end

  private

  def fetch_tastytrade_data
    begin
      api_service = Tastytrade::ApiService.new(current_user)

      # Get accounts
      accounts_response = api_service.get_accounts
      @accounts = accounts_response.dig("data", "items") || []

      if @accounts.any?
        # Use the first account for now
        account_id = @accounts.first["account"]["account-number"]

        # Get positions
        positions_response = api_service.get_positions(account_id)
        @positions = positions_response.dig("data", "items") || []

        # Get account balances
        balances_response = api_service.get_balances(account_id)
        @balances = balances_response.dig("data") || {}

        # Calculate portfolio summary from live data
        @portfolio_summary = calculate_tastytrade_portfolio_summary

        # Get recent orders (transactions)
        transactions_response = api_service.get_transactions(account_id, { limit: 10 })
        @recent_orders = transactions_response.dig("data", "items") || []
      else
        @positions = []
        @balances = {}
        @portfolio_summary = { total_positions: 0, total_market_value: 0, total_unrealized_pnl: 0, options_count: 0, stocks_count: 0 }
        @recent_orders = []
      end

    rescue => e
      Rails.logger.error "Failed to fetch TastyTrade data: #{e.message}"
      flash[:alert] = "Unable to fetch TastyTrade data. Please check your connection."
      @accounts = []
      @positions = []
      @balances = {}
      @portfolio_summary = { total_positions: 0, total_market_value: 0, total_unrealized_pnl: 0, options_count: 0, stocks_count: 0 }
      @recent_orders = []
    end
  end

  def skip_mfa_in_development
    if Rails.env.development? && params[:skip_mfa] == "true"
      session[:mfa_verified] = true
    end
  end

  def calculate_portfolio_summary
    positions = current_user.positions.where.not(quantity: 0)

    {
      total_positions: positions.count,
      total_market_value: positions.sum(&:market_value).to_f.round(2),
      total_unrealized_pnl: positions.sum(&:unrealized_pnl).to_f.round(2),
      options_count: positions.options.count,
      stocks_count: positions.stocks.count
    }
  end

  def calculate_tastytrade_portfolio_summary
    return { total_positions: 0, total_market_value: 0, total_unrealized_pnl: 0, options_count: 0, stocks_count: 0 } if @positions.blank?

    total_market_value = @balances.dig("cash-balance") || 0
    total_unrealized_pnl = 0
    options_count = 0
    stocks_count = 0

    @positions.each do |position|
      instrument = position["instrument"]
      quantity = position["quantity"].to_i

      next if quantity == 0

      if instrument["instrument-type"] == "Equity Option"
        options_count += 1
      elsif instrument["instrument-type"] == "Equity"
        stocks_count += 1
      end

      # Calculate unrealized P&L if available
      if position["mark-price"] && position["average-price"]
        mark_price = position["mark-price"].to_f
        avg_price = position["average-price"].to_f
        total_unrealized_pnl += (mark_price - avg_price) * quantity
      end
    end

    {
      total_positions: @positions.length,
      total_market_value: total_market_value.to_f.round(2),
      total_unrealized_pnl: total_unrealized_pnl.round(2),
      options_count: options_count,
      stocks_count: stocks_count
    }
  end
end
