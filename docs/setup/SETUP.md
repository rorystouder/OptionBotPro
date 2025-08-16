# OptionBotPro Setup Guide

This guide walks you through all the manual operations needed to get the OptionBotPro application running.

## Prerequisites

- Ruby 3.2.3 (already installed)
- PostgreSQL database
- Redis server
- TastyTrade API credentials

## Quick Start

Follow these setup files in order:

1. [Database Setup](./docs/setup/01-database-setup.md) - PostgreSQL database configuration
2. [Environment Variables](./docs/setup/02-environment-setup.md) - Configure API keys and secrets
3. [Gem Installation](./docs/setup/03-gem-installation.md) - Install Ruby dependencies
4. [Database Migration](./docs/setup/04-database-migration.md) - Create database schema
5. [TastyTrade API Setup](./docs/setup/05-tastytrade-setup.md) - Configure API credentials
6. [Testing Setup](./docs/setup/06-testing-setup.md) - Verify everything works
7. [Risk Management Setup](./docs/setup/08-risk-management-setup.md) - Configure portfolio protection
8. [Optional: Views Setup](./docs/setup/07-views-setup.md) - Create basic web interface

## Directory Structure

After setup, your application will have:

```
OptionBotPro/
├── app/
│   ├── controllers/         # API and web controllers
│   ├── models/             # User, Order, Position models
│   ├── services/           # TastyTrade API integration
│   └── views/              # Web interface (to be created)
├── config/
│   ├── database.yml        # PostgreSQL configuration
│   └── routes.rb           # API and web routes
├── db/
│   └── migrate/            # Database migrations
├── docs/                   # Project documentation
│   ├── setup/              # Setup instruction files
│   ├── guides/             # Trading rules and guides
│   ├── architecture/       # System architecture docs
│   ├── api/                # API integration docs
│   └── development/        # Development guidelines
├── .env                    # Environment variables (you create)
└── .env.example           # Environment template
```

## Support

If you encounter issues during setup:

1. Check the logs: `tail -f log/development.log`
2. Verify database connection: `rails db:version`
3. Test API connectivity: Use the testing commands in setup files
4. Review the troubleshooting section in each setup file

## Security Notes

- Never commit `.env` files to version control
- Use strong passwords for database and application
- Rotate TastyTrade API credentials regularly
- Keep your PostgreSQL and Redis instances secure

## Next Steps After Setup

Once setup is complete, you can:

- Access the API at `http://localhost:3000/api/v1/`
- View the dashboard at `http://localhost:3000/dashboard`
- Start developing trading strategies
- Add automated trading features
- Implement real-time market data streaming

For development guidelines, see the [docs/development/DEVELOPMENT.md](./docs/development/DEVELOPMENT.md) file.