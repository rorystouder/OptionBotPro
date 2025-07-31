# Gem Installation

This guide helps you install all Ruby gems required for the OptionBotPro application.

## Step 1: Fix Gem Version Conflicts

We encountered some version conflicts during development. Let's fix the Gemfile first:

### Update SQLite Gem

Since we're using PostgreSQL, remove the SQLite gem:

```bash
# Edit Gemfile and remove or comment out this line:
# gem "sqlite3", ">= 2.1"
```

Or run this command to comment it out:

```bash
sed -i 's/^gem "sqlite3"/# gem "sqlite3"/' Gemfile
```

## Step 2: Bundle Configuration

Configure Bundler to install gems locally to avoid permission issues:

```bash
bundle config set --local path 'vendor/bundle'
bundle config set --local without 'production'
```

## Step 3: Install Gems

Install all gems:

```bash
bundle install
```

### If You Encounter Permission Errors

If you still get permission errors, try:

```bash
# Install gems to local vendor directory
bundle install --path vendor/bundle

# Or install with user permissions
bundle install --user-install
```

### If You Get Version Conflicts

If you encounter Kamal/dotenv version conflicts:

```bash
# Remove kamal temporarily if not needed for deployment
sed -i 's/^gem "kamal"/# gem "kamal"/' Gemfile
bundle install
```

## Step 4: Verify Gem Installation

Check that key gems are installed:

```bash
bundle exec rails -v
bundle exec pg --version
bundle exec redis-cli --version
```

## Step 5: Install System Dependencies

Some gems require system dependencies:

### For PostgreSQL gem (pg):

#### Ubuntu/Debian:
```bash
sudo apt-get install libpq-dev
```

#### macOS:
```bash
brew install postgresql
```

### For Redis gem:

#### Ubuntu/Debian:
```bash
sudo apt-get install redis-server
```

#### macOS:
```bash
brew install redis
```

### For EventMachine (for faye-websocket):

#### Ubuntu/Debian:
```bash
sudo apt-get install build-essential
```

## Step 6: Reinstall Gems with Native Extensions

If you had issues with native extensions, reinstall them:

```bash
bundle pristine pg
bundle pristine eventmachine
bundle pristine faye-websocket
```

## Step 7: Verify Critical Gems

Test that critical gems are working:

```bash
# Test PostgreSQL connection
bundle exec rails runner "puts ActiveRecord::Base.connection.adapter_name"

# Test Redis connection  
bundle exec rails runner "puts Redis.new.ping"

# Test HTTParty
bundle exec rails runner "puts HTTParty.get('https://httpbin.org/ip')"
```

## Step 8: Generate Gemfile.lock

Ensure you have a proper Gemfile.lock:

```bash
bundle lock
```

## Troubleshooting

### Bundle Install Fails

If `bundle install` completely fails:

1. **Clear bundle cache:**
   ```bash
   bundle clean --force
   rm -rf vendor/bundle
   rm Gemfile.lock
   ```

2. **Install gems one by one:**
   ```bash
   # Install core Rails gems first
   gem install rails -v 8.0.2
   gem install pg
   gem install redis
   
   # Then try bundle install again
   bundle install
   ```

### Native Extension Compilation Errors

For native extension errors:

```bash
# Install development tools
sudo apt-get install build-essential libssl-dev libreadline-dev

# Or on macOS
xcode-select --install
```

### Permission Denied Errors

If you get permission errors:

```bash
# Use rbenv or rvm if available
rbenv rehash

# Or install to user directory
gem install --user-install bundler
```

### Missing System Libraries

For missing library errors:

#### Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install -y \
  build-essential \
  libpq-dev \
  libssl-dev \
  libreadline-dev \
  libyaml-dev \
  libxml2-dev \
  libxslt1-dev \
  libcurl4-openssl-dev \
  libffi-dev
```

#### macOS:
```bash
brew install openssl readline libyaml libxml2 libxslt libffi
```

## Alternative: Manual Gem Installation

If bundle install continues to fail, install gems manually:

```bash
# Core gems
gem install rails -v 8.0.2
gem install pg -v 1.6.0
gem install redis -v 5.4.1
gem install httparty -v 0.23.1
gem install sidekiq -v 7.3.9

# Authentication & validation
gem install bcrypt -v 3.1.20
gem install aasm -v 5.5.1
gem install dry-validation -v 1.11.1

# Testing gems
gem install rspec-rails -v 6.1.5
gem install factory_bot_rails -v 6.5.0
gem install webmock -v 3.25.1

# Then create Gemfile.lock
bundle lock
```

## Verification

Before proceeding to the next step, verify:

- [ ] `bundle install` completes successfully
- [ ] All critical gems are installed (rails, pg, redis, httparty)
- [ ] Native extensions compile without errors
- [ ] Gemfile.lock is generated
- [ ] No missing system dependencies

## Next Step

Continue to [Database Migration](./04-database-migration.md)