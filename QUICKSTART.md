# 🚀 Quick Start Guide

## Starting the Application

### Option 1: Using the Start Script (Recommended)
```bash
./start-app.sh
```

### Option 2: Manual Start
```bash
# Start Rails server
bundle exec rails server

# In another terminal (optional - for background jobs)
bundle exec sidekiq
```

## First Time Setup

1. **Access the Application**
   - Open your browser to: http://localhost:3000
   - You'll be redirected to the login page

2. **Create an Account**
   - Click "Sign Up" or go to: http://localhost:3000/signup
   - Fill in your details:
     - Email
     - Password 
     - First/Last Name
     - TastyTrade Customer ID (optional for now)

3. **Login**
   - Use your email and password
   - Optionally add TastyTrade credentials to connect to the API

4. **Configure Risk Management** (IMPORTANT!)
   - The system automatically protects 25% of your funds
   - Default settings are conservative and safe
   - Review settings in your profile

## Testing the API

1. **Generate an API Token** (in Rails console):
   ```bash
   bundle exec rails console
   user = User.find_by(email: 'your_email@example.com')
   token = SecureRandom.hex(32)
   Rails.cache.write("api_token_#{token}", user.id, expires_in: 24.hours)
   puts "Your API Token: #{token}"
   exit
   ```

2. **Test API Endpoints**:
   ```bash
   # Check portfolio protection status
   curl -X GET "http://localhost:3000/api/v1/portfolio_protections/status?account_id=TEST123" \
     -H "Authorization: Bearer YOUR_TOKEN"
   ```

## Troubleshooting

### Application Won't Start?
1. Check logs: `tail -f log/development.log`
2. Ensure database exists: `ls storage/development.sqlite3`
3. Check port 3000 is free: `lsof -i :3000`

### Can't Login?
1. Create a user in Rails console:
   ```bash
   bundle exec rails console
   User.create!(
     email: "test@example.com",
     password: "password123",
     first_name: "Test",
     last_name: "User",
     tastytrade_customer_id: "TEST123"
   )
   exit
   ```

### Risk Management Not Working?
- Risk management is ALWAYS active
- Check logs for "RISK_DECISION" entries
- The 25% reserve cannot be disabled

## Safety Features Active

✅ **25% Cash Reserve Protection** - Cannot trade with last 25% of funds
✅ **5% Daily Loss Limit** - Auto-stops trading if exceeded  
✅ **10% Single Trade Limit** - Prevents oversized positions
✅ **Emergency Stop System** - Manual halt capability
✅ **Database Constraints** - Enforced at database level

## Need Help?

1. Check the comprehensive documentation in `/docs`
2. Review logs in `/log/development.log`
3. Test individual components in Rails console
4. All risk decisions are logged for debugging

---

**Remember**: The system is designed to protect your capital. The 25% reserve rule is non-negotiable and cannot be bypassed.