# Environment Variables Setup

This guide helps you configure the environment variables needed for the OptionBotPro application.

## Step 1: Create Environment File

Copy the example environment file:

```bash
cp .env.example .env
```

## Step 2: Configure Database Credentials

Edit the `.env` file and set your database credentials:

```bash
nano .env
```

Update these values with the credentials from the previous step:

```env
# Database Configuration
DATABASE_USERNAME=rails
DATABASE_PASSWORD=your_secure_password_here
DATABASE_HOST=localhost
DATABASE_PORT=5432
```

## Step 3: Generate Rails Secret Key

Generate a secret key for Rails:

```bash
rails secret
```

Copy the generated key and add it to your `.env` file:

```env
# Rails Configuration
SECRET_KEY_BASE=paste_the_generated_secret_here
```

## Step 4: TastyTrade API Configuration

You'll need to obtain TastyTrade API credentials. For now, add placeholder values:

```env
# TastyTrade API Configuration
TASTYTRADE_CLIENT_ID=your_client_id_here
TASTYTRADE_CLIENT_SECRET=your_client_secret_here
TASTYTRADE_API_URL=https://api.tastyworks.com
TASTYTRADE_WEBSOCKET_URL=wss://streamer.tastyworks.com
```

**Note**: You'll update these with real credentials in step 5.

## Step 5: Redis Configuration

If Redis is running locally (default), keep these values:

```env
# Redis Configuration
REDIS_URL=redis://localhost:6379/0
```

### Install Redis (if not already installed)

#### Ubuntu/Debian:
```bash
sudo apt update
sudo apt install redis-server
sudo systemctl start redis-server
sudo systemctl enable redis-server
```

#### macOS (with Homebrew):
```bash
brew install redis
brew services start redis
```

#### Test Redis Connection:
```bash
redis-cli ping
```
You should see `PONG` as response.

## Step 6: Additional Configuration

Add these additional settings to your `.env` file:

```env
# Application Settings
RAILS_ENV=development
RAILS_LOG_TO_STDOUT=true
RAILS_MAX_THREADS=5

# Sidekiq Configuration
SIDEKIQ_CONCURRENCY=10
```

## Step 7: Complete .env File Example

Your complete `.env` file should look like this:

```env
# TastyTrade API Configuration
TASTYTRADE_CLIENT_ID=your_client_id_here
TASTYTRADE_CLIENT_SECRET=your_client_secret_here
TASTYTRADE_API_URL=https://api.tastyworks.com
TASTYTRADE_WEBSOCKET_URL=wss://streamer.tastyworks.com

# Database Configuration
DATABASE_USERNAME=rails
DATABASE_PASSWORD=your_secure_password_here
DATABASE_HOST=localhost
DATABASE_PORT=5432

# Redis Configuration
REDIS_URL=redis://localhost:6379/0

# Rails Configuration
SECRET_KEY_BASE=your_generated_secret_key_here
RAILS_ENV=development
RAILS_LOG_TO_STDOUT=true
RAILS_MAX_THREADS=5

# Sidekiq Configuration
SIDEKIQ_CONCURRENCY=10
```

## Step 8: Verify Environment Loading

Test that Rails can load your environment variables:

```bash
rails runner "puts ENV['DATABASE_USERNAME']"
```

This should output `rails` if configured correctly.

## Security Notes

- **Never commit the `.env` file to version control**
- The `.env` file is already in `.gitignore`
- Use strong, unique passwords
- Keep your secret key secure

## Troubleshooting

### Environment Variables Not Loading

If environment variables aren't loading:

1. Verify the `.env` file is in the project root
2. Check for syntax errors in the `.env` file
3. Restart your Rails server after changes

### Secret Key Issues

If you get secret key errors:

```bash
# Generate a new secret
rails secret

# Or use this temporary command for development
export SECRET_KEY_BASE=$(rails secret)
```

## Verification

Before proceeding to the next step, verify:

- [ ] `.env` file exists and is configured
- [ ] Database credentials are set
- [ ] SECRET_KEY_BASE is generated and set
- [ ] Redis is running and accessible
- [ ] Rails can load environment variables

## Next Step

Continue to [Gem Installation](./03-gem-installation.md)