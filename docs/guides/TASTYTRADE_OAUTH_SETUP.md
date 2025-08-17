# TastyTrade OAuth Integration Guide

This guide covers the complete setup and troubleshooting of TastyTrade OAuth authentication for OptionBotPro.

## Overview

TastyTrade OAuth integration allows secure API access to trading accounts using the OAuth 2.0 authorization code flow. This replaces username/password authentication with secure token-based authentication.

## OAuth Flow Implementation

### 1. **Authorization Code Flow**

TastyTrade uses the standard OAuth 2.0 authorization code flow:

1. **Authorization Request**: User is redirected to TastyTrade's authorization server
2. **User Authentication**: User logs in with their TastyTrade credentials on TastyTrade's secure page
3. **Authorization Grant**: TastyTrade redirects back with an authorization code
4. **Token Exchange**: Authorization code is exchanged for access/refresh tokens
5. **API Access**: Access tokens are used to authenticate API requests

### 2. **Environment-Specific URLs**

**Production Environment:**
- OAuth Authorization: `https://my.tastytrade.com/auth.html`
- API Base URL: `https://api.tastyworks.com`
- Token Endpoint: `https://api.tastyworks.com/oauth/token`

**Sandbox Environment:**
- OAuth Authorization: `https://cert-my.staging-tasty.works/auth.html`
- API Base URL: `https://api.cert.tastyworks.com`
- Token Endpoint: `https://api.cert.tastyworks.com/oauth/token`

## Setup Requirements

### 1. **OAuth Client Registration**

Before using OAuth, you must register an OAuth client with TastyTrade:

1. **Create Developer Account**: Visit [developer.tastyworks.com](https://developer.tastyworks.com)
2. **Register OAuth Client**: Create a new OAuth application
3. **Configure Redirect URI**: Set to `http://your-domain.com/tastytrade/oauth/callback`
4. **Request Scopes**: Request permissions for `read`, `trade`, `openid`
5. **Get Credentials**: Obtain your Client ID and Client Secret

### 2. **Required Information**

- **Client ID**: Unique identifier for your OAuth application
- **Client Secret**: Secret key for your OAuth application (keep secure)
- **Redirect URI**: `http://localhost:3000/tastytrade/oauth/callback` (for development)
- **Scopes**: `read trade openid`

## Configuration Steps

### 1. **Access OAuth Setup**

Navigate to the OAuth configuration page:
```
http://localhost:3000/tastytrade/oauth/setup
```

### 2. **Enter OAuth Credentials**

- **Client ID**: Your registered OAuth client ID
- **Client Secret**: Your OAuth client secret
- **Environment**: Choose between Sandbox (testing) or Production

### 3. **Save and Authorize**

1. Click "Save OAuth Credentials"
2. You'll be redirected to TastyTrade's authorization page
3. Log in with your TastyTrade username and password
4. Authorize the application
5. You'll be redirected back with authentication tokens

## Technical Implementation

### 1. **Controller Structure**

```ruby
# app/controllers/tastytrade_controller.rb

def oauth_setup
  # Display OAuth configuration form
end

def oauth_save
  # Store OAuth credentials in session
  # Set environment-specific URLs
end

def oauth_authorize
  # Generate OAuth state for security
  # Redirect to TastyTrade authorization page
end

def oauth_callback
  # Handle authorization code
  # Exchange for access/refresh tokens
  # Store tokens in user record
end
```

### 2. **Token Management**

```ruby
# app/models/user.rb

def tastytrade_authenticated?
  # Check OAuth token first (preferred method)
  if tastytrade_oauth_token.present? && tastytrade_oauth_expires_at.present?
    return tastytrade_oauth_expires_at > Time.current
  end
  
  # Fallback to username/password authentication
  username = tastytrade_username
  return false if username.nil?
  Rails.cache.exist?("tastytrade_token_#{username}")
end
```

### 3. **API Authentication**

```ruby
# app/services/tastytrade/api_service.rb

def get_auth_headers
  # Try OAuth token first (preferred method)
  if @user.tastytrade_oauth_token.present? && @user.tastytrade_oauth_expires_at > Time.current
    return { "Authorization" => "Bearer #{@user.tastytrade_oauth_token}" }
  end
  
  # Fallback to session-based authentication
  @auth_service.authenticated_headers(@user.tastytrade_username)
end
```

## Common Issues and Solutions

### 1. **"404 Client not found" Error**

**Cause**: OAuth client is not registered with TastyTrade

**Solution**:
- Register OAuth client at [developer.tastyworks.com](https://developer.tastyworks.com)
- Ensure Client ID is correct
- Verify you're using the right environment (sandbox vs production)

### 2. **"Invalid redirect_uri" Error**

**Cause**: Redirect URI doesn't match registered URI

**Solution**:
- Ensure redirect URI matches exactly: `http://your-domain.com/tastytrade/oauth/callback`
- Check for trailing slashes or protocol mismatches
- Update registered URI in TastyTrade developer console

### 3. **"Invalid scope" Error**

**Cause**: Requested scopes not approved for your OAuth client

**Solution**:
- Request proper scopes: `read`, `trade`, `openid`
- Contact TastyTrade support to approve additional scopes

### 4. **Token Expiration**

**Cause**: Access tokens expire after 15 minutes

**Solution**:
- Implement token refresh logic using refresh tokens
- Store `tastytrade_oauth_expires_at` to check token validity
- Re-authenticate when tokens expire

## Testing

### 1. **Sandbox Testing**

1. Set environment to "Sandbox"
2. Use sandbox OAuth client credentials
3. Test with certification account credentials
4. Verify API calls work with sandbox endpoints

### 2. **Production Testing**

1. Set environment to "Production"
2. Use production OAuth client credentials
3. Test with real TastyTrade account
4. Verify live data access

## Security Considerations

### 1. **Client Secret Protection**

- Store Client Secret securely (environment variables)
- Never expose Client Secret in client-side code
- Rotate credentials periodically

### 2. **State Parameter**

- Always use OAuth state parameter for CSRF protection
- Generate random state value for each OAuth flow
- Validate state parameter in callback

### 3. **Token Storage**

- Store tokens securely in encrypted database fields
- Set appropriate token expiration times
- Implement secure token refresh logic

## Monitoring and Maintenance

### 1. **Token Health**

Monitor token usage and expiration:
```ruby
# Check token validity
user.tastytrade_authenticated?

# Check token expiration
user.tastytrade_oauth_expires_at
```

### 2. **Error Logging**

Log OAuth errors for debugging:
```ruby
Rails.logger.info "[OAUTH] Starting OAuth flow with client_id: #{client_id}"
Rails.logger.error "[OAUTH] Token exchange failed: #{response.body}"
```

### 3. **Rate Limiting**

- Respect TastyTrade API rate limits
- Implement exponential backoff for failed requests
- Monitor API usage quotas

## Files Modified

### Controllers
- `app/controllers/tastytrade_controller.rb` - OAuth flow implementation
- `app/controllers/application_controller.rb` - MFA bypass for OAuth actions

### Models
- `app/models/user.rb` - OAuth token validation
- Database schema - OAuth token fields

### Services
- `app/services/tastytrade/api_service.rb` - OAuth token usage
- `app/services/tastytrade/auth_service.rb` - OAuth header generation

### Views
- `app/views/tastytrade/oauth_setup.html.erb` - OAuth configuration form
- `app/views/dashboard/index.html.erb` - OAuth connection status

## Environment Variables

Set these environment variables for OAuth functionality:

```bash
# Optional: Default OAuth credentials
TASTYTRADE_CLIENT_ID=your_client_id
TASTYTRADE_CLIENT_SECRET=your_client_secret
TASTYTRADE_ENV=production  # or sandbox
TASTYTRADE_API_URL=https://api.tastyworks.com  # or https://api.cert.tastyworks.com
```

## Database Schema

OAuth token fields in `users` table:

```ruby
add_column :users, :tastytrade_oauth_token, :text
add_column :users, :tastytrade_oauth_refresh_token, :text
add_column :users, :tastytrade_oauth_expires_at, :datetime
```

## Next Steps

1. **Register OAuth Client**: Contact TastyTrade to register your OAuth application
2. **Test Sandbox**: Use certification environment for initial testing
3. **Production Deploy**: Switch to production environment with live credentials
4. **Monitor Usage**: Track OAuth token usage and API rate limits

## Support

For OAuth-related issues:

1. **TastyTrade Support**: Contact developer support for OAuth client registration
2. **Documentation**: Review TastyTrade's OAuth2 API guide
3. **Developer Portal**: Use [developer.tastyworks.com](https://developer.tastyworks.com) for client management

---

*Last Updated: August 2025*
*Status: OAuth implementation complete, requires client registration*