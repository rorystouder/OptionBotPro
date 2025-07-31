# TastyTrade Authentication Setup Guide

## Overview

TastyTrade uses **session-based authentication** with username/password credentials, NOT OAuth client ID/secret. This guide explains how to set up authentication for both sandbox and production environments.

## Authentication Flow

1. **Login** with username/password → Receive session token
2. **Use session token** in Authorization header for all API requests
3. **Token expires** after 24 hours (handled automatically by our app)

## Setting Up Sandbox Credentials

### Step 1: Create a Sandbox Account

1. Go to: https://developer.tastytrade.com/
2. Click "Get Started" or "Create Sandbox Account"
3. Register for a sandbox account (separate from your live account)
4. You'll receive:
   - Sandbox username (usually your email)
   - Sandbox password
   - Access to sandbox environment

### Step 2: Configure Environment Variables

1. Copy the sandbox environment template:
   ```bash
   cp .env.sandbox .env.local.sandbox
   ```

2. Edit `.env.local.sandbox` with your sandbox credentials:
   ```env
   # TastyTrade Sandbox API Configuration 
   TASTYTRADE_USERNAME=your.email@example.com
   TASTYTRADE_PASSWORD=your_sandbox_password
   TASTYTRADE_API_URL=https://api.cert.tastyworks.com
   TASTYTRADE_WEBSOCKET_URL=wss://streamer.cert.tastyworks.com
   ```

### Step 3: Test Authentication

Run the authentication test:

```bash
# Using Rails console
RAILS_ENV=sandbox rails console

# Test authentication
auth = Tastytrade::AuthService.new
result = auth.authenticate(
  username: ENV['TASTYTRADE_USERNAME'],
  password: ENV['TASTYTRADE_PASSWORD']
)
puts result
```

Or use the sandbox test script:
```bash
./bin/sandbox_test
```

## Setting Up Production Credentials

### ⚠️ IMPORTANT: Production Setup

1. **Never commit production credentials** to version control
2. Use environment variables or Rails credentials
3. Consider using a secrets management service

### Option 1: Environment Variables

Edit `.env.local` (git-ignored):
```env
TASTYTRADE_USERNAME=your.real.email@example.com
TASTYTRADE_PASSWORD=your_real_password
TASTYTRADE_API_URL=https://api.tastyworks.com
TASTYTRADE_WEBSOCKET_URL=wss://streamer.tastyworks.com
```

### Option 2: Rails Encrypted Credentials

```bash
# Edit credentials
rails credentials:edit

# Add:
tastytrade:
  username: your.email@example.com
  password: your_password
```

Then update the auth service to use:
```ruby
Rails.application.credentials.tastytrade[:username]
Rails.application.credentials.tastytrade[:password]
```

## How Our Authentication Works

### 1. Initial Login
When a user logs in through our app:

```ruby
# app/controllers/sessions_controller.rb
def create
  # Authenticate with TastyTrade
  auth_service = Tastytrade::AuthService.new
  auth_result = auth_service.authenticate(
    username: params[:tastytrade_username],
    password: params[:tastytrade_password]
  )
  
  # Store session token in Rails cache (24-hour expiry)
  # Token is automatically managed by AuthService
end
```

### 2. API Requests
All API requests automatically include the session token:

```ruby
# app/services/tastytrade/api_service.rb
def make_request(method, path, params = nil, body = nil)
  options = {
    headers: @auth_service.authenticated_headers(@user.email).merge({
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    })
  }
  # ... rest of request
end
```

### 3. Token Management
- Tokens are cached for 24 hours
- Expired tokens are detected automatically
- Users are prompted to re-authenticate when needed

## Troubleshooting

### Common Issues

**"Authentication failed" error**
- Verify username/password are correct
- Check you're using sandbox credentials for sandbox environment
- Ensure the API URL matches the environment

**"Token expired" error**
- Normal after 24 hours
- User needs to log in again
- App handles this automatically

**"No valid token found" error**
- User hasn't logged in yet
- Cache was cleared
- Need to authenticate first

### Testing Authentication

1. **Check current authentication status:**
   ```ruby
   user = User.find_by(email: 'your.email@example.com')
   user.tastytrade_authenticated?  # => true/false
   ```

2. **Validate token:**
   ```ruby
   auth = Tastytrade::AuthService.new
   auth.validate_token('your.email@example.com')  # => true/false
   ```

3. **Manual login test:**
   ```ruby
   auth = Tastytrade::AuthService.new
   result = auth.authenticate(
     username: 'your.email@example.com',
     password: 'your_password'
   )
   ```

## Security Best Practices

1. **Never hardcode credentials** in source code
2. **Use environment variables** for all sensitive data
3. **Rotate passwords regularly**
4. **Use separate accounts** for sandbox and production
5. **Monitor for suspicious activity** in your TastyTrade account
6. **Implement rate limiting** to avoid API abuse
7. **Log authentication events** for security auditing

## API Endpoints

The authentication endpoints we use:

- **Login:** `POST /sessions`
- **Validate:** `GET /sessions/validate`
- **Logout:** `DELETE /sessions`

All use the base URL:
- **Sandbox:** `https://api.cert.tastyworks.com`
- **Production:** `https://api.tastyworks.com`

## Getting Help

1. **TastyTrade Developer Support:** https://developer.tastytrade.com/
2. **API Documentation:** https://api.tastyworks.com/documentation
3. **Support Email:** api.support@tastytrade.com

Remember: TastyTrade does NOT use OAuth or API keys. It's a simple username/password session-based system.