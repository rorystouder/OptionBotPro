# TastyTrades UI Project Summary

## Project Overview
A Ruby on Rails automated trading system for TastyTrade with a critical **25% cash reserve protection** requirement. The system automatically scans for option trading opportunities and can execute trades while ensuring the last 25% of available funds are never used.

## Current Status (As of July 31, 2025)

### ✅ Completed Features

1. **Rails Application Setup**
   - Rails 8.0.2 with SQLite database (NO PostgreSQL)
   - Ruby 3.2.0 installed
   - All gems configured and working
   - Development environment fully functional

2. **Core Models & Database**
   - User model with authentication
   - Order model with AASM state machine
   - Position model for portfolio tracking
   - PortfolioProtection model with 25% reserve constraint
   - TradeScanResult and SandboxTestResult models
   - Database migrations all applied

3. **TastyTrade API Integration**
   - **IMPORTANT**: Uses session-based auth (username/password), NOT OAuth
   - Complete API service with all trading endpoints
   - Authentication service with 24-hour token caching
   - Error handling for specific scenarios
   - Sandbox and production environment support

4. **Risk Management System** (Critical Feature)
   - **25% cash reserve ALWAYS protected**
   - Database-level constraints ensure safety
   - Per-trade validation before execution
   - Emergency stop functionality
   - Daily loss limits (5%)
   - Single trade limits (10% of portfolio)

5. **Automated Stock Scanner**
   - MarketScannerService following TRADING_RULES.md
   - Scans for put credit spreads, call credit spreads, iron condors
   - Filters: POP ≥ 65%, risk/reward ≥ 0.33
   - Maximum 5 trades per cycle
   - Sector diversification (max 2 per sector)
   - Background job for periodic scanning

6. **Trade Execution System**
   - TradeExecutorService for automated order placement
   - Multi-leg option order support
   - Integration with risk management
   - Order tracking and status management

7. **Web Interface**
   - Dashboard with portfolio overview
   - Scanner interface with manual trigger
   - User authentication with TastyTrade integration
   - Sandbox testing interface
   - Bootstrap 5 styling

8. **Comprehensive Testing**
   - SandboxTestService for full system validation
   - 6 test categories covering all components
   - Sandbox environment configuration
   - Test result tracking and history

9. **Documentation**
   - Complete setup guides in /docs
   - API integration documentation
   - Trading rules and architecture docs
   - Sandbox vs production guide

### 🔄 Pending Tasks
- WebSocket connection for real-time market data (not critical for 5-min scanner)

## Critical Implementation Details

### Authentication Flow
```ruby
# TastyTrade uses session-based auth, NOT OAuth!
auth_service = Tastytrade::AuthService.new
auth_service.authenticate(
  username: "your-email@example.com",  # NOT a client ID
  password: "your-password"            # Your actual TastyTrade password
)
```

### Environment Setup
```bash
# Sandbox (fake money testing)
TASTYTRADE_USERNAME=sandbox-email@example.com
TASTYTRADE_PASSWORD=sandbox-password
TASTYTRADE_API_URL=https://api.cert.tastyworks.com

# Production (real money)
TASTYTRADE_USERNAME=your-real-email@example.com
TASTYTRADE_PASSWORD=your-real-password
TASTYTRADE_API_URL=https://api.tastyworks.com
```

### Key Files to Remember
- `/app/services/risk_management_service.rb` - 25% protection logic
- `/app/services/market_scanner_service.rb` - Automated trade finder
- `/app/services/tastytrade/api_service.rb` - API integration
- `/app/models/portfolio_protection.rb` - Risk constraints
- `/docs/guides/TRADING_RULES.md` - Trading strategy rules

## How to Resume Development

### 1. Environment Setup
```bash
cd /home/rorystouder/projects/tastytradesUI

# Install dependencies if needed
bundle install

# Run migrations if needed
rails db:migrate

# Start server
rails server
```

### 2. Test Current Setup
```bash
# Test TastyTrade authentication
./bin/test_tastytrade_auth

# Run sandbox tests
./bin/sandbox_test

# Check system status
rails console
User.first.tastytrade_authenticated?
```

### 3. Key Commands
```bash
# Switch between environments
./bin/switch_environment

# Run scanner manually
rails console
MarketScannerJob.perform_now(User.first.id)

# Access web interfaces
http://localhost:3000/dashboard  # Main dashboard
http://localhost:3000/scanner    # Scanner interface
http://localhost:3000/sandbox    # Testing interface
```

## Important Reminders

### 🛡️ 25% Cash Reserve Protection
- **NEVER DISABLED** - Core safety feature
- Enforced at database level
- Checked before every trade
- User cannot override

### 🔐 Authentication
- **NO API KEYS** - TastyTrade uses username/password
- Sandbox needs separate account from developer.tastytrade.com
- Tokens expire after 24 hours
- Automatic re-auth prompts in UI

### 📊 Trading Rules
- Maximum 5 trades per scan
- POP must be ≥ 65%
- Risk/reward must be ≥ 0.33
- Max 2 trades per sector
- Scanner runs every 5 minutes during market hours

### 🧪 Testing
- Always test in sandbox first
- Sandbox orders fill at specific prices (market=$1, limit≤$3=fill)
- Use separate database for sandbox
- Monitor all test results

## Next Development Steps

1. **If WebSocket needed**: Implement real-time data streaming
2. **Enhanced Features**: 
   - Email/SMS trade notifications
   - Performance analytics dashboard
   - Multiple account support
   - More option strategies

3. **Production Deployment**:
   - Set up production server
   - Configure production database
   - Set up monitoring/logging
   - Deploy with proper security

## Git Status
- Repository initialized and working
- Main branch is stable
- All code committed except Ruby installation files
- Ready for continued development

## Contact for Issues
- TastyTrade API Support: api.support@tastytrade.com
- TastyTrade Developer Portal: https://developer.tastytrade.com/

---

**Last Updated**: July 31, 2025
**Primary Developer Note**: System is fully functional for automated option trading with safety measures in place. The 25% cash reserve protection is the most critical feature and must never be removed or bypassed.