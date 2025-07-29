# TastyTrades Option Trader UI

A Python-based automated stock option trading application with a local web interface that integrates with the TastyTrade API. The system features autonomous trading capabilities that scan markets and execute trades based on predefined rules without user intervention.

## Project Overview

This application provides both manual and automated trading capabilities for stock options through TastyTrade's API. Built with Python and modern web technologies, it offers real-time option chain data, automated trade scanning and execution, portfolio management, and comprehensive risk controls.

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

- **Backend**: Python 3.9+
- **Web Framework**: FastAPI or Flask (TBD)
- **Frontend**: React/Vue.js with WebSocket support
- **API Integration**: TastyTrade API
- **Database**: PostgreSQL/SQLite for local data storage
- **Message Queue**: Redis for real-time updates
- **Deployment**: Docker containers

## Project Structure

```
tastytradesUI/
├── src/
│   ├── api/              # TastyTrade API integration
│   ├── core/             # Core business logic
│   ├── web/              # Web interface backend
│   ├── static/           # Frontend assets
│   └── utils/            # Helper utilities
├── tests/                # Test suite
├── docs/                 # Additional documentation
├── config/               # Configuration files
└── requirements/         # Python dependencies
```

## Getting Started

### Prerequisites
- Python 3.9 or higher
- TastyTrade account with API access
- Git

### Installation

1. Clone the repository:
```bash
git clone https://github.com/rorystouder/tastytradesUI.git
cd tastytradesUI
```

2. Create a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Configure API credentials:
```bash
cp config/example.env .env
# Edit .env with your TastyTrade API credentials
```

5. Configure automated trading (optional):
```bash
# Enable automated trading in .env
AUTO_TRADING_ENABLED=true
PAPER_TRADING=true  # Start with paper trading
```

6. Run the application:
```bash
python src/main.py
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