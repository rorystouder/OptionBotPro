# Development Guidelines

This document outlines the development standards, workflow, and rules for the TastyTrades Option Trader UI project built with Ruby on Rails.

## Development Rules for Claude AI Assistant

### MANDATORY RULES - MUST FOLLOW BEFORE WRITING ANY CODE:

1. **ALWAYS review the existing codebase** to check if there is a framework or pattern already implemented before writing new code.
   - Check existing modules and their structure
   - Review import statements to understand dependencies
   - Look for established patterns in similar files

2. **ALWAYS prefer existing open-source packages** over writing code from scratch when suitable packages exist.
   - Check RubyGems.org for established gems
   - Verify license compatibility
   - Consider maintenance status and community support
   - Use Bundler for dependency management

3. **NEVER create new files** unless absolutely necessary.
   - Always prefer modifying existing files
   - If a new file is needed, check if it can be added to an existing module

4. **ALWAYS check for existing tests** before implementing new features.
   - Run existing tests to ensure they pass
   - Follow the established testing patterns

5. **NEVER hardcode sensitive information** like API keys, passwords, or credentials.
   - Always use environment variables
   - Check .env.example for configuration patterns

## Code Standards

### Ruby Style Guide
- Follow the Ruby Style Guide (rubocop gem)
- Use meaningful method and variable names
- Maximum line length: 80 characters
- Prefer symbols over strings for hash keys
- Use Ruby 3.2+ features appropriately

### Rails Project Structure
```ruby
# Rails application structure
app/
├── channels/         # Action Cable channels
│   └── market_data_channel.rb
├── controllers/      # Rails controllers
│   ├── api/
│   │   └── v1/
│   │       ├── orders_controller.rb
│   │       └── positions_controller.rb
│   └── application_controller.rb
├── jobs/            # Active Job classes
│   ├── market_scanner_job.rb
│   └── trade_executor_job.rb
├── models/          # Active Record models
│   ├── order.rb
│   ├── position.rb
│   └── user.rb
├── services/        # Service objects
│   ├── trading_service.rb
│   ├── risk_calculator.rb
│   └── tastytrade_api_client.rb
└── views/           # Rails views
    └── layouts/
        └── application.html.erb
```

### Rails Naming Conventions
- **Classes/Modules**: PascalCase (e.g., `OptionChain`, `TradingStrategy`)
- **Methods/Variables**: snake_case (e.g., `get_option_chain`, `current_price`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_RETRY_ATTEMPTS`)
- **Private methods**: `private` keyword, not underscore
- **Files**: snake_case matching class names
- **Database tables**: plural snake_case (e.g., `trading_strategies`)

## Development Workflow

### Before Starting Development
1. Review existing code structure
2. Check for relevant open-source packages
3. Review the API documentation
4. Plan the implementation approach

### During Development
1. Write clean, readable code with proper documentation
2. Use YARD comments for method documentation
3. Follow Rails conventions for ActiveRecord models
4. Handle errors gracefully with Rails error handling
5. Use Rails.logger for logging important events

### Testing Requirements
- Write RSpec tests for all new functionality
- Aim for >85% code coverage with SimpleCov
- Use Factory Bot for test data
- Mock external API calls with WebMock/VCR
- Test background jobs with RSpec-Sidekiq

## Recommended Ruby Gems

### Core Rails Stack
- **Rails 8.0+**: Full-stack web framework
- **Puma**: Application server
- **SQLite3**: Development database (always use SQLite for development)
- **Redis**: Caching and Sidekiq backend

### Background Processing
- **Sidekiq**: Background job processing
- **sidekiq-cron**: Scheduled job execution
- **sidekiq-web**: Web UI for monitoring jobs

### API Integration
- **httparty**: HTTP client for external APIs
- **faraday**: HTTP client library with middleware
- **faye-websocket**: WebSocket client for streaming

### Real-time Features
- **Action Cable**: Built-in WebSocket support
- **turbo-rails**: Hotwire Turbo for SPA-like experience
- **stimulus-rails**: JavaScript framework

### Authentication & Security
- **devise**: Authentication solution
- **cancancan**: Authorization
- **rack-attack**: Rate limiting and blocking

### Data Processing
- **ruby-statistics**: Statistical calculations
- **matrix**: Mathematical operations
- **rubanok**: Data processing pipelines

### Testing
- **rspec-rails**: Testing framework
- **factory_bot_rails**: Test data factories
- **webmock**: HTTP request stubbing
- **vcr**: Record HTTP interactions
- **simplecov**: Code coverage

### Development Tools
- **rubocop**: Ruby linter and formatter
- **rubocop-rails**: Rails-specific cops
- **brakeman**: Security scanner
- **bullet**: N+1 query detection
- **pry-rails**: Enhanced debugging

## Security Guidelines

1. **API Credentials**
   - Store in environment variables
   - Never commit to version control
   - Use `.env` files for local development

2. **Input Validation**
   - Validate all user inputs
   - Use parameterized queries for database operations
   - Sanitize data before processing

3. **Authentication**
   - Implement proper session management
   - Use secure token generation
   - Set appropriate CORS policies

## Error Handling

```python
# Example error handling pattern
from typing import Optional, Dict, Any
import logging

logger = logging.getLogger(__name__)

class TastyTradeAPIError(Exception):
    """Custom exception for API errors"""
    pass

def get_option_chain(symbol: str) -> Optional[Dict[str, Any]]:
    """
    Fetch option chain data for a given symbol.
    
    Args:
        symbol: Stock symbol
        
    Returns:
        Option chain data or None if error
        
    Raises:
        TastyTradeAPIError: If API request fails
    """
    try:
        # Implementation here
        pass
    except requests.RequestException as e:
        logger.error(f"Failed to fetch option chain for {symbol}: {e}")
        raise TastyTradeAPIError(f"API request failed: {e}")
```

## Git Workflow

1. **Branch Naming**
   - Feature branches: `feature/description`
   - Bug fixes: `fix/description`
   - Documentation: `docs/description`

2. **Commit Messages**
   - Use conventional commits format
   - Examples:
     - `feat: add option chain visualization`
     - `fix: correct order submission logic`
     - `docs: update API integration guide`

3. **Pull Requests**
   - Include description of changes
   - Reference related issues
   - Ensure all tests pass
   - Request code review

## Performance Considerations

1. **API Rate Limiting**
   - Implement rate limiting for API calls
   - Use caching where appropriate
   - Batch requests when possible

2. **Data Processing**
   - Use efficient data structures
   - Implement pagination for large datasets
   - Consider async/await for I/O operations

3. **WebSocket Management**
   - Implement reconnection logic
   - Handle connection drops gracefully
   - Manage subscription limits

## Automated Trading Development

### Safety-First Development
When developing automated trading features:

1. **Always Implement Kill Switch First**
   ```python
   class AutomatedTrader:
       def __init__(self):
           self.kill_switch = KillSwitch()
           self.kill_switch.register_triggers({
               'max_daily_loss': -1000,
               'max_position_loss': -500,
               'connection_errors': 5
           })
   ```

2. **Mandatory Testing Requirements**
   - All automated trading code MUST have comprehensive tests
   - Test all edge cases and failure scenarios
   - Include integration tests with mock API
   - Require 95%+ code coverage for trading logic

3. **Paper Trading Validation**
   - New strategies must run in paper trading for minimum 5 days
   - Compare paper results with backtesting
   - Document any discrepancies

4. **Code Review Requirements**
   - Automated trading code requires 2 reviewers
   - Must include risk management review
   - Performance impact assessment required

### Automated Trading Guidelines

1. **Scanner Development**
   - Use async/await for all I/O operations
   - Implement circuit breakers for data sources
   - Cache data appropriately to reduce API calls
   - Log all trading decisions with rationale

2. **Executor Development**
   - Never use market orders in automated systems
   - Always validate orders before submission
   - Implement retry logic with exponential backoff
   - Track all order states in database

3. **Risk Controls**
   - Hard-code maximum position sizes
   - Implement portfolio-level Greeks limits
   - Monitor correlation between positions
   - Daily loss limits must be enforced

4. **Monitoring Requirements**
   - Real-time dashboard for automated trades
   - Alert on any anomalies or errors
   - Track execution quality metrics
   - Log all state transitions

## Monitoring and Logging

1. **Logging Levels**
   - DEBUG: Detailed information for debugging
   - INFO: General informational messages
   - WARNING: Warning messages for potential issues
   - ERROR: Error messages for failures
   - CRITICAL: Critical issues requiring immediate attention

2. **Log Format**
   ```python
   logging.basicConfig(
       format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
       level=logging.INFO
   )
   ```

3. **Metrics to Track**
   - API response times
   - Order execution latency
   - WebSocket connection stability
   - Error rates by endpoint
   - Automated trading performance metrics
   - Scanner efficiency and hit rate