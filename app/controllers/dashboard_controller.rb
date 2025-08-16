class DashboardController < ApplicationController
  before_action :skip_mfa_in_development, only: [:index]
  
  def index
    @user = current_user
    @recent_orders = current_user.orders.includes(:legs).order(created_at: :desc).limit(10)
    @positions = current_user.positions.where.not(quantity: 0).order(:symbol)
    @tastytrade_authenticated = current_user.tastytrade_authenticated?

    # Calculate portfolio summary
    @portfolio_summary = calculate_portfolio_summary
  end

  private
  
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
end
