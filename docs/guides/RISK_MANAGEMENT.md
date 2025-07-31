# Risk Management System

The OptionBotPro includes comprehensive risk management and portfolio protection features to safeguard your capital during automated trading.

## 🛡️ Core Protection Features

### 1. Cash Reserve Protection
- **Default**: 25% of buying power must remain in cash
- **Purpose**: Ensures you never commit all available funds
- **Override**: Can be adjusted between 20-50%, but 25% is recommended
- **Enforcement**: All trades are blocked if they would violate this reserve

### 2. Daily Loss Limits
- **Default**: 5% maximum daily loss
- **Purpose**: Prevents catastrophic losses during bad market days
- **Action**: Automatic emergency stop when limit is reached
- **Recovery**: Manual intervention required to resume trading

### 3. Single Trade Size Limits
- **Default**: 10% maximum of portfolio per trade
- **Purpose**: Prevents over-concentration in single positions
- **Calculation**: Based on total portfolio value, not just cash
- **Flexibility**: Adjustable between 5-20% based on risk tolerance

### 4. Portfolio Exposure Limits
- **Default**: Maximum 75% of portfolio can be in active positions
- **Purpose**: Maintains liquidity and reduces overall portfolio risk
- **Calculation**: Total market value of all positions vs. portfolio value
- **Complement**: Works with 25% cash reserve requirement

## 🚨 Emergency Stop System

### Automatic Triggers
1. **Daily Loss Exceeded**: Stops all trading when daily loss limit is hit
2. **API Errors**: Temporary halt during connection issues
3. **Validation Failures**: Stops trading if risk checks fail repeatedly
4. **Account Restrictions**: Triggered by PDT or margin violations

### Manual Emergency Stop
- Available via API endpoint or web interface
- Immediately cancels all pending orders
- Blocks all new order submissions
- Requires manual confirmation to clear

### Recovery Process
1. **Identify Cause**: Review emergency stop reason
2. **Address Issues**: Fix underlying problems (account funding, etc.)
3. **Manual Clearance**: Explicitly clear emergency stop with confirmation
4. **Gradual Resume**: Consider starting with smaller position sizes

## 📊 Risk Validation Process

### Pre-Trade Validation
Every order goes through these checks:

1. **Emergency Stop Check**: Is trading currently halted?
2. **Cash Reserve Check**: Will this trade violate reserve requirements?
3. **Trade Size Check**: Is this trade within single-trade limits?
4. **Daily Loss Check**: Has daily loss limit been reached?
5. **Exposure Check**: Will this exceed maximum portfolio exposure?
6. **Concentration Check**: Will this over-concentrate in one symbol?

### Order Blocking
- Orders that fail ANY risk check are automatically rejected
- Detailed violation reasons are logged and returned
- No partial fills - orders are either fully approved or fully rejected

## 🔧 Configuration Options

### Portfolio Protection Settings

```json
{
  "cash_reserve_percentage": 25.0,        // 20.0 - 50.0
  "max_daily_loss_percentage": 5.0,       // 1.0 - 15.0
  "max_single_trade_percentage": 10.0,    // 5.0 - 20.0
  "max_portfolio_exposure_percentage": 75.0, // 50.0 - 85.0
  "max_position_concentration_percentage": 20.0, // Per symbol limit
  "max_daily_trades": 50,                 // Daily trade count limit
  "trailing_stop_percentage": 2.0         // Automatic stop-loss
}
```

### Alert Settings
- **Email Alerts**: Notifications for risk violations
- **SMS Alerts**: Emergency notifications (requires phone number)
- **Log Alerts**: All decisions logged for audit trail

## 🏗️ Implementation Details

### Database Storage
- `portfolio_protections` table stores per-account settings
- Unique constraint ensures one protection per user/account
- Database constraints enforce safe value ranges
- Audit trail tracks all emergency stop events

### Caching Strategy
- Emergency stops cached in Redis for fast access
- Portfolio status cached for performance
- Cache keys include user and account identifiers
- Automatic cache expiration prevents stale data

### API Integration
- Real-time account data from TastyTrade API
- Position valuation uses current market prices
- Buying power checks include maintenance requirements
- Order validation before API submission

## 🔍 Monitoring and Logging

### Risk Decision Logging
Every trade decision is logged with:
- Order parameters and validation result
- Account snapshot at decision time
- Specific violations (if any)
- Timestamp and user identification

### Performance Tracking
- Daily P&L monitoring
- Exposure percentage tracking
- Trade count and frequency analysis
- Risk limit utilization metrics

### Alert Thresholds
- **Warning (80% of limit)**: Yellow alert, increased monitoring
- **Critical (95% of limit)**: Red alert, consider position reduction
- **Violation (100% of limit)**: Automatic trading halt

## 📱 API Usage Examples

### Check Portfolio Status
```bash
GET /api/v1/portfolio_protections/status?account_id=ABC123

Response:
{
  "success": true,
  "data": {
    "portfolio_status": {
      "buying_power": 100000.00,
      "available_for_trading": 75000.00,
      "current_exposure": 45000.00,
      "exposure_percentage": 60.0,
      "daily_pnl": -1200.00,
      "daily_pnl_percentage": -1.6,
      "risk_status": "low_risk"
    },
    "emergency_stop_active": false,
    "trading_allowed": true
  }
}
```

### Validate Trade Before Submission
```bash
POST /api/v1/portfolio_protections/validate_trade

Body:
{
  "account_id": "ABC123",
  "order": {
    "symbol": "AAPL",
    "quantity": 100,
    "order_type": "limit",
    "action": "buy-to-open",
    "price": 150.00
  }
}

Response:
{
  "success": true,
  "data": {
    "allowed": false,
    "violations": [
      "Trade would violate cash reserve requirement (must keep 25% reserve)",
      "Required reserve: $25000.00, Available after trade: $10000.00"
    ]
  }
}
```

### Emergency Stop
```bash
POST /api/v1/portfolio_protections/:id/emergency_stop

Body:
{
  "reason": "Manual halt due to market volatility",
  "triggered_by": "user@example.com"
}
```

### Clear Emergency Stop
```bash
DELETE /api/v1/portfolio_protections/:id/clear_emergency_stop

Body:
{
  "confirm": "true",
  "cleared_by": "user@example.com"
}
```

## ⚠️ Important Safety Notes

### Conservative Defaults
- All default settings err on the side of caution
- New accounts start with maximum protection enabled
- Adjustments require explicit user action
- Database constraints prevent unsafe values

### Manual Override Protection
- Emergency stops cannot be cleared programmatically
- Requires explicit human confirmation
- Cooling-off period recommended after emergency stops
- Consider position size reduction after incidents

### Regular Review
- Review protection settings monthly
- Adjust based on account size and risk tolerance
- Monitor actual vs. intended exposure levels
- Update limits as trading experience grows

## 🆘 Emergency Procedures

### If Emergency Stop Triggers
1. **Don't Panic**: The system is protecting you
2. **Review Logs**: Check what triggered the stop
3. **Assess Positions**: Review current holdings
4. **Address Issues**: Fix any underlying problems
5. **Plan Recovery**: Consider gradual restart strategy

### If You Need to Override
1. **Validate Reason**: Ensure override is truly necessary
2. **Check Account**: Verify account health and balances
3. **Start Small**: Resume with reduced position sizes
4. **Monitor Closely**: Watch trades more carefully initially

### Contact Information
- **Technical Issues**: Check application logs first
- **Account Issues**: Contact TastyTrade support
- **Risk Questions**: Review this documentation

---

*Remember: These protections exist to preserve your capital. It's better to miss opportunities than to lose money unnecessarily.*