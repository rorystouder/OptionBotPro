# TastyTrade Options Trading UI

A Ruby on Rails application for automated options trading through the TastyTrade API, featuring market scanning, risk management, and automated trade execution.

## Features

- 🔐 **Secure Authentication**: Multi-factor authentication (MFA) support with TOTP
- 📊 **Market Scanner**: Automated scanning for high-probability option trades
- 💼 **Portfolio Management**: Real-time position tracking and P&L monitoring
- 🎯 **Risk Management**: Built-in position sizing and risk controls
- 🔄 **Automated Trading**: Execute trades based on predefined strategies
- 📈 **Live Market Data**: Real-time quotes and market updates via WebSocket
- 🧪 **Sandbox Mode**: Test strategies safely with TastyTrade's sandbox environment

## Requirements

- Ruby 3.2.0
- Rails 8.0.2+
- PostgreSQL 14+ (or SQLite for development)
- Redis 7.0+ (for Sidekiq background jobs)
- Node.js 20.x (for asset compilation)

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/rorystouder/tastytradesUI.git
cd tastytradesUI
```

### 2. Install Dependencies

```bash
# Install Ruby dependencies
bundle install

# Install Node dependencies (if any)
npm install
```

### 3. Configure Environment Variables

Copy the example environment file and configure your settings:

```bash
cp .env.example .env
```

Edit `.env` with your configuration:

```bash
# TastyTrade API Configuration
TASTYTRADE_USERNAME=your_username_or_email
TASTYTRADE_PASSWORD=your_password
TASTYTRADE_API_URL=https://api.tastyworks.com
TASTYTRADE_WEBSOCKET_URL=wss://streamer.tastyworks.com

# For sandbox testing (recommended for development):
# TASTYTRADE_API_URL=https://api.cert.tastyworks.com
# TASTYTRADE_WEBSOCKET_URL=wss://streamer.cert.tastyworks.com

# Database Configuration
DATABASE_URL=postgresql://username:password@localhost:5432/tastytrades_development
# Or for SQLite (development only):
# DATABASE_URL=sqlite3:db/development.sqlite3

# Redis Configuration
REDIS_URL=redis://localhost:6379/0

# Rails Configuration
SECRET_KEY_BASE=your_secret_key_base_here  # Generate with: bundle exec rails secret
RAILS_ENV=development
```

### 4. Database Setup

```bash
# Create database
bundle exec rails db:create

# Run migrations
bundle exec rails db:migrate

# (Optional) Seed with sample data
bundle exec rails db:seed
```

### 5. Start the Application

#### Development Mode

```bash
# Start Rails server
bundle exec rails server

# In another terminal, start Sidekiq for background jobs
bundle exec sidekiq

# In another terminal, start Redis (if not already running)
redis-server
```

The application will be available at `http://localhost:3000`

#### Production Mode (Local Testing)

```bash
# Precompile assets
RAILS_ENV=production bundle exec rails assets:precompile

# Start server
RAILS_ENV=production bundle exec rails server
```

## TastyTrade Setup

### Sandbox Environment (Recommended for Testing)

1. Create a sandbox account at [TastyTrade Sandbox](https://sandbox.tastyworks.com/)
2. Use sandbox credentials in your `.env` file
3. Set the API URLs to sandbox endpoints:
   - API: `https://api.cert.tastyworks.com`
   - WebSocket: `wss://streamer.cert.tastyworks.com`

### Production Environment

⚠️ **WARNING**: Use production credentials only when ready for live trading

1. Use your real TastyTrade account credentials
2. Set the API URLs to production endpoints:
   - API: `https://api.tastyworks.com`
   - WebSocket: `wss://streamer.tastyworks.com`

## Testing

```bash
# Run all tests
bundle exec rspec

# Run with coverage
COVERAGE=true bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/user_spec.rb

# Run linter
bundle exec rubocop

# Run security scan (with ignore file for false positives)
bundle exec brakeman -i config/brakeman.ignore
```

## Docker Setup (Optional)

```bash
# Build the Docker image
docker build -t tastytrade-ui .

# Run with Docker Compose
docker-compose up
```

## Environment Files

The application uses different environment files for different contexts:

- `.env` - Default development environment (never commit)
- `.env.example` - Template with placeholders (safe to commit)
- `.env.production` - Production settings (never commit)
- `.env.sandbox` - Sandbox testing settings (never commit)
- `.env.test` - Test environment settings (never commit)

**Security Note**: Never commit `.env` files with real credentials. They are already in `.gitignore`.

## Key Features Configuration

### Market Scanner

The market scanner runs periodically to find trading opportunities:

```ruby
# Configure in config/initializers/market_scanner.rb
MarketScanner.configure do |config|
  config.min_pop = 0.70        # Minimum probability of profit
  config.min_risk_reward = 0.25 # Minimum risk/reward ratio
  config.max_loss_percentage = 5 # Maximum loss as % of NAV
end
```

### Risk Management

Risk parameters can be configured per user or globally:

```ruby
# User-specific settings
user.max_position_size = 10000  # Maximum position size in dollars
user.max_open_positions = 10    # Maximum number of open positions
user.risk_per_trade = 0.02      # Risk 2% per trade
```

### Background Jobs

Sidekiq handles background processing for:
- Market data updates
- Position monitoring
- Order execution
- Alert notifications

Configure Sidekiq in `config/sidekiq.yml`

## API Documentation

The application provides RESTful API endpoints:

- `GET /api/positions` - List all positions
- `GET /api/market_data/:symbol` - Get market data for symbol
- `POST /api/orders` - Create new order
- `GET /api/scanner/results` - Get latest scan results

## Troubleshooting

### Common Issues

1. **Database connection failed**
   - Ensure PostgreSQL/SQLite is running
   - Check DATABASE_URL in `.env`

2. **Redis connection failed**
   - Start Redis: `redis-server`
   - Check REDIS_URL in `.env`

3. **TastyTrade authentication failed**
   - Verify credentials in `.env`
   - Check if using correct API URLs (sandbox vs production)

4. **Assets not loading in production**
   - Run: `RAILS_ENV=production bundle exec rails assets:precompile`
   - Set: `RAILS_SERVE_STATIC_FILES=true` in production

### Logs

- Rails logs: `log/development.log` or `log/production.log`
- Sidekiq logs: Check terminal output or configure logging in `config/sidekiq.yml`

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Security

- Report security vulnerabilities via GitHub Security Advisories
- Never commit credentials or API keys
- Use environment variables for all sensitive configuration
- Keep dependencies updated with `bundle update`

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

- Create an issue on GitHub for bug reports or feature requests
- Check existing issues before creating new ones
- Provide detailed information when reporting bugs

## Disclaimer

This software is for educational purposes only. Trading options involves risk of loss. The developers are not responsible for any financial losses incurred through use of this software. Always test thoroughly in sandbox mode before using with real money.