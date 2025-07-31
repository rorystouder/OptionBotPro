# TastyTrade API Setup

This guide helps you configure and test the TastyTrade API integration for the OptionBotPro application.

## Step 1: Obtain TastyTrade API Credentials

### Register for API Access

1. **Visit TastyTrade Developer Portal**: https://developer.tastyworks.com/
2. **Create Developer Account**: Sign up for API access
3. **Create Application**: Register your trading application
4. **Get API Keys**: Note down your Client ID and Client Secret

### Alternative: Use Certification Environment

For testing, you can use the certification environment:

- **API URL**: `https://api.cert.tastyworks.com`
- **Credentials**: Use your regular TastyTrade account credentials
- **Benefits**: Safe testing environment with paper trading

## Step 2: Update Environment Variables

Edit your `.env` file with real TastyTrade credentials:

```bash
nano .env
```

Update these values:

```env
# TastyTrade API Configuration
TASTYTRADE_CLIENT_ID=your_actual_client_id
TASTYTRADE_CLIENT_SECRET=your_actual_client_secret
TASTYTRADE_API_URL=https://api.tastyworks.com
TASTYTRADE_WEBSOCKET_URL=wss://streamer.tastyworks.com

# For testing/certification environment:
# TASTYTRADE_API_URL=https://api.cert.tastyworks.com
# TASTYTRADE_WEBSOCKET_URL=wss://streamer.cert.tastyworks.com
```

## Step 3: Test API Authentication

Test that you can authenticate with the TastyTrade API:

```bash
bundle exec rails console
```

In the Rails console:

```ruby
# Test authentication service
auth_service = Tastytrade::AuthService.new

# Try to authenticate (use your actual TastyTrade credentials)
begin
  result = auth_service.authenticate(
    username: 'your_tastytrade_username',
    password: 'your_tastytrade_password'
  )
  
  puts "Authentication successful!"
  puts "Token: #{result.dig('data', 'session-token')}"
rescue => e
  puts "Authentication failed: #{e.message}"
end

exit
```

**Important**: Replace `your_tastytrade_username` and `your_tastytrade_password` with your actual TastyTrade login credentials.

## Step 4: Test API Service

Create a test user and test the API service:

```bash
bundle exec rails console
```

```ruby
# Create a test user
user = User.create!(
  email: 'trader@example.com',
  password: 'password123',
  first_name: 'Test',
  last_name: 'Trader',
  tastytrade_customer_id: 'your_customer_id'
)

# Authenticate with TastyTrade first
auth_service = Tastytrade::AuthService.new
auth_service.authenticate(
  username: 'your_tastytrade_username',
  password: 'your_tastytrade_password'
)

# Test API service
api_service = Tastytrade::ApiService.new(user)

# Test getting accounts
begin
  accounts = api_service.get_accounts
  puts "Accounts fetched successfully!"
  puts accounts.inspect
rescue => e
  puts "Failed to fetch accounts: #{e.message}"
end

exit
```

## Step 5: Test Market Data

Test fetching market data:

```bash
bundle exec rails console
```

```ruby
# Assuming you have authenticated as in previous steps
api_service = Tastytrade::ApiService.new(User.first)

# Test getting quotes
begin
  quotes = api_service.get_quote('AAPL')
  puts "Quote for AAPL:"
  puts quotes.inspect
rescue => e
  puts "Failed to fetch quotes: #{e.message}"
end

# Test getting option chain
begin
  option_chain = api_service.get_option_chain('AAPL')
  puts "Option chain for AAPL:"
  puts option_chain.dig('data', 'items').count
rescue => e
  puts "Failed to fetch option chain: #{e.message}"
end

exit
```

## Step 6: Test API Endpoints

Start the Rails server:

```bash
bundle exec rails server
```

### Test Authentication Endpoint

In another terminal, test the API endpoints:

```bash
# Create a user account
curl -X POST http://localhost:3000/signup \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "api-test@example.com",
      "password": "password123",
      "first_name": "API",
      "last_name": "Test",
      "tastytrade_customer_id": "TEST123"
    }
  }'

# Login to get session
curl -X POST http://localhost:3000/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "api-test@example.com",
    "password": "password123",
    "tastytrade_username": "your_tastytrade_username",
    "tastytrade_password": "your_tastytrade_password"
  }' \
  -c cookies.txt

# Test API endpoints (this requires proper API token setup)
curl -X GET http://localhost:3000/api/v1/accounts \
  -H "Authorization: Bearer your_api_token" \
  -H "Content-Type: application/json"
```

## Step 7: Configure API Token System

For API access, you need to implement token generation. Add this to your Rails console:

```ruby
# Generate API token for a user
user = User.find_by(email: 'api-test@example.com')
token = SecureRandom.hex(32)
Rails.cache.write("api_token_#{token}", user.id, expires_in: 24.hours)

puts "API Token for #{user.email}: #{token}"
puts "Use this token in Authorization header: Bearer #{token}"
```

## Step 8: Production Configuration

For production deployment, consider these additional configurations:

### Secure Credential Storage

Use Rails encrypted credentials:

```bash
bundle exec rails credentials:edit
```

Add your TastyTrade credentials:

```yaml
tastytrade:
  client_id: your_production_client_id
  client_secret: your_production_client_secret
  api_url: https://api.tastyworks.com
  websocket_url: wss://streamer.tastyworks.com
```

### Update Services to Use Credentials

Modify the auth service to use encrypted credentials in production:

```ruby
# In app/services/tastytrade/auth_service.rb
def initialize
  if Rails.env.production?
    @client_id = Rails.application.credentials.tastytrade[:client_id]
    @client_secret = Rails.application.credentials.tastytrade[:client_secret]
  else
    @client_id = ENV['TASTYTRADE_CLIENT_ID']
    @client_secret = ENV['TASTYTRADE_CLIENT_SECRET']
  end
end
```

## Troubleshooting

### Authentication Failures

1. **Invalid Credentials Error:**
   - Verify your TastyTrade username/password
   - Check if your account is active
   - Try logging into TastyTrade web interface first

2. **API Key Issues:**
   - Verify Client ID and Client Secret are correct
   - Check if API access is enabled for your account
   - Contact TastyTrade support if needed

3. **SSL/Certificate Errors:**
   ```bash
   # Update certificates
   sudo apt-get update && sudo apt-get install ca-certificates
   ```

### Network/Connection Issues

1. **Timeout Errors:**
   - Check your internet connection
   - Verify firewall settings
   - Try ping to api.tastyworks.com

2. **Rate Limiting:**
   - The API has rate limits (120 req/min)
   - Implement proper caching
   - Add delays between requests if testing

### API Response Errors

1. **422 Validation Errors:**
   - Check request format matches API documentation
   - Verify all required fields are provided
   - Check data types (strings vs numbers)

2. **401 Unauthorized:**
   - Token may have expired (24 hour limit)
   - Re-authenticate to get new token
   - Check token is being sent in correct header format

## Verification

Before proceeding to the next step, verify:

- [ ] TastyTrade API credentials are configured
- [ ] Authentication service works with real credentials
- [ ] Can fetch account information
- [ ] Can fetch market data (quotes, option chains)
- [ ] API token system is working
- [ ] Rails server starts without errors
- [ ] Basic API endpoints respond correctly

## Next Step

Continue to [Testing Setup](./06-testing-setup.md)