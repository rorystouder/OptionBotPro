# Quick Start Guide - TastyTrades UI

## 🚀 Getting Started in 5 Minutes

### Prerequisites Check
```bash
ruby -v          # Should be 3.2.0
rails -v         # Should be 8.0.2
sqlite3 --version # Any recent version
```

### 1. Initial Setup (First Time Only)
```bash
# Clone and enter project
cd /home/rorystouder/projects/tastytradesUI

# Install dependencies
bundle install

# Setup database
rails db:create
rails db:migrate

# Copy environment template
cp .env.sandbox .env.local
```

### 2. Configure TastyTrade Credentials

**For Sandbox Testing (Recommended First):**
1. Get sandbox account: https://developer.tastytrade.com/
2. Edit `.env.local`:
```env
TASTYTRADE_USERNAME=your-sandbox-email@example.com
TASTYTRADE_PASSWORD=your-sandbox-password
TASTYTRADE_API_URL=https://api.cert.tastyworks.com
```

**For Production (Real Trading):**
```env
TASTYTRADE_USERNAME=your-real-email@example.com
TASTYTRADE_PASSWORD=your-real-password  
TASTYTRADE_API_URL=https://api.tastyworks.com
```

### 3. Start the Application

**Sandbox Mode:**
```bash
RAILS_ENV=sandbox rails server
```

**Production Mode (⚠️ Real Money!):**
```bash
RAILS_ENV=production rails server
```

### 4. Access the System
- Open browser: http://localhost:3000
- Create local account (for app access)
- Login with TastyTrade credentials when prompted

## 🎯 Key Features to Test

### 1. Dashboard
- View account overview
- Check 25% reserve protection status
- Monitor positions and orders

### 2. Market Scanner
- Navigate to Scanner page
- Click "Run New Scan"
- Review found opportunities
- System enforces all safety rules

### 3. Sandbox Testing
- Go to Sandbox page (dev/sandbox only)
- Run full test suite
- Verify all systems working

## 🔧 Useful Commands

```bash
# Test TastyTrade connection
./bin/test_tastytrade_auth

# Run full sandbox test suite
./bin/sandbox_test

# Switch environments easily
./bin/switch_environment

# Rails console for debugging
rails console

# Check authentication status
rails console
User.first.tastytrade_authenticated?

# Manually run scanner
rails console
MarketScannerJob.perform_now(User.first.id)
```

## ⚠️ Important Safety Features

### 25% Cash Reserve Protection
- **ALWAYS ACTIVE** - Cannot be disabled
- Prevents using last 25% of funds
- Checked before EVERY trade
- Database-level enforcement

### Risk Limits
- Max 10% portfolio per trade
- Max 5% daily loss limit
- Emergency stop functionality
- Automatic halt on violations

## 📁 Key Files for Troubleshooting

| Issue | Check This File |
|-------|----------------|
| Auth problems | `/app/services/tastytrade/auth_service.rb` |
| API errors | `/app/services/tastytrade/api_service.rb` |
| Risk violations | `/app/services/risk_management_service.rb` |
| Scanner issues | `/app/services/market_scanner_service.rb` |
| Trade execution | `/app/services/trade_executor_service.rb` |

## 🐛 Common Issues & Solutions

### "Invalid credentials"
- Check using correct environment (sandbox vs production)
- Verify credentials in `.env.local`
- Try logging into TastyTrade website to confirm

### "No trades found"
- Normal during low volatility
- Check market hours (9:30 AM - 4:00 PM ET)
- Review scanner criteria in TRADING_RULES.md

### "Risk management rejection"
- System working as designed
- Check account balance and limits
- Review portfolio protection settings

## 📚 Documentation

- **Full Setup**: `/docs/setup/`
- **API Details**: `/docs/api/`
- **Trading Rules**: `/docs/guides/TRADING_RULES.md`
- **Architecture**: `/docs/architecture/ARCHITECTURE.md`
- **Testing Guide**: `/docs/testing/SANDBOX_SETUP.md`

## 🆘 Getting Help

1. **Check logs**: `tail -f log/development.log`
2. **Run tests**: `./bin/sandbox_test`
3. **Review docs**: `/docs/` folder
4. **TastyTrade API**: api.support@tastytrade.com

---

**Remember**: Start with SANDBOX mode for safe testing!