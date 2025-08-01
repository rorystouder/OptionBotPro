# Create Subscription Tiers for OptionBotPro

puts "Creating subscription tiers..."

# Basic Tier
basic = SubscriptionTier.find_or_create_by(slug: 'basic') do |tier|
  tier.name = 'Basic Trader'
  tier.price_monthly = 49.00
  tier.max_daily_trades = 5
  tier.max_trading_capital = 10000.00
  tier.max_accounts = 1
  tier.sort_order = 1
  tier.description = 'Perfect for new options traders getting started with automation'
  tier.features = [
    'Basic automated scanning',
    'Up to 5 trades per day',
    '25% cash protection (mandatory)',
    'Put credit spreads only',
    '$10,000 max trading capital',
    '1 TastyTrade account',
    'Email support',
    'Basic dashboard'
  ].join("\n")
end

# Pro Tier (Most Popular)
pro = SubscriptionTier.find_or_create_by(slug: 'pro') do |tier|
  tier.name = 'Pro Trader'
  tier.price_monthly = 149.00
  tier.max_daily_trades = 20
  tier.max_trading_capital = 100000.00
  tier.max_accounts = 2
  tier.sort_order = 2
  tier.description = 'Most popular plan for experienced traders with medium accounts'
  tier.features = [
    'Everything in Basic',
    'Advanced strategies (Iron Condors, Call Credit Spreads)',
    'Up to 20 trades per day',
    'Real-time alerts & notifications',
    'Portfolio analytics dashboard',
    'Custom scanning parameters',
    '$100,000 max trading capital',
    '2 TastyTrade accounts',
    'Priority email support'
  ].join("\n")
end

# Elite Tier
elite = SubscriptionTier.find_or_create_by(slug: 'elite') do |tier|
  tier.name = 'Elite Trader'
  tier.price_monthly = 299.00
  tier.max_daily_trades = nil # Unlimited
  tier.max_trading_capital = nil # Unlimited
  tier.max_accounts = 5
  tier.sort_order = 3
  tier.description = 'Professional-grade plan for serious traders with large accounts'
  tier.features = [
    'Everything in Pro',
    'Unlimited daily trades',
    'All option strategies',
    'Custom risk parameters',
    'Unlimited trading capital',
    'Up to 5 TastyTrade accounts',
    'API access for integrations',
    'Phone support',
    'Advanced analytics & reporting',
    'White-glove onboarding'
  ].join("\n")
end

puts "Created subscription tiers:"
puts "  #{basic.name} - $#{basic.price_monthly}/month"
puts "  #{pro.name} - $#{pro.price_monthly}/month"
puts "  #{elite.name} - $#{elite.price_monthly}/month"
puts "Done!"
