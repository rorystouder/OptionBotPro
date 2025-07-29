# System Architecture

## Overview

The TastyTrades Option Trader UI is designed as a modular, scalable Ruby on Rails application that provides real-time option trading capabilities through the TastyTrade API. It leverages Rails' built-in features including Action Cable for WebSockets, Active Job with Sidekiq for background processing, and Active Record for data persistence.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        Frontend (Web UI)                     │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │  Hotwire/   │  │ Action Cable │  │   Stimulus.js   │  │
│  │   Turbo     │  │   Client     │  │   Controllers   │  │
│  └─────────────┘  └──────────────┘  └──────────────────┘  │
└─────────────────────────────┬───────────────────────────────┘
                              │ HTTP/WebSocket
┌─────────────────────────────┴───────────────────────────────┐
│                   Backend (Ruby on Rails)                    │
│  ┌─────────────────────────────────────────────────────┐   │
│  │               Rails Application Layer                 │   │
│  │  ┌────────────┐  ┌──────────────┐  ┌────────────┐  │   │
│  │  │   Rails    │  │ Action Cable │  │   Devise   │  │   │
│  │  │Controllers │  │   Channels   │  │    Auth    │  │   │
│  │  └────────────┘  └──────────────┘  └────────────┘  │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │           Services & Background Jobs Layer           │   │
│  │  ┌────────────┐  ┌──────────────┐  ┌────────────┐  │   │
│  │  │  Trading   │  │   Strategy   │  │    Risk    │  │   │
│  │  │  Service   │  │   Service    │  │  Service   │  │   │
│  │  └────────────┘  └──────────────┘  └────────────┘  │   │
│  │  ┌────────────┐  ┌──────────────┐  ┌────────────┐  │   │
│  │  │  Scanner   │  │   Executor   │  │  Analyzer  │  │   │
│  │  │    Job     │  │     Job      │  │    Job     │  │   │
│  │  └────────────┘  └──────────────┘  └────────────┘  │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Data Access Layer                       │   │
│  │  ┌────────────┐  ┌──────────────┐  ┌────────────┐  │   │
│  │  │ TastyTrade │  │Active Record │  │   Redis    │  │   │
│  │  │API Service │  │   Models     │  │   Cache    │  │   │
│  │  └────────────┘  └──────────────┘  └────────────┘  │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ HTTPS/WebSocket
                              │
┌─────────────────────────────┴───────────────────────────────┐
│                    External Services                         │
│  ┌─────────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   TastyTrade   │  │   Market     │  │  PostgreSQL  │  │
│  │      API       │  │   Data Feed  │  │   Database   │  │
│  └─────────────────┘  └──────────────┘  └──────────────┘  │
│  ┌─────────────────┐  ┌──────────────┐                     │
│  │     Redis      │  │   Sidekiq    │                     │
│  │     Server     │  │    Queue     │                     │
│  └─────────────────┘  └──────────────┘                     │
└─────────────────────────────────────────────────────────────┘
```

## Component Details

### Frontend Layer

#### Web UI
- **Technology**: Hotwire (Turbo + Stimulus.js) or React
- **Responsibilities**:
  - User interface rendering with Turbo Frames/Streams
  - Client-side interactivity with Stimulus controllers
  - Real-time updates via Action Cable
  - Form validation and submission

#### Action Cable Client
- **Purpose**: Real-time market data and order updates
- **Features**:
  - Built-in reconnection handling
  - Channel subscriptions for market data
  - Broadcasting trade updates
  - Presence tracking for active users

### Backend Layer

#### Rails Application Layer

##### Rails Controllers
- **RESTful Endpoints**:
  ```ruby
  namespace :api do
    namespace :v1 do
      resources :accounts      # Account management
      resources :positions     # Position tracking
      resources :orders        # Order placement
      resources :options       # Option chains
      resources :market_data   # Market information
    end
  end
  ```

##### Authentication (Devise)
- **Features**:
  - Session-based authentication
  - JWT tokens for API access
  - Encrypted credentials with Rails 7.1+
  - Built-in rate limiting with Rack::Attack

#### Services & Background Jobs Layer

##### Trading Service
- **Core Service Object**:
  ```ruby
  class TradingService
    def place_order(order_params)
      # Business logic for order placement
    end
    
    def modify_order(order_id, modifications)
      # Modify existing order
    end
    
    def cancel_order(order_id)
      # Cancel order logic
    end
  end
  ```

##### Strategy Service
- **Rails Service Pattern**:
  - Service objects for each strategy type
  - Strategy::CoveredCall, Strategy::IronCondor
  - Backtesting with historical data
  - Performance tracking in Active Record

##### Risk Service
- **Risk Management**:
  - RiskCalculator service object
  - Greeks calculation with Ruby gems
  - Portfolio metrics stored in Redis
  - Action Cable alerts for thresholds

##### Scanner Job (Sidekiq)
- **Background Job Implementation**:
  ```ruby
  class MarketScannerJob < ApplicationJob
    queue_as :critical
    
    def perform
      candidates = MarketScanner.new.scan
      filtered = TradingRules.apply(candidates)
      ranked = TradeRanker.new(filtered).rank
      ValidatedTrade.create_batch(ranked.first(5))
    end
  end
  ```
- **Scheduled with Sidekiq-Cron**:
  - Runs every 30 seconds
  - Parallel data fetching with concurrent-ruby
  - Rules engine using Ruby DSL
  - Database-backed trade validation

##### Executor Job (Sidekiq)
- **Automated Execution Job**:
  ```ruby
  class TradeExecutorJob < ApplicationJob
    queue_as :urgent
    sidekiq_options retry: 3
    
    def perform(validated_trade_id)
      trade = ValidatedTrade.find(validated_trade_id)
      result = TastyTradeAPI::OrderService.new.place_order(trade)
      trade.update!(status: result.status, order_id: result.id)
      MonitorFillJob.perform_later(result.id)
    end
  end
  ```
- **Safety Features**:
  - Database transactions for atomicity
  - KillSwitch concern for emergency stops
  - Rails validations for position limits
  - Automatic retries with exponential backoff

##### Analyzer Job (Sidekiq)
- **Market Analysis Job**:
  - DataAggregator service for all data sources
  - OptionsAnalyzer for Greeks calculations
  - AlternativeData module for sentiment
  - MarketRegime detector with ML.rb

#### Data Access Layer

##### TastyTrade API Service
- **Ruby API Client**:
  ```ruby
  module TastyTradeAPI
    class Client
      include HTTParty
      base_uri 'https://api.tastyworks.com'
      
      def authenticate(username, password)
        # OAuth 2.0 authentication
      end
      
      def get_account
        # Fetch account details
      end
      
      def place_order(order_params)
        # Submit order to API
      end
      
      def stream_market_data(&block)
        # WebSocket streaming with Faye
      end
    end
  end
  ```

##### Active Record Models
- **Database Schema**:
  ```ruby
  # app/models/user.rb
  class User < ApplicationRecord
    has_secure_password
    has_many :positions
    has_many :orders
    has_many :strategies
    encrypts :api_key
  end
  
  # app/models/order.rb
  class Order < ApplicationRecord
    belongs_to :user
    validates :symbol, :quantity, :order_type, presence: true
    
    state_machine initial: :pending do
      event :fill { transition pending: :filled }
      event :cancel { transition pending: :cancelled }
    end
  end
  
  # Additional models: Position, Strategy, ValidatedTrade
  ```

##### Redis Cache
- **Rails Cache Store**:
  ```ruby
  # config/environments/production.rb
  config.cache_store = :redis_cache_store, {
    url: ENV['REDIS_URL'],
    expires_in: 1.hour,
    namespace: 'tastytrades'
  }
  ```
  - Market data: 1 second TTL
  - Option chains: 5 minutes TTL
  - Account data: 30 seconds TTL
  - Fragment caching for views

## Data Flow

### Order Placement Flow
```
1. User submits order via UI
2. Frontend validates and sends to backend
3. Backend validates against risk rules
4. Order sent to TastyTrade API
5. Order confirmation stored in database
6. WebSocket notification sent to UI
7. UI updates with order status
```

### Automated Trading Flow
```
1. Scanner continuously monitors market data
2. Identifies trades matching TRADING_RULES.md criteria
3. Validates trades against portfolio constraints
4. Ranks and selects top 5 trades
5. Executor places orders automatically
6. Monitor fills and update positions
7. Log all activities for audit trail
8. Send notifications to UI dashboard
```

### Market Data Flow
```
1. Backend establishes WebSocket with TastyTrade
2. Subscribe to required symbols
3. Stream data to Redis cache
4. Broadcast to connected UI clients
5. UI renders real-time updates
```

## Security Architecture

### API Security
- HTTPS only communication
- JWT tokens with refresh mechanism
- API rate limiting (100 requests/minute)
- Input validation and sanitization

### Data Security
- API credentials encrypted at rest
- Database encryption for sensitive data
- Secure session management
- Regular security audits

## Deployment Architecture

### Development Environment
```yaml
version: '3.8'
services:
  web:
    build: .
    command: bundle exec rails server -b 0.0.0.0
    ports:
      - "3000:3000"
    environment:
      - RAILS_ENV=development
    volumes:
      - .:/rails
    depends_on:
      - postgres
      - redis
  
  sidekiq:
    build: .
    command: bundle exec sidekiq
    volumes:
      - .:/rails
    environment:
      - RAILS_ENV=development
    depends_on:
      - postgres
      - redis
  
  postgres:
    image: postgres:14
    environment:
      - POSTGRES_DB=tastytrades_development
      - POSTGRES_USER=rails
      - POSTGRES_PASSWORD=password
  
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
```

### Production Environment
- **Backend**: Multiple instances behind load balancer
- **Database**: PostgreSQL with read replicas
- **Cache**: Redis cluster
- **Monitoring**: Prometheus + Grafana
- **Logging**: ELK stack (Elasticsearch, Logstash, Kibana)

## Scalability Considerations

### Horizontal Scaling
- Stateless backend design
- Session storage in Redis
- Database connection pooling
- Load balancer for traffic distribution

### Performance Optimization
- Async/await for I/O operations
- Connection pooling for database
- Efficient WebSocket message batching
- CDN for static assets

## Monitoring and Observability

### Metrics
- API response times
- WebSocket connection count
- Order execution latency
- Error rates by endpoint
- Database query performance

### Logging
- Structured JSON logging
- Log aggregation with Logstash
- Error tracking with Sentry
- Audit logs for trading activities

## Future Enhancements

### Phase 2
- Mobile application support
- Advanced charting capabilities
- Social trading features
- Automated trading bots

### Phase 3
- Multi-broker support
- Machine learning for strategy optimization
- Advanced analytics dashboard
- Backtesting engine improvements