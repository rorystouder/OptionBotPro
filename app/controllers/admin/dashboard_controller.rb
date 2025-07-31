class Admin::DashboardController < Admin::BaseController
  def index
    @stats = {
      total_users: User.count,
      trial_users: User.trial_users.count,
      paying_users: User.paying_users.count,
      total_orders: Order.count,
      active_users: User.active.count,
      monthly_revenue: calculate_monthly_revenue
    }
    
    @recent_users = User.order(created_at: :desc).limit(10)
    @recent_orders = Order.includes(:user).order(created_at: :desc).limit(10)
    @subscription_breakdown = subscription_tier_breakdown
  end
  
  private
  
  def calculate_monthly_revenue
    # Calculate based on active subscriptions
    User.joins(:subscription_tier)
        .where(subscription_status: 'active')
        .sum('subscription_tiers.price_monthly')
  end
  
  def subscription_tier_breakdown
    User.joins(:subscription_tier)
        .group('subscription_tiers.name')
        .count
  end
end
