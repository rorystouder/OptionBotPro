# Testing Setup

This guide helps you verify that all components of the OptionBotPro application are working correctly.

## Step 1: Basic Rails Application Test

Start by testing that Rails is working:

```bash
# Check Rails version
bundle exec rails -v

# Check database connection
bundle exec rails runner "puts ActiveRecord::Base.connection.adapter_name"

# Check environment loading
bundle exec rails runner "puts Rails.env"
```

## Step 2: Start the Rails Server

Start the development server:

```bash
bundle exec rails server
```

The server should start and show:
```
=> Booting Puma
=> Rails 8.0.2 application starting in development 
=> Run `bin/rails server --help` for more startup options
Puma starting in single mode...
* Puma version: 6.6.0 ("Return to Forever")
* Ruby version: ruby 3.2.3 (2024-01-18 revision 52bb2ac0a6) [x86_64-linux-gnu]
*  Min threads: 3
*  Max threads: 3
*  Environment: development
*          PID: 12345
* Listening on http://127.0.0.1:3000
* Listening on http://[::1]:3000
Use Ctrl-C to stop
```

## Step 3: Test Web Interface

### Test Root Path

Visit in your browser or use curl:

```bash
curl -I http://localhost:3000/
```

You should get a redirect to login page (302 status).

### Test Health Check

```bash
curl http://localhost:3000/up
```

Should return "Rails is up and running" with 200 status.

## Step 4: Test User Registration

### Via Web Interface

1. Visit: http://localhost:3000/signup
2. Fill in the form with:
   - Email: test@example.com
   - Password: password123
   - First Name: Test
   - Last Name: User
   - TastyTrade Customer ID: TEST123

### Via API

```bash
curl -X POST http://localhost:3000/signup \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "test@example.com",
      "password": "password123",
      "first_name": "Test",
      "last_name": "User",
      "tastytrade_customer_id": "TEST123"
    }
  }' \
  -v
```

## Step 5: Test Authentication

### Login via Web

1. Visit: http://localhost:3000/login
2. Use the credentials from Step 4
3. Add your TastyTrade credentials to test API integration

### Login via API

```bash
curl -X POST http://localhost:3000/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }' \
  -c cookies.txt \
  -v
```

## Step 6: Test Database Operations

Open Rails console and test database operations:

```bash
bundle exec rails console
```

```ruby
# Test user creation and validation
user = User.new(email: "db-test@example.com")
user.valid?
puts user.errors.full_messages

# Create a valid user
user = User.create!(
  email: "db-test@example.com",
  password: "password123",
  first_name: "DB",
  last_name: "Test",
  tastytrade_customer_id: "DB001",
  active: true
)

# Test relationships
order = user.orders.create!(
  symbol: "AAPL",
  quantity: 100,
  order_type: "limit",
  action: "buy-to-open",
  price: 150.00,
  time_in_force: "day"
)

position = user.positions.create!(
  symbol: "AAPL",
  quantity: 100,
  average_price: 150.00,
  tastytrade_account_id: "ACC123"
)

# Test queries
puts "User count: #{User.count}"
puts "Order count: #{Order.count}"
puts "Position count: #{Position.count}"

# Test associations
puts "User orders: #{user.orders.count}"
puts "User positions: #{user.positions.count}"

exit
```

## Step 7: Test TastyTrade API Integration

**Note**: This requires valid TastyTrade credentials from Step 5.

```bash
bundle exec rails console
```

```ruby
# Test authentication
auth_service = Tastytrade::AuthService.new

begin
  result = auth_service.authenticate(
    username: 'your_tastytrade_username',
    password: 'your_tastytrade_password'
  )
  puts "✅ TastyTrade authentication successful"
  puts "Token expires: #{24.hours.from_now}"
rescue => e
  puts "❌ TastyTrade authentication failed: #{e.message}"
end

# Test API service with a user
user = User.first
api_service = Tastytrade::ApiService.new(user)

begin
  accounts = api_service.get_accounts
  puts "✅ Account data fetched successfully"
  puts "Account count: #{accounts.dig('data', 'items')&.count || 0}"
rescue => e
  puts "❌ Failed to fetch accounts: #{e.message}"
end

exit
```

## Step 8: Test API Endpoints

### Generate API Token

```bash
bundle exec rails console
```

```ruby
# Create API token for testing
user = User.first
token = SecureRandom.hex(32)
Rails.cache.write("api_token_#{token}", user.id, expires_in: 24.hours)
puts "API Token: #{token}"
exit
```

### Test API Endpoints

Use the token from above:

```bash
# Set your token
API_TOKEN="your_generated_token_here"

# Test accounts endpoint
curl -X GET http://localhost:3000/api/v1/accounts \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json"

# Test positions endpoint  
curl -X GET http://localhost:3000/api/v1/positions \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json"

# Test orders endpoint
curl -X GET http://localhost:3000/api/v1/orders \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json"

# Test market data endpoint
curl -X GET "http://localhost:3000/api/v1/options/quotes?symbols=AAPL" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json"
```

## Step 9: Test Order Placement (Optional)

**Warning**: This will place a real order if using production API. Only test with certification environment or paper trading account.

```bash
curl -X POST http://localhost:3000/api/v1/orders \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "order": {
      "symbol": "AAPL",
      "quantity": 1,
      "order_type": "limit",
      "action": "buy-to-open",
      "price": 150.00,
      "time_in_force": "day",
      "account_id": "your_account_id"
    }
  }'
```

## Step 10: Test Background Jobs (Sidekiq)

### Start Sidekiq

In a new terminal:

```bash
bundle exec sidekiq
```

### Test Job Processing

```bash
bundle exec rails console
```

```ruby
# Test a simple job
class TestJob < ApplicationJob
  def perform(message)
    Rails.logger.info "Test job executed: #{message}"
  end
end

# Queue a job
TestJob.perform_later("Hello from Sidekiq!")

# Check job was processed in Sidekiq terminal
exit
```

## Step 11: Test Caching (Redis)

```bash
bundle exec rails console
```

```ruby
# Test Redis connection
begin
  Redis.new.ping
  puts "✅ Redis connection successful"
rescue => e
  puts "❌ Redis connection failed: #{e.message}"
end

# Test Rails cache (uses Redis)
Rails.cache.write("test_key", "test_value", expires_in: 1.minute)
cached_value = Rails.cache.read("test_key")
puts cached_value == "test_value" ? "✅ Cache working" : "❌ Cache failed"

exit
```

## Step 12: Test Error Handling

Test that errors are handled gracefully:

```bash
# Test invalid API token
curl -X GET http://localhost:3000/api/v1/accounts \
  -H "Authorization: Bearer invalid_token" \
  -H "Content-Type: application/json"

# Should return 401 Unauthorized with error message

# Test invalid order data
curl -X POST http://localhost:3000/api/v1/orders \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "order": {
      "symbol": "",
      "quantity": -1,
      "order_type": "invalid"
    }
  }'

# Should return 422 with validation errors
```

## Step 13: Performance Testing

### Test Response Times

```bash
# Test API response times
time curl -X GET http://localhost:3000/api/v1/accounts \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  -s > /dev/null

# Test database queries
bundle exec rails runner "
  start_time = Time.now
  User.includes(:orders, :positions).limit(10).to_a
  puts 'Query time: #{Time.now - start_time}s'
"
```

### Test Concurrent Requests

```bash
# Install ab (Apache Bench) if needed
sudo apt-get install apache2-utils

# Test concurrent requests
ab -n 100 -c 10 -H "Authorization: Bearer $API_TOKEN" \
  http://localhost:3000/api/v1/accounts
```

## Troubleshooting

### Server Won't Start

1. **Check logs:**
   ```bash
   tail -f log/development.log
   ```

2. **Check for port conflicts:**
   ```bash
   lsof -i :3000
   ```

3. **Check database connection:**
   ```bash
   bundle exec rails db:version
   ```

### API Tests Fail

1. **Check authentication:**
   - Verify TastyTrade credentials
   - Check token generation
   - Verify headers format

2. **Check network:**
   ```bash
   ping api.tastyworks.com
   ```

3. **Check Rails logs:**
   ```bash
   tail -f log/development.log
   ```

### Database Errors

1. **Check PostgreSQL status:**
   ```bash
   sudo systemctl status postgresql
   ```

2. **Check database exists:**
   ```bash
   bundle exec rails runner "puts ActiveRecord::Base.connection.current_database"
   ```

3. **Check migrations:**
   ```bash
   bundle exec rails db:migrate:status
   ```

## Test Results Checklist

Before moving to production, verify all tests pass:

- [ ] Rails server starts without errors
- [ ] Database operations work correctly
- [ ] User registration/authentication works
- [ ] TastyTrade API authentication succeeds
- [ ] API endpoints return expected responses
- [ ] Error handling works correctly
- [ ] Caching (Redis) is functional
- [ ] Background jobs (Sidekiq) process correctly
- [ ] Performance is acceptable
- [ ] Concurrent requests are handled properly

## Next Step

Continue to [Views Setup](./07-views-setup.md) (optional) or start using your API!