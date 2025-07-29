# Development Guidelines

This document outlines the development standards, workflow, and rules for the TastyTrades Option Trader UI project.

## Development Rules for Claude AI Assistant

### MANDATORY RULES - MUST FOLLOW BEFORE WRITING ANY CODE:

1. **ALWAYS review the existing codebase** to check if there is a framework or pattern already implemented before writing new code.
   - Check existing modules and their structure
   - Review import statements to understand dependencies
   - Look for established patterns in similar files

2. **ALWAYS prefer existing open-source packages** over writing code from scratch when suitable packages exist.
   - Check PyPI for established libraries
   - Verify license compatibility
   - Consider maintenance status and community support

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

### Python Style Guide
- Follow PEP 8 conventions
- Use type hints for all function parameters and return values
- Maximum line length: 88 characters (Black formatter standard)
- Use descriptive variable and function names

### Project Structure
```python
# Example module structure
src/
├── api/
│   ├── __init__.py
│   ├── client.py         # TastyTrade API client
│   ├── models.py         # API data models
│   └── endpoints.py      # API endpoint definitions
├── core/
│   ├── __init__.py
│   ├── trading.py        # Trading logic
│   ├── strategies.py     # Trading strategies
│   └── risk.py          # Risk management
└── web/
    ├── __init__.py
    ├── app.py           # Web application
    ├── routes.py        # API routes
    └── websocket.py     # WebSocket handlers
```

### Naming Conventions
- **Classes**: PascalCase (e.g., `OptionChain`, `TradingStrategy`)
- **Functions/Variables**: snake_case (e.g., `get_option_chain`, `current_price`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_RETRY_ATTEMPTS`)
- **Private methods**: Leading underscore (e.g., `_calculate_risk`)

## Development Workflow

### Before Starting Development
1. Review existing code structure
2. Check for relevant open-source packages
3. Review the API documentation
4. Plan the implementation approach

### During Development
1. Write clean, readable code with proper documentation
2. Add type hints to all functions
3. Include docstrings for classes and functions
4. Handle errors gracefully with proper exception handling
5. Log important events and errors

### Testing Requirements
- Write unit tests for all new functions
- Aim for >80% code coverage
- Use pytest for testing framework
- Mock external API calls in tests

## Recommended Open-Source Packages

### Web Framework
- **FastAPI**: Modern, fast web framework with automatic API documentation
- **Flask**: Lightweight alternative if simplicity is preferred

### TastyTrade API
- **tastytrade-api**: Official Python SDK (if available)
- **requests**: For HTTP requests if no SDK exists
- **websocket-client**: For real-time data streaming

### Data Processing
- **pandas**: Data manipulation and analysis
- **numpy**: Numerical computations
- **pydantic**: Data validation and settings management

### UI/Frontend Communication
- **python-socketio**: WebSocket implementation
- **fastapi-websocket**: WebSocket support for FastAPI

### Database
- **SQLAlchemy**: ORM for database interactions
- **alembic**: Database migration tool

### Testing
- **pytest**: Testing framework
- **pytest-cov**: Code coverage
- **pytest-mock**: Mocking support

### Development Tools
- **black**: Code formatter
- **flake8**: Linting
- **mypy**: Static type checking
- **pre-commit**: Git hooks for code quality

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