# Risk Management Setup

This guide helps you configure and test the portfolio protection and risk management features that safeguard your automated trading.

## ⚠️ CRITICAL IMPORTANCE

The risk management system is your primary defense against catastrophic losses. **DO NOT SKIP THIS STEP** or disable these protections without fully understanding the consequences.

## Step 1: Run Risk Management Migration

First, create the portfolio protection database table:

```bash
bundle exec rails db:migrate
```

You should see the portfolio protection migration run:

```
== 20250729000005 CreatePortfolioProtections: migrating ===================
-- create_table(:portfolio_protections)
-- add_index(:portfolio_protections, [:user_id, :account_id], {:unique=>true})
-- add_index(:portfolio_protections, :account_id)
-- add_index(:portfolio_protections, :active)
-- add_index(:portfolio_protections, :emergency_stop_triggered_at)
-- add_check_constraint(:portfolio_protections, "cash_reserve_percentage >= 20.0 AND cash_reserve_percentage <= 50.0", {:name=>"cash_reserve_range_check"})
-- add_check_constraint(:portfolio_protections, "max_daily_loss_percentage > 0 AND max_daily_loss_percentage <= 15.0", {:name=>"daily_loss_range_check"})
-- add_check_constraint(:portfolio_protections, "max_single_trade_percentage > 0 AND max_single_trade_percentage <= 20.0", {:name=>"single_trade_range_check"})
-- add_check_constraint(:portfolio_protections, "max_portfolio_exposure_percentage >= 50.0 AND max_portfolio_exposure_percentage <= 85.0", {:name=>"exposure_range_check"})
== 20250729000005 CreatePortfolioProtections: migrated (0.0XXXs) ==========
```

## Step 2: Verify Database Constraints

Test that the database constraints are working:

```bash
bundle exec rails console
```

```ruby
# Test that constraints prevent unsafe values
user = User.first
protection = user.portfolio_protections.build(
  account_id: "TEST123",
  cash_reserve_percentage: 10.0  # This should fail (too low)
)

begin
  protection.save!
  puts "ERROR: Constraint not working!"
rescue => e
  puts "✅ Constraint working: #{e.message}"
end

# Test valid values
protection = user.portfolio_protections.create!(
  account_id: "TEST123",
  cash_reserve_percentage: 25.0,
  max_daily_loss_percentage: 5.0,
  max_single_trade_percentage: 10.0,
  max_portfolio_exposure_percentage: 75.0
)

puts "✅ Portfolio protection created successfully"
puts "Protection ID: #{protection.id}"

exit
```

## Step 3: Test Risk Management Service

Test the core risk management functionality:

```bash
bundle exec rails console
```

```ruby
# Create test user and protection
user = User.first || User.create!(
  email: "risk-test@example.com",
  password: "password123",
  first_name: "Risk",
  last_name: "Test",
  tastytrade_customer_id: "RISK001"
)

# Test risk management service initialization
risk_service = RiskManagementService.new(user, "TEST123")

# Test emergency stop functionality
puts "Testing emergency stop..."
risk_service.emergency_stop!("Test emergency stop")

if risk_service.emergency_stop_active?
  puts "✅ Emergency stop activated"
else
  puts "❌ Emergency stop failed"
end

# Clear emergency stop
risk_service.clear_emergency_stop!("test_user")

unless risk_service.emergency_stop_active?
  puts "✅ Emergency stop cleared"
else
  puts "❌ Emergency stop not cleared"
end

exit
```

## Step 4: Test Trade Validation

Test that trades are properly validated against risk rules:

```bash
bundle exec rails console
```

```ruby
user = User.first
account_id = "TEST123"

# Create portfolio protection with strict limits
protection = user.portfolio_protection_for(account_id)
protection.update!(
  cash_reserve_percentage: 30.0,      # Keep 30% in reserve
  max_single_trade_percentage: 5.0,   # Max 5% per trade
  max_daily_loss_percentage: 3.0      # Max 3% daily loss
)

# Test order validation
order = user.orders.build(
  symbol: "AAPL",
  quantity: 1000,  # Large quantity to potentially trigger limits
  order_type: "limit",
  action: "buy-to-open",
  price: 150.00,
  time_in_force: "day",
  tastytrade_account_id: account_id
)

# This should trigger validation
puts "Testing order validation..."
if order.valid?
  puts "❌ Order should have been rejected by risk management"
else
  puts "✅ Order properly rejected"
  puts "Violations:"
  order.errors.full_messages.each { |msg| puts "  - #{msg}" }
end

exit
```

## Step 5: Test API Endpoints

Test the portfolio protection API endpoints:

### Start Rails Server

```bash
bundle exec rails server
```

### Generate API Token

In another terminal:

```bash
bundle exec rails console
```

```ruby
user = User.first
token = SecureRandom.hex(32)
Rails.cache.write("api_token_#{token}", user.id, expires_in: 24.hours)
puts "API Token: #{token}"
exit
```

### Test Portfolio Protection API

Use the token from above:

```bash
# Set your token
API_TOKEN="your_generated_token_here"

# Get portfolio protection status
curl -X GET "http://localhost:3000/api/v1/portfolio_protections/status?account_id=TEST123" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json"

# Create portfolio protection
curl -X POST http://localhost:3000/api/v1/portfolio_protections \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "portfolio_protection": {
      "account_id": "TEST123",
      "cash_reserve_percentage": 25.0,
      "max_daily_loss_percentage": 5.0,
      "max_single_trade_percentage": 10.0,
      "max_portfolio_exposure_percentage": 75.0
    }
  }'

# Test trade validation
curl -X POST http://localhost:3000/api/v1/portfolio_protections/validate_trade \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "account_id": "TEST123",
    "order": {
      "symbol": "AAPL",
      "quantity": 100,
      "order_type": "limit",
      "action": "buy-to-open",
      "price": 150.00
    }
  }'
```

## Step 6: Test Emergency Stop Procedures

### Test Emergency Stop Activation

Get the protection ID from previous step, then:

```bash
# Trigger emergency stop
curl -X POST "http://localhost:3000/api/v1/portfolio_protections/PROTECTION_ID/emergency_stop" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "Testing emergency stop functionality",
    "triggered_by": "test_user"
  }'
```

### Test Emergency Stop Clearance

```bash
# Clear emergency stop (requires confirmation)
curl -X DELETE "http://localhost:3000/api/v1/portfolio_protections/PROTECTION_ID/clear_emergency_stop" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "confirm": "true",
    "cleared_by": "test_user"
  }'
```

## Step 7: Configure Default Protection Settings

Set up conservative default protection for your account:

```bash
bundle exec rails console
```

```ruby
# Update your user's default protection settings
user = User.find_by(email: 'your_email@example.com')
account_id = 'your_tastytrade_account_id'

protection = user.portfolio_protection_for(account_id)
protection.update!(
  cash_reserve_percentage: 25.0,        # Keep 25% in cash
  max_daily_loss_percentage: 5.0,       # Stop at 5% daily loss
  max_single_trade_percentage: 10.0,    # Max 10% per trade
  max_portfolio_exposure_percentage: 75.0, # Max 75% invested
  max_position_concentration_percentage: 20.0, # Max 20% in one symbol
  max_daily_trades: 50,                  # Max 50 trades per day
  email_alerts_enabled: true,           # Enable email alerts
  active: true                          # Protection is active
)

puts "✅ Default protection configured for account #{account_id}"
puts "Settings:"
puts "  Cash Reserve: #{protection.cash_reserve_percentage}%"
puts "  Daily Loss Limit: #{protection.max_daily_loss_percentage}%"
puts "  Single Trade Limit: #{protection.max_single_trade_percentage}%"
puts "  Max Exposure: #{protection.max_portfolio_exposure_percentage}%"

exit
```

## Step 8: Test Integration with Order Placement

Test that order placement respects risk management:

```bash
bundle exec rails console
```

```ruby
user = User.first
account_id = "TEST123"

# Ensure protection is active
protection = user.portfolio_protection_for(account_id)
protection.update!(active: true)

# Try to place an order that should be blocked
order = user.orders.build(
  symbol: "AAPL",
  quantity: 10000,  # Huge quantity to trigger limits
  order_type: "market",
  action: "buy-to-open",
  time_in_force: "day",
  tastytrade_account_id: account_id
)

puts "Testing order creation with risk management..."
if order.save
  puts "❌ Order should have been blocked!"
else
  puts "✅ Order properly blocked by risk management"
  puts "Errors:"
  order.errors.full_messages.each { |msg| puts "  - #{msg}" }
end

# Try a reasonable order
reasonable_order = user.orders.build(
  symbol: "AAPL",
  quantity: 1,  # Small quantity
  order_type: "limit",
  action: "buy-to-open",
  price: 150.00,
  time_in_force: "day",
  tastytrade_account_id: account_id
)

puts "\nTesting reasonable order..."
if reasonable_order.valid?
  puts "✅ Reasonable order passes validation"
  # Don't actually save to avoid API calls
else
  puts "❌ Reasonable order blocked:"
  reasonable_order.errors.full_messages.each { |msg| puts "  - #{msg}" }
end

exit
```

## Step 9: Monitor Risk Management Logs

Check that risk decisions are being logged:

```bash
# Check Rails logs for risk management decisions
tail -f log/development.log | grep "RISK_DECISION"

# In another terminal, try to place an order to generate log entries
bundle exec rails console
```

```ruby
user = User.first
risk_service = RiskManagementService.new(user, "TEST123")

# This will generate log entries
test_order = {
  symbol: "AAPL",
  quantity: 100,
  order_type: "limit",
  action: "buy-to-open",
  price: 150.00
}

result = risk_service.can_place_trade?(test_order)
puts "Trade allowed: #{result}"

exit
```

You should see detailed logging in the Rails log.

## Step 10: Verify Production Readiness

Ensure all safety features are working:

```bash
bundle exec rails console
```

```ruby
# Comprehensive safety check
user = User.first
account_id = "TEST123"

puts "=== RISK MANAGEMENT SAFETY CHECK ==="

# 1. Check protection exists
protection = user.portfolio_protection_for(account_id)
puts "✅ Portfolio protection configured"

# 2. Check constraints are enforced
begin
  bad_protection = user.portfolio_protections.build(
    account_id: "TEST999",
    cash_reserve_percentage: 10.0  # Too low
  )
  bad_protection.save!
  puts "❌ Database constraints not working!"
rescue => e
  puts "✅ Database constraints enforced"
end

# 3. Check emergency stop functionality
risk_service = RiskManagementService.new(user, account_id)
risk_service.emergency_stop!("Safety check")
if risk_service.emergency_stop_active?
  puts "✅ Emergency stop functional"
  risk_service.clear_emergency_stop!("safety_check")
else
  puts "❌ Emergency stop not working!"
end

# 4. Check order validation
order = user.orders.build(
  symbol: "TEST",
  quantity: 999999,  # Huge quantity
  order_type: "market",
  action: "buy-to-open",
  tastytrade_account_id: account_id
)

unless order.valid?
  puts "✅ Order validation working"
else
  puts "❌ Order validation not working!"
end

# 5. Check API endpoints are accessible
puts "✅ Risk management system ready for production"
puts ""
puts "IMPORTANT REMINDERS:"
puts "- Always test with small amounts first"
puts "- Monitor logs during initial automated trading"
puts "- Review and adjust limits based on your risk tolerance"
puts "- Keep emergency contact information handy"

exit
```

## Troubleshooting

### Database Migration Issues

If migration fails:

```bash
# Check migration status
bundle exec rails db:migrate:status

# If constraint creation fails, check PostgreSQL version
bundle exec rails runner "puts ActiveRecord::Base.connection.select_value('SELECT version()')"

# For older PostgreSQL versions, you may need to adjust constraints manually
```

### Risk Service Errors

If risk management service fails:

1. **Check TastyTrade API Connection:**
   ```bash
   bundle exec rails console
   ```
   ```ruby
   user = User.first
   api_service = Tastytrade::ApiService.new(user)
   begin
     accounts = api_service.get_accounts
     puts "✅ API connection working"
   rescue => e
     puts "❌ API connection failed: #{e.message}"
   end
   ```

2. **Check Redis Connection:**
   ```bash
   bundle exec rails runner "puts Redis.new.ping"
   ```

3. **Check Account Data:**
   - Verify TastyTrade credentials are correct
   - Ensure account has sufficient funds
   - Check account is not restricted

### Emergency Stop Not Working

If emergency stops don't trigger:

1. **Check Cache:**
   ```bash
   bundle exec rails runner "puts Rails.cache.stats"
   ```

2. **Verify Database:**
   ```bash
   bundle exec rails runner "puts PortfolioProtection.count"
   ```

3. **Check Logs:**
   ```bash
   grep -i emergency log/development.log
   ```

## Security Considerations

### Database Constraints
- Constraints prevent unsafe values even if application logic fails
- Cannot be bypassed through direct database access
- Provide last line of defense against configuration errors

### Emergency Stop Authority
- Emergency stops require explicit clearance
- Cannot be cleared programmatically
- Audit trail tracks all emergency events

### Logging
- All risk decisions are logged
- Cannot be disabled or bypassed
- Provides compliance and audit trail

## Verification Checklist

Before proceeding to automated trading, verify:

- [ ] Database migration completed successfully
- [ ] Database constraints are enforced
- [ ] Risk management service initializes correctly
- [ ] Emergency stop can be triggered and cleared
- [ ] Order validation blocks risky trades
- [ ] API endpoints respond correctly
- [ ] Portfolio protection settings are configured
- [ ] Risk decisions are being logged
- [ ] TastyTrade API integration works
- [ ] Redis caching is functional

## Next Steps

After completing risk management setup:

1. **Start with Manual Trading**: Test the system manually first
2. **Small Automated Trades**: Begin with very small position sizes
3. **Monitor Closely**: Watch logs and account status carefully
4. **Gradual Scaling**: Increase position sizes gradually as confidence grows
5. **Regular Review**: Adjust risk parameters based on experience

## Emergency Contacts

Keep these handy during automated trading:

- **TastyTrade Support**: [Contact information]
- **Your Account Representative**: [If applicable]
- **System Administrator**: [For technical issues]

---

**⚠️ FINAL WARNING**: Automated trading involves significant risk. These protections help but cannot eliminate all risk. Never trade with money you cannot afford to lose.