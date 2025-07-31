# Sandbox vs Production - Complete Guide

## Overview

TastyTrade provides two completely separate environments:

1. **Sandbox** - For testing (fake money, no risk)
2. **Production** - For real trading (real money, real risk)

## Key Differences

| Feature | Sandbox | Production |
|---------|---------|------------|
| **API URL** | `https://api.cert.tastyworks.com` | `https://api.tastyworks.com` |
| **Credentials** | Separate sandbox account | Your real TastyTrade login |
| **Money** | Fake/test money | Real money |
| **Orders** | Never reach real market | Execute on real exchanges |
| **Account Creation** | developer.tastytrade.com | tastyworks.com |

## Setting Up Sandbox

### Step 1: Create Sandbox Account

1. Go to https://developer.tastytrade.com/
2. Click "Get Started" or "Create Sandbox Account"
3. Fill out the registration form
4. You'll receive:
   - Sandbox username (usually your email)
   - Sandbox password
   - These are DIFFERENT from your live account!

### Step 2: Configure Your App

```bash
# Switch to sandbox configuration
./bin/switch_environment
# Choose option 1 (Sandbox)

# Edit .env.local with your sandbox credentials
TASTYTRADE_USERNAME=your-sandbox-email@example.com
TASTYTRADE_PASSWORD=your-sandbox-password
TASTYTRADE_API_URL=https://api.cert.tastyworks.com
```

### Step 3: Run in Sandbox Mode

```bash
# Start the server in sandbox mode
RAILS_ENV=sandbox rails server

# Or run tests
./bin/sandbox_test
```

## Setting Up Production

### ⚠️ WARNING: Production = Real Money!

### Step 1: Use Your Regular TastyTrade Account

- Use the same credentials you use for tastyworks.com
- No separate registration needed

### Step 2: Configure Your App

```bash
# Switch to production configuration
./bin/switch_environment
# Choose option 2 (Production)

# Edit .env.local with your REAL credentials
TASTYTRADE_USERNAME=your-real-email@example.com
TASTYTRADE_PASSWORD=your-real-password
TASTYTRADE_API_URL=https://api.tastyworks.com
```

### Step 3: Run in Production Mode

```bash
# Start the server in production mode
RAILS_ENV=production rails server
```

## How Our App Handles Environments

### Single Login Screen
- Same login page for both environments
- The app routes to different APIs based on Rails environment
- Visual indicators show which mode you're in

### Environment Detection
```ruby
# The app automatically uses the correct API based on environment
if Rails.env.sandbox?
  # Uses: https://api.cert.tastyworks.com
  # Shows: "🧪 Sandbox Mode" warning
elsif Rails.env.production?
  # Uses: https://api.tastyworks.com
  # Shows: "⚠️ Live Trading Mode" warning
end
```

### Visual Indicators

**Sandbox Mode:**
```
🧪 Sandbox Mode Active
• Use sandbox credentials from developer.tastytrade.com
• These are NOT your live trading credentials
• Connecting to: https://api.cert.tastyworks.com
```

**Production Mode:**
```
⚠️ Live Trading Mode
• Use your real TastyTrade credentials
• Real money trades will be executed
• Connecting to: https://api.tastyworks.com
```

## Common Confusion Points

### "Do I need different logins?"
**YES!** Sandbox and production are completely separate:
- Sandbox account: Created at developer.tastytrade.com
- Production account: Your regular TastyTrade/TastyWorks account

### "Can I use production credentials in sandbox?"
**NO!** They are separate systems:
- Production credentials → Production API only
- Sandbox credentials → Sandbox API only

### "How do I know which environment I'm in?"
Look for:
1. The warning banner on login page
2. The URL in the browser (localhost:3000 vs your production URL)
3. Rails environment: `echo $RAILS_ENV`
4. API URL in logs

## Best Practices

### Development Workflow
1. **Always start with sandbox** for new features
2. **Test thoroughly** in sandbox
3. **Review all changes** before production
4. **Use separate databases** for each environment

### Security
1. **Never commit credentials** to git
2. **Use .env.local** (git-ignored) for secrets
3. **Keep sandbox and production credentials separate**
4. **Enable 2FA** on your TastyTrade account

### Testing Checklist
- [ ] Create sandbox account at developer.tastytrade.com
- [ ] Configure .env.local with sandbox credentials
- [ ] Test authentication with `./bin/test_tastytrade_auth`
- [ ] Run full test suite with `./bin/sandbox_test`
- [ ] Verify orders stay in sandbox (check TastyWorks app)

## Troubleshooting

### "Invalid credentials" error
1. Check you're using the right credentials for the environment
2. Verify API URL matches your credentials
3. Try logging into the web platform to verify credentials

### "Can't create sandbox account"
1. Go directly to https://developer.tastytrade.com/
2. Use a different email than your production account
3. Check spam folder for confirmation email

### "Orders not showing in TastyWorks app"
- Sandbox orders only visible in sandbox environment
- Production orders only visible in production app
- They are completely separate systems

## Quick Reference

```bash
# Check current environment
echo $RAILS_ENV

# Test authentication
./bin/test_tastytrade_auth

# Switch environments
./bin/switch_environment

# Start server
RAILS_ENV=sandbox rails server    # For testing
RAILS_ENV=production rails server  # For real trading
```

Remember: **Sandbox is for testing, Production is for real trading!**