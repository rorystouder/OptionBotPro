# TastyTrade API Integration Guide

## Overview

This document provides comprehensive guidance for integrating with the TastyTrade API for options trading functionality.

## API Documentation Links

- Official API Docs: https://developer.tastyworks.com/
- API Sandbox: https://api.cert.tastyworks.com/

## Authentication

### OAuth 2.0 Flow

TastyTrade uses OAuth 2.0 for authentication:

```python
# Example authentication flow
import requests
from typing import Dict, Optional

class TastyTradeAuth:
    BASE_URL = "https://api.tastyworks.com"
    
    def __init__(self, client_id: str, client_secret: str):
        self.client_id = client_id
        self.client_secret = client_secret
        self.access_token: Optional[str] = None
        self.refresh_token: Optional[str] = None
    
    def authenticate(self, username: str, password: str) -> Dict:
        """Authenticate and obtain access token"""
        response = requests.post(
            f"{self.BASE_URL}/sessions",
            json={
                "login": username,
                "password": password
            }
        )
        
        if response.status_code == 201:
            data = response.json()
            self.access_token = data["data"]["session-token"]
            return data
        else:
            raise Exception(f"Authentication failed: {response.text}")
```

### Session Management

- Access tokens expire after 24 hours
- Implement automatic token refresh
- Store tokens securely (never in code)

## Core API Endpoints

### Account Management

#### Get Account Info
```python
GET /accounts/{account_id}
Headers: 
  Authorization: Bearer {access_token}

Response:
{
  "data": {
    "account-number": "ABC12345",
    "buying-power": 50000.00,
    "cash-balance": 25000.00,
    "day-trading-buying-power": 100000.00,
    "maintenance-requirement": 15000.00
  }
}
```

#### Get Positions
```python
GET /accounts/{account_id}/positions
Headers:
  Authorization: Bearer {access_token}

Response:
{
  "data": {
    "items": [
      {
        "symbol": "AAPL",
        "quantity": 100,
        "cost-basis": 15000.00,
        "market-value": 17500.00,
        "unrealized-pnl": 2500.00
      }
    ]
  }
}
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
```python
from pydantic import BaseModel, validator
from decimal import Decimal
from typing import Optional

class Order(BaseModel):
    symbol: str
    quantity: int
    action: str
    order_type: str
    price: Optional[Decimal] = None
    
    @validator('action')
    def validate_action(cls, v):
        valid_actions = ['buy-to-open', 'buy-to-close', 
                        'sell-to-open', 'sell-to-close']
        if v not in valid_actions:
            raise ValueError(f'Invalid action: {v}')
        return v
    
    @validator('quantity')
    def validate_quantity(cls, v):
        if v <= 0:
            raise ValueError('Quantity must be positive')
        return v
```

### 4. Caching Strategy
```python
from functools import lru_cache
import redis
import json

class MarketDataCache:
    def __init__(self):
        self.redis_client = redis.Redis(
            host='localhost',
            port=6379,
            decode_responses=True
        )
    
    def get_option_chain(self, symbol: str, expiration: str):
        key = f"option_chain:{symbol}:{expiration}"
        cached = self.redis_client.get(key)
        
        if cached:
            return json.loads(cached)
        
        # Fetch from API
        data = fetch_option_chain_from_api(symbol, expiration)
        
        # Cache for 5 minutes
        self.redis_client.setex(
            key, 
            300,  # 5 minutes
            json.dumps(data)
        )
        
        return data
```

## Testing

### Mock API Responses
```python
# tests/fixtures/api_responses.py
MOCK_ACCOUNT_RESPONSE = {
    "data": {
        "account-number": "TEST123",
        "buying-power": 100000.00,
        "cash-balance": 50000.00
    }
}

MOCK_POSITION_RESPONSE = {
    "data": {
        "items": [
            {
                "symbol": "AAPL",
                "quantity": 100,
                "cost-basis": 15000.00
            }
        ]
    }
}
```

### Integration Tests
```python
import pytest
from unittest.mock import patch, MagicMock

class TestTastyTradeIntegration:
    @patch('requests.post')
    def test_authentication(self, mock_post):
        mock_post.return_value.status_code = 201
        mock_post.return_value.json.return_value = {
            "data": {"session-token": "test_token"}
        }
        
        client = TastyTradeAuth("client_id", "secret")
        result = client.authenticate("user", "pass")
        
        assert client.access_token == "test_token"
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