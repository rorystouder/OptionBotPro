# Deploy to Heroku - Works 100% with Rails

Heroku is the original Rails platform and works perfectly. Here's how to deploy in 5 minutes:

## Step 1: Install Heroku CLI

### On Windows (WSL/Ubuntu):
```bash
curl https://cli-assets.heroku.com/install-ubuntu.sh | sh
```

### On Mac:
```bash
brew tap heroku/brew && brew install heroku
```

## Step 2: Create Heroku Account (Free)
Visit: https://signup.heroku.com/

## Step 3: Deploy Your App

```bash
# Login to Heroku
heroku login

# Create your app
heroku create optionbotpro

# Deploy
git push heroku main

# Set your master key
heroku config:set RAILS_MASTER_KEY=$(cat config/master.key)

# Run database migrations
heroku run rails db:migrate

# Open your app
heroku open
```

## Your App Will Be Live At:
https://optionbotpro.herokuapp.com

## Add-ons You'll Need (All have free tiers):

### For Background Jobs (Required):
```bash
# Add Redis for Sidekiq
heroku addons:create heroku-redis:mini

# Add scheduler for cron jobs
heroku addons:create scheduler:standard
```

### For Production Database (Optional - can stick with SQLite):
```bash
# If you want PostgreSQL instead of SQLite
heroku addons:create heroku-postgresql:mini
```

## Set Environment Variables:
```bash
# TastyTrade credentials
heroku config:set TASTYTRADE_USERNAME=your-email@example.com
heroku config:set TASTYTRADE_PASSWORD=your-password
heroku config:set TASTYTRADE_API_URL=https://api.tastyworks.com

# SendGrid for emails (optional)
heroku config:set SENDGRID_API_KEY=your-key

# Admin credentials
heroku config:set ADMIN_EMAIL=admin@optionbotpro.com
heroku config:set ADMIN_PASSWORD=SecurePassword123!
```

## Scale Your Dynos:
```bash
# Run web and worker processes
heroku ps:scale web=1 worker=1
```

## Monitor Logs:
```bash
heroku logs --tail
```

## Cost:
- **Eco Dyno**: $5/month (1000 hours)
- **Basic Dyno**: $7/month (always on)
- **Redis**: Free tier available
- **PostgreSQL**: Free tier available
- **Total**: $5-7/month to start

## Why Heroku Works When Others Don't:
1. **Invented buildpacks** - Rails support is perfect
2. **No Docker needed** - Uses native Ruby buildpack
3. **SQLite support** - Works out of the box
4. **Background jobs** - Native Sidekiq support
5. **Zero configuration** - Just push and it works

## Troubleshooting:

If you see any errors, run:
```bash
heroku logs --tail
```

Common fixes:
```bash
# If assets fail
heroku config:set RAILS_SERVE_STATIC_FILES=true

# If database fails
heroku run rails db:create db:migrate

# If gems fail
heroku buildpacks:set heroku/ruby
```

## Done!
Your app is now live and working. No Docker, no complex configs, just Rails running perfectly.