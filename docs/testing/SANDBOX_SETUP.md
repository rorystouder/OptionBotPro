# Sandbox Testing Setup

This document explains how to set up and use the TastyTrade sandbox environment for testing our automated trading system.

## Overview

The sandbox environment allows you to test all trading functionality without placing real orders or affecting real markets. All orders remain within the sandbox system and follow predetermined behavior patterns.

## Environment Configuration

### 1. Sandbox Environment Variables

Copy the `.env.sandbox` file and update with your sandbox credentials:

```bash
cp .env.sandbox .env.local.sandbox
```

Update the following values:
- `TASTYTRADE_CLIENT_ID=your_sandbox_client_id_here`
- `TASTYTRADE_CLIENT_SECRET=your_sandbox_client_secret_here`

### 2. Sandbox API Endpoints

- **API Base URL:** `https://api.cert.tastyworks.com`
- **WebSocket URL:** `wss://streamer.cert.tastyworks.com`

### 3. Database Configuration

The sandbox uses a separate SQLite database (`db/sandbox.sqlite3`) to avoid interfering with development data.

## Order Behavior in Sandbox

The sandbox follows specific order fill logic:

| Order Type | Price Condition | Behavior |
|------------|----------------|----------|
| Market Orders | Any price | Always fill at **$1.00** |
| Limit Orders | Price ≤ $3.00 | Fill **immediately** |
| Limit Orders | Price > $3.00 | Remain **live**, never fill |

This allows testing of different order scenarios and system responses.

## Running Sandbox Tests

### Method 1: Command Line Script

```bash
# Run the complete test suite
./bin/sandbox_test
```

### Method 2: Web Interface

1. Start the Rails server in sandbox mode:
   ```bash
   RAILS_ENV=sandbox rails server
   ```

2. Navigate to: `http://localhost:3000/sandbox`

3. Click "Run Full Test Suite"

### Method 3: Rails Console

```ruby
# In Rails console
user = User.find_by(email: 'your-email@example.com')
test_service = SandboxTestService.new(user: user)
results = test_service.run_full_test_suite
puts JSON.pretty_generate(results)
```

## Test Categories

### 1. 🔐 API Authentication
- Validates TastyTrade API login
- Retrieves account information
- Checks token validity

### 2. 📊 Market Data Retrieval
- Tests quote retrieval for multiple symbols
- Validates data freshness and format
- Checks options chain access

### 3. 🔍 Scanner Functionality
- Runs the market scanner service
- Validates trade opportunity identification
- Tests filtering and ranking algorithms

### 4. 🛡️ Risk Management
- Tests 25% cash reserve protection
- Validates trade size limits
- Checks emergency stop functionality

### 5. 📋 Order Placement
- Places test orders with different parameters
- Validates sandbox order behavior
- Tests order status tracking

### 6. ⚡ Execution Pipeline
- Tests end-to-end trade execution
- Validates integration between components
- Checks error handling

## Understanding Test Results

### Success Criteria
- **100% Pass Rate:** All systems operational
- **80-99% Pass Rate:** Minor issues detected
- **<80% Pass Rate:** Significant issues require attention

### Common Issues and Solutions

#### Authentication Failures
- Check sandbox credentials in `.env.sandbox`
- Verify API endpoint is set to `api.cert.tastyworks.com`
- Ensure account has sandbox access

#### Market Data Issues
- Some symbols may lag in sandbox environment
- Contact `api.support@tastytrade.com` for symbol issues
- Use mock data mode for consistent testing

#### Order Placement Failures
- Verify order parameters match sandbox requirements
- Check risk management limits
- Ensure account has sufficient buying power

## Mock Data Mode

For consistent testing, enable mock data mode:

```bash
MOCK_MARKET_DATA=true
```

This provides predictable market data for repeatable tests.

## Sandbox Limitations

The following services are **not available** in sandbox:
- Symbol search
- Net liquidating value history
- Market metrics
- Real-time streaming data

These limitations don't affect core trading functionality testing.

## Best Practices

### 1. Regular Testing
- Run sandbox tests before deploying changes
- Test after updating trading rules or risk parameters
- Validate after TastyTrade API updates

### 2. Test Data Management
- Use separate test users for different scenarios
- Clean up test orders periodically
- Maintain test result history for trend analysis

### 3. Environment Isolation
- Never use production credentials in sandbox
- Keep sandbox database separate from development
- Use appropriate environment variables

### 4. Error Monitoring
- Review failed tests immediately
- Check logs for detailed error information
- Monitor success rate trends over time

## Troubleshooting

### Common Error Messages

**"Authentication token expired"**
- Re-authenticate with TastyTrade
- Check credential configuration
- Verify account permissions

**"Rate limit exceeded"**
- Reduce test frequency
- Implement proper delays between API calls
- Check concurrent job limits

**"Risk management validation failed"**
- Review portfolio protection settings
- Check cash reserve requirements
- Validate position sizing limits

### Getting Help

1. Check the Rails logs: `tail -f log/sandbox.log`
2. Review test results in the web interface
3. Contact TastyTrade support for sandbox-specific issues
4. Review the system architecture documentation

## Example Test Output

```
🧪 OptionBotPro Sandbox Test Runner
==================================================
Environment: sandbox
API URL: https://api.cert.tastyworks.com
Database: db/sandbox.sqlite3

Test User: Sandbox Tester (ID: 1)

🚀 Starting sandbox test suite...

📊 TEST RESULTS
==============================
Total Tests: 6
Passed: 5
Failed: 1
Success Rate: 83.3%
Overall Status: SOME_FAILED

✅ Authentication: Retrieved 1 accounts
✅ Market data: Retrieved quotes for 3/3 symbols
✅ Scanner: Scanner found 2 opportunities  
✅ Risk management: Normal trade: Approved, Excessive trade: Rejected
❌ Order placement: Failed to place limit order
✅ Execution pipeline: Put Credit Spread order placed for SPY

💾 Results saved as SandboxTestResult #1
🌐 View in browser: http://localhost:3000/sandbox/1

✅ Sandbox testing complete!
```

This comprehensive testing framework ensures your trading system works correctly before going live.