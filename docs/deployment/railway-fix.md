# Railway Deployment Fix

The Docker registry error you're experiencing is a common Railway issue. Here are three solutions:

## Solution 1: Use Railway CLI (Recommended)
Instead of deploying through the web UI, use the CLI which handles builds better:

```bash
# Install Railway CLI if not already installed
curl -fsSL https://railway.app/install.sh | sh

# Login
railway login

# Link your project (in your project directory)
cd /home/rorystouder/projects/tastytradesUI
railway link

# Deploy directly (this bypasses Docker registry issues)
railway up
```

## Solution 2: Try Render.com Instead
Given the Railway issue, Render might be more stable:

```bash
# 1. Go to https://render.com
# 2. Click "New +" → "Web Service"
# 3. Connect your GitHub repo
# 4. Use these settings:
#    - Environment: Ruby
#    - Build Command: bundle install && bundle exec rails assets:precompile
#    - Start Command: bundle exec rails db:migrate && bundle exec rails server -b 0.0.0.0 -p $PORT
# 5. Add environment variables:
#    - RAILS_MASTER_KEY (from config/master.key)
#    - DATABASE_URL=sqlite3:///data/production.sqlite3
# 6. Add a disk at /data path (10GB)
```

## Solution 3: Fix Railway Build

### Option A: Clear Railway cache and retry
```bash
# In Railway dashboard:
# 1. Go to Settings → Advanced
# 2. Click "Clear Build Cache"
# 3. Redeploy
```

### Option B: Use custom Dockerfile
Create a `Dockerfile` in your project root:

```dockerfile
FROM ruby:3.2.0-slim

RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libsqlite3-dev \
    nodejs \
    yarn \
    git \
    curl

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

RUN bundle exec rails assets:precompile
RUN bundle exec rails db:create db:migrate

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
```

Then push to GitHub and Railway will use this Dockerfile.

## Quick Alternative: Deploy to Fly.io
Fly.io is very reliable for Rails apps:

```bash
# Install Fly CLI
curl -L https://fly.io/install.sh | sh

# Launch (this auto-detects Rails)
fly launch

# Say yes to:
# - Copy configuration? Yes
# - PostgreSQL? No (we're using SQLite)
# - Redis? No (optional)

# Deploy
fly deploy

# Open your app
fly open
```

## Why This Error Happens
- Docker Hub rate limiting
- Network timeout during large image pulls
- Railway's build system trying to pull Ruby base image

## Files I've Added to Help:
1. **nixpacks.toml** - Tells Railway to use Nixpacks (avoids Docker)
2. **.buildpacks** - Alternative build system
3. **.node-version** - Ensures Node.js compatibility
4. **Fixed .ruby-version** - Was 3.2.3, now matches Gemfile (3.2.0)

Try the Railway CLI method first - it usually works when the web UI fails!