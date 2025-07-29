# TastyTrades Option Trader UI

A Ruby on Rails-based automated stock option trading application with a web interface that integrates with the TastyTrade API. The system features autonomous trading capabilities that scan markets and execute trades based on predefined rules without user intervention.

## Project Overview

This application provides both manual and automated trading capabilities for stock options through TastyTrade's API. Built with Ruby on Rails and modern web technologies, it offers real-time option chain data via Action Cable, automated trade scanning and execution through Active Job, portfolio management, and comprehensive risk controls.

### Key Features (Planned)

#### Manual Trading
- Real-time option chain visualization
- Order placement and management
- Portfolio tracking and P&L analysis
- Risk analysis tools
- Market data streaming

#### Automated Trading
- **Autonomous market scanning** - Continuously monitors markets for opportunities
- **Rule-based trade selection** - Applies filters from TRADING_RULES.md
- **Automatic trade execution** - Places orders without user intervention
- **Portfolio constraints enforcement** - Maintains delta/vega limits
- **Risk management** - Automated stop-loss and profit targets
- **Kill switch mechanism** - Emergency stop capabilities
- **Performance tracking** - Real-time metrics and reporting

## Technology Stack

- **Backend**: Ruby 3.2+ with Rails 7.1+
- **Web Framework**: Ruby on Rails
- **Real-time**: Action Cable for WebSocket support
- **Background Jobs**: Sidekiq for automated trading
- **Frontend**: Stimulus.js/Turbo (Hotwire) or React
- **API Integration**: TastyTrade API via Faraday
- **Database**: PostgreSQL with Active Record
- **Cache**: Redis for real-time data and Sidekiq
- **Deployment**: Docker containers

## Project Structure

```
tastytradesUI/
├── app/
│   ├── channels/         # Action Cable channels
│   ├── controllers/      # Rails controllers
│   ├── jobs/            # Active Job for automated trading
│   ├── models/          # Active Record models
│   ├── services/        # Business logic and API integration
│   ├── views/           # Rails views
│   └── javascript/      # Stimulus controllers
├── config/              # Rails configuration
├── db/                  # Database migrations and schema
├── lib/
│   ├── tastytrade/      # TastyTrade API client
│   └── trading/         # Trading engine and strategies
├── spec/                # RSpec test suite
├── docs/                # Additional documentation
└── Gemfile              # Ruby dependencies
```

## Getting Started

### Prerequisites
- Ruby 3.2 or higher
- Rails 7.1 or higher
- PostgreSQL 14+
- Redis 7+
- TastyTrade account with API access
- Git

### Installation

1. Clone the repository:
```bash
git clone https://github.com/rorystouder/tastytradesUI.git
cd tastytradesUI
```

2. Install Ruby dependencies:
```bash
bundle install
```

3. Install JavaScript dependencies:
```bash
yarn install
```

4. Setup database:
```bash
rails db:create
rails db:migrate
```

5. Configure API credentials:
```bash
# Rails 7.1+ uses encrypted credentials
EDITOR="code --wait" rails credentials:edit

# Add your TastyTrade credentials:
# tastytrade:
#   client_id: your_client_id
#   client_secret: your_secret
#   api_url: https://api.tastyworks.com
```

6. Configure automated trading (optional):
```bash
# In config/application.yml or .env
AUTO_TRADING_ENABLED=true
PAPER_TRADING=true  # Start with paper trading
```

7. Start Redis:
```bash
redis-server
```

8. Start Sidekiq (in another terminal):
```bash
bundle exec sidekiq
```

9. Run the application:
```bash
rails server
```

### Automated Trading Setup

To enable automated trading:
1. Review [TRADING_RULES.md](docs/guides/TRADING_RULES.md) for selection criteria
2. Configure risk limits in `.env` file
3. Start with `PAPER_TRADING=true` for testing
4. Monitor via the web dashboard
5. Review [AUTOMATED_TRADING.md](docs/guides/AUTOMATED_TRADING.md) for details

## Documentation

- [Development Guidelines](docs/development/DEVELOPMENT.md) - Coding standards and development workflow
- [Architecture](docs/architecture/ARCHITECTURE.md) - System design and component overview
- [API Integration](docs/api/API_INTEGRATION.md) - TastyTrade API usage guide
- [Claude Rules](docs/development/CLAUDE.md) - AI assistant guidelines
- [Trading Rules](docs/guides/TRADING_RULES.md) - Stock option picking and trading criteria
- [Automated Trading](docs/guides/AUTOMATED_TRADING.md) - Autonomous trading system documentation

## Contributing

Please read [DEVELOPMENT.md](docs/development/DEVELOPMENT.md) for details on our code of conduct and the process for submitting pull requests.

## Security

- Never commit API credentials or sensitive data
- Use environment variables for configuration
- Follow security best practices outlined in [DEVELOPMENT.md](docs/development/DEVELOPMENT.md)

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Disclaimer

This software is for educational and personal use only. Trading options involves substantial risk of loss and is not suitable for all investors. Past performance is not indicative of future results.