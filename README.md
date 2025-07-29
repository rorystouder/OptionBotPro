# TastyTrades Option Trader UI

A Python-based stock option trading application with a local web interface that integrates with the TastyTrade API.

## Project Overview

This application provides a user-friendly web interface for trading stock options through TastyTrade's API. Built with Python and modern web technologies, it offers real-time option chain data, trading capabilities, and portfolio management features.

### Key Features (Planned)
- Real-time option chain visualization
- Order placement and management
- Portfolio tracking and P&L analysis
- Risk analysis tools
- Strategy builder and backtesting
- Automated trading capabilities
- Market data streaming

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

5. Run the application:
```bash
python src/main.py
```

## Documentation

- [Development Guidelines](docs/development/DEVELOPMENT.md) - Coding standards and development workflow
- [Architecture](docs/architecture/ARCHITECTURE.md) - System design and component overview
- [API Integration](docs/api/API_INTEGRATION.md) - TastyTrade API usage guide
- [Claude Rules](docs/development/CLAUDE.md) - AI assistant guidelines

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