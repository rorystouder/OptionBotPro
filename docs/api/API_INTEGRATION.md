# TastyTrade API Integration Guide

## Overview

This document provides comprehensive guidance for integrating with the TastyTrade API for options trading functionality using Ruby on Rails.

## API Documentation Links

- Official API Docs: https://developer.tastyworks.com/
- API Sandbox: https://api.cert.tastyworks.com/

## Authentication

### OAuth 2.0 Flow

TastyTrade uses OAuth 2.0 for authentication. Here's the Ruby implementation:

```ruby
# app/services/tastytrade_auth_service.rb
class TastytradeAuthService
  include HTTParty
  base_uri 'https://api.tastyworks.com'
  
  def initialize(client_id:, client_secret:)
    @client_id = client_id
    @client_secret = client_secret
    @access_token = nil
    @refresh_token = nil
  end
  
  def authenticate(username:, password:)
    response = self.class.post('/sessions', {
      body: {
        login: username,
        password: password
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    })
    
    if response.code == 201
      data = response.parsed_response
      @access_token = data.dig('data', 'session-token')
      Rails.cache.write("tastytrade_token", @access_token, expires_in: 24.hours)
      data
    else
      raise StandardError, "Authentication failed: #{response.body}"
    end
  end
  
  def authenticated_headers
    token = @access_token || Rails.cache.read("tastytrade_token")
    { 'Authorization' => "Bearer #{token}" }
  end
  
  private
  
  attr_reader :client_id, :client_secret, :access_token, :refresh_token
end
```

### Session Management

- Access tokens expire after 24 hours
- Use Rails.cache for token storage with TTL
- Store credentials with Rails encrypted credentials
- Implement automatic token refresh in service

## Core API Endpoints

### Account Management

#### Get Account Info
```ruby
# app/services/tastytrade_api_service.rb
class TastytradeApiService
  include HTTParty
  base_uri 'https://api.tastyworks.com'
  
  def initialize
    @auth_service = TastytradeAuthService.new(
      client_id: Rails.application.credentials.tastytrade[:client_id],
      client_secret: Rails.application.credentials.tastytrade[:client_secret]
    )
  end
  
  def get_account(account_id)
    response = self.class.get(
      "/accounts/#{account_id}",
      headers: @auth_service.authenticated_headers
    )
    
    handle_response(response)
  end
  
  private
  
  def handle_response(response)
    case response.code
    when 200..299
      response.parsed_response
    when 401
      # Token expired, re-authenticate
      raise TokenExpiredError
    else
      raise APIError, "Request failed: #{response.body}"
    end
  end
end

# Usage in controller:
# GET /accounts/{account_id}
# Headers: Authorization: Bearer {access_token}
# 
# Response:
# {
#   "data": {
#     "account-number": "ABC12345",
#     "buying-power": 50000.00,
#     "cash-balance": 25000.00,
#     "day-trading-buying-power": 100000.00,
#     "maintenance-requirement": 15000.00
#   }
# }
```

#### Get Positions
```ruby
def get_positions(account_id)
  response = self.class.get(
    "/accounts/#{account_id}/positions",
    headers: @auth_service.authenticated_headers
  )
  
  handle_response(response)
end

# Expected response format:
# {
#   "data": {
#     "items": [
#       {
#         "symbol": "AAPL",
#         "quantity": 100,
#         "cost-basis": 15000.00,
#         "market-value": 17500.00,
#         "unrealized-pnl": 2500.00
#       }
#     ]
#   }
# }
```

### Market Data

#### Get Option Chain
```python
GET /option-chains/{symbol}/nested
Query Parameters:
  expiration-date: 2024-01-19

Response:
{
  "data": {
    "items": [
      {
        "expiration-date": "2024-01-19",
        "strikes": [
          {
            "strike-price": 150.00,
            "call": {
              "symbol": "AAPL240119C00150000",
              "bid": 5.25,
              "ask": 5.30,
              "last": 5.27,
              "volume": 1234,
              "open-interest": 5678,
              "implied-volatility": 0.25,
              "delta": 0.55,
              "gamma": 0.02,
              "theta": -0.05,
              "vega": 0.15
            },
            "put": {
              "symbol": "AAPL240119P00150000",
              "bid": 4.75,
              "ask": 4.80,
              "last": 4.77,
              "volume": 987,
              "open-interest": 4321,
              "implied-volatility": 0.24,
              "delta": -0.45,
              "gamma": 0.02,
              "theta": -0.04,
              "vega": 0.14
            }
          }
        ]
      }
    ]
  }
}
```

#### Stream Market Data (WebSocket)
```python
# WebSocket endpoint: wss://streamer.tastyworks.com

# Connection message
{
  "action": "connect",
  "token": "{access_token}"
}

# Subscribe to quotes
{
  "action": "subscribe",
  "symbols": ["AAPL", "AAPL240119C00150000"],
  "channels": ["quote", "greeks"]
}

# Data format
{
  "type": "quote",
  "symbol": "AAPL",
  "data": {
    "bid": 175.25,
    "ask": 175.30,
    "last": 175.27,
    "volume": 50000000,
    "timestamp": "2024-01-10T15:30:00Z"
  }
}
```

### Order Management

#### Place Order
```python
POST /accounts/{account_id}/orders
Headers:
  Authorization: Bearer {access_token}
  Content-Type: application/json

Request Body:
{
  "type": "limit",
  "symbol": "AAPL240119C00150000",
  "quantity": 10,
  "action": "buy-to-open",
  "price": 5.25,
  "time-in-force": "day"
}

Response:
{
  "data": {
    "order-id": "ORD123456",
    "status": "pending",
    "created-at": "2024-01-10T15:30:00Z"
  }
}
```

#### Order Types

1. **Single Leg Orders**
   - Market Order
   - Limit Order
   - Stop Order
   - Stop Limit Order

2. **Multi-Leg Orders**
   - Vertical Spreads
   - Iron Condors
   - Butterflies
   - Custom Combinations

#### Order Actions
- `buy-to-open` - Open long position
- `buy-to-close` - Close short position
- `sell-to-open` - Open short position
- `sell-to-close` - Close long position

#### Time in Force Options
- `day` - Day order
- `gtc` - Good till canceled
- `ioc` - Immediate or cancel
- `fok` - Fill or kill

### Error Handling

#### Common Error Responses
```json
{
  "error": {
    "code": "invalid_order",
    "message": "Insufficient buying power",
    "details": {
      "required": 5250.00,
      "available": 5000.00
    }
  }
}
```

#### Error Codes
- `401` - Unauthorized (invalid/expired token)
- `403` - Forbidden (insufficient permissions)
- `404` - Resource not found
- `422` - Validation error
- `429` - Rate limit exceeded
- `500` - Internal server error

## Rate Limiting

### Limits
- REST API: 120 requests per minute
- WebSocket: 100 subscriptions per connection
- Order placement: 60 orders per minute

### Best Practices
```python
import time
from functools import wraps

def rate_limit(calls_per_minute: int):
    """Decorator for rate limiting API calls"""
    min_interval = 60.0 / calls_per_minute
    last_called = [0.0]
    
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            elapsed = time.time() - last_called[0]
            left_to_wait = min_interval - elapsed
            if left_to_wait > 0:
                time.sleep(left_to_wait)
            last_called[0] = time.time()
            return func(*args, **kwargs)
        return wrapper
    return decorator

# Usage
@rate_limit(120)
def get_account_info(account_id: str):
    # API call implementation
    pass
```

## Integration Best Practices

### 1. Connection Management
```python
class TastyTradeAPIClient:
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            'Accept': 'application/json',
            'Content-Type': 'application/json'
        })
    
    def __enter__(self):
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        self.session.close()
```

### 2. Error Recovery
```python
import backoff

@backoff.on_exception(
    backoff.expo,
    requests.exceptions.RequestException,
    max_tries=3,
    max_time=60
)
def make_api_request(url: str, **kwargs):
    """Make API request with exponential backoff"""
    response = requests.get(url, **kwargs)
    response.raise_for_status()
    return response.json()
```

### 3. Data Validation
```ruby
# app/models/order.rb
class Order < ApplicationRecord
  VALID_ACTIONS = %w[buy-to-open buy-to-close sell-to-open sell-to-close].freeze
  
  validates :symbol, presence: true, format: { with: /\A[A-Z]+\z/ }
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :action, presence: true, inclusion: { in: VALID_ACTIONS }
  validates :order_type, presence: true
  validates :price, numericality: { greater_than: 0 }, allow_nil: true
  
  before_validation :upcase_symbol
  
  private
  
  def upcase_symbol
    self.symbol = symbol.upcase if symbol.present?
  end
end

# Alternative using ActiveModel for service objects
class OrderValidator
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations
  
  attribute :symbol, :string
  attribute :quantity, :integer
  attribute :action, :string
  attribute :order_type, :string
  attribute :price, :decimal
  
  validates :symbol, presence: true, format: { with: /\A[A-Z]+\z/ }
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :action, presence: true, inclusion: { in: Order::VALID_ACTIONS }
  validates :order_type, presence: true
  validates :price, numericality: { greater_than: 0 }, allow_nil: true
end
```

### 4. Caching Strategy
```ruby
# app/services/market_data_cache_service.rb
class MarketDataCacheService
  def initialize
    @redis = Redis.new(url: ENV['REDIS_URL'])
  end
  
  def get_option_chain(symbol, expiration)
    cache_key = "option_chain:#{symbol}:#{expiration}"
    
    # Try Rails cache first (with automatic JSON handling)
    Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      fetch_option_chain_from_api(symbol, expiration)
    end
  end
  
  # Alternative direct Redis usage
  def get_option_chain_redis(symbol, expiration)
    cache_key = "option_chain:#{symbol}:#{expiration}"
    cached_data = @redis.get(cache_key)
    
    if cached_data
      JSON.parse(cached_data)
    else
      data = fetch_option_chain_from_api(symbol, expiration)
      @redis.setex(cache_key, 300, data.to_json) # 5 minutes
      data
    end
  end
  
  private
  
  def fetch_option_chain_from_api(symbol, expiration)
    api_service = TastytradeApiService.new
    api_service.get_option_chain(symbol, expiration)
  end
end

# Usage in Rails controller:
class Api::V1::OptionsController < ApplicationController
  def show
    @option_chain = MarketDataCacheService.new.get_option_chain(
      params[:symbol], 
      params[:expiration]
    )
    render json: @option_chain
  end
end
```

## Testing

### Mock API Responses
```ruby
# spec/fixtures/tastytrade_responses.rb
module TastytradeResponses
  MOCK_ACCOUNT_RESPONSE = {
    "data" => {
      "account-number" => "TEST123",
      "buying-power" => 100000.00,
      "cash-balance" => 50000.00
    }
  }.freeze

  MOCK_POSITION_RESPONSE = {
    "data" => {
      "items" => [
        {
          "symbol" => "AAPL",
          "quantity" => 100,
          "cost-basis" => 15000.00
        }
      ]
    }
  }.freeze
end
```

### RSpec Integration Tests
```ruby
# spec/services/tastytrade_auth_service_spec.rb
require 'rails_helper'

RSpec.describe TastytradeAuthService do
  let(:service) do
    described_class.new(
      client_id: 'test_client_id',
      client_secret: 'test_secret'
    )
  end
  
  describe '#authenticate' do
    before do
      stub_request(:post, "https://api.tastyworks.com/sessions")
        .with(
          body: { login: 'test_user', password: 'test_pass' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        .to_return(
          status: 201,
          body: { data: { 'session-token' => 'test_token' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end
    
    it 'returns authentication data on success' do
      result = service.authenticate(username: 'test_user', password: 'test_pass')
      
      expect(result.dig('data', 'session-token')).to eq('test_token')
      expect(Rails.cache.read('tastytrade_token')).to eq('test_token')
    end
  end
end

# spec/services/tastytrade_api_service_spec.rb  
RSpec.describe TastytradeApiService do
  let(:service) { described_class.new }
  
  before do
    allow(Rails.cache).to receive(:read).with('tastytrade_token').and_return('valid_token')
  end
  
  describe '#get_account' do
    before do
      stub_request(:get, "https://api.tastyworks.com/accounts/TEST123")
        .with(headers: { 'Authorization' => 'Bearer valid_token' })
        .to_return(
          status: 200,
          body: TastytradeResponses::MOCK_ACCOUNT_RESPONSE.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end
    
    it 'returns account information' do
      result = service.get_account('TEST123')
      
      expect(result.dig('data', 'account-number')).to eq('TEST123')
      expect(result.dig('data', 'buying-power')).to eq(100000.00)
    end
  end
end
```

## Troubleshooting

### Common Issues

1. **Authentication Failures**
   - Verify API credentials
   - Check token expiration
   - Ensure correct environment (prod vs sandbox)

2. **WebSocket Disconnections**
   - Implement reconnection logic
   - Monitor heartbeat messages
   - Handle network interruptions

3. **Order Rejections**
   - Validate buying power
   - Check market hours
   - Verify symbol format

### Debug Logging
```python
import logging

logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

# Log all API requests/responses
logging.getLogger('requests').setLevel(logging.DEBUG)
```

## Security Considerations

1. **API Credentials**
   - Never hardcode credentials
   - Use environment variables
   - Rotate keys regularly

2. **Data Encryption**
   - Use HTTPS for all communications
   - Encrypt stored credentials
   - Implement secure session management

3. **Access Control**
   - Implement user-level permissions
   - Audit all trading activities
   - Monitor for unusual patterns