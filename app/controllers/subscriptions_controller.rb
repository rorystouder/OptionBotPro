class SubscriptionsController < ApplicationController
  skip_before_action :authenticate_user, only: [ :index ]

  def index
    @tiers = SubscriptionTier.active.ordered
    @current_user_tier = current_user&.subscription_tier
  end

  def show
    @user = current_user
    @current_tier = @user.subscription_tier
    @subscription_status = @user.subscription_status
  end

  def create
    @tier = SubscriptionTier.find(params[:tier_id])

    # For now, just redirect to Stripe or show a placeholder
    # TODO: Implement Stripe checkout
    redirect_to subscription_path, notice: "Stripe integration coming soon for #{@tier.name} subscription!"
  end
end
