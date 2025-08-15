# OptionBotPro Deployment Guide

## Hosting Platform Comparison

### ❌ Vercel Cannot Host This App
Vercel is designed for static sites and serverless functions, not full Rails applications with:
- Background jobs (Sidekiq)
- WebSocket connections (Action Cable)
- Persistent SQLite database
- Session-based authentication

## Recommended Hosting Platforms

### 1. Railway.app (RECOMMENDED) ⭐
**Best for**: Quick deployment, minimal configuration
**Monthly Cost**: $20-50
**Uptime**: 99.9% SLA

#### Pros:
- One-click Rails deployment
- Built-in background worker support
- Automatic SSL certificates
- SQLite persistence with volumes
- WebSocket support out of the box
- Simple scaling controls

#### Deployment Steps:
```bash
# 1. Install Railway CLI
curl -fsSL https://railway.app/install.sh | sh

# 2. Login to Railway
railway login

# 3. Initialize project
railway init

# 4. Link to GitHub repo
railway link

# 5. Deploy
railway up

# 6. Add environment variables in dashboard
# - RAILS_MASTER_KEY (from config/master.key)
# - TASTYTRADE_USERNAME
# - TASTYTRADE_PASSWORD
# - SENDGRID_API_KEY

# 7. Create persistent volume for SQLite
railway volume create --mount /data

# 8. Deploy with volume
railway up
```

### 2. Render.com ⭐
**Best for**: Production reliability, auto-scaling
**Monthly Cost**: $25-85
**Uptime**: 99.95%

#### Deployment Steps:
```bash
# 1. Create account at render.com

# 2. Connect GitHub repository

# 3. Create new Web Service
# - Environment: Ruby
# - Build Command: bundle install && rails assets:precompile
# - Start Command: rails db:migrate && rails server -b 0.0.0.0 -p $PORT

# 4. Add persistent disk
# - Mount path: /data
# - Size: 10GB

# 5. Create background worker
# - Same repo
# - Start Command: bundle exec sidekiq

# 6. Add environment variables
# - RAILS_MASTER_KEY
# - DATABASE_URL=sqlite3:///data/production.sqlite3
# - All TastyTrade credentials
```

### 3. Fly.io
**Best for**: Global edge deployment, advanced control
**Monthly Cost**: $20-60
**Uptime**: 99.9%

#### Deployment Steps:
```bash
# 1. Install Fly CLI
curl -L https://fly.io/install.sh | sh

# 2. Login
fly auth login

# 3. Launch app
fly launch

# 4. Create volume for SQLite
fly volumes create data --size 10

# 5. Set secrets
fly secrets set RAILS_MASTER_KEY=<your-key>
fly secrets set TASTYTRADE_USERNAME=<username>
fly secrets set TASTYTRADE_PASSWORD=<password>

# 6. Deploy
fly deploy

# 7. Scale workers
fly scale count 2 --app optionbotpro
```

### 4. AWS EC2 (Advanced)
**Best for**: Complete control, enterprise features
**Monthly Cost**: $30-100
**Uptime**: 99.99%

#### Not Recommended Unless:
- You have DevOps experience
- Need specific compliance requirements
- Want complete infrastructure control

## Pre-Deployment Checklist

### 1. Environment Variables
Create a `.env.production` file (DO NOT commit):
```bash
RAILS_ENV=production
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
SECRET_KEY_BASE=<generate with: rails secret>
RAILS_MASTER_KEY=<from config/master.key>

# TastyTrade Credentials (Production)
TASTYTRADE_USERNAME=your-real-email@example.com
TASTYTRADE_PASSWORD=your-real-password
TASTYTRADE_API_URL=https://api.tastyworks.com

# SendGrid (for emails)
SENDGRID_API_KEY=your-sendgrid-key

# Admin credentials
ADMIN_EMAIL=admin@optionbotpro.com
ADMIN_PASSWORD=SecurePassword123!
```

### 2. Database Setup
```bash
# Ensure production database is ready
RAILS_ENV=production rails db:create
RAILS_ENV=production rails db:migrate
RAILS_ENV=production rails db:seed
```

### 3. Asset Compilation
```bash
# Precompile assets
RAILS_ENV=production rails assets:precompile
```

### 4. Security Checks
```bash
# Check for security vulnerabilities
bundle audit
rails credentials:edit
```

## Domain Configuration

### 1. Purchase Domain
Recommended registrars:
- Namecheap
- Google Domains
- Cloudflare

### 2. Configure DNS

#### For Railway:
```
Type: CNAME
Name: @
Value: <your-app>.up.railway.app
TTL: 3600
```

#### For Render:
```
Type: CNAME
Name: @
Value: <your-app>.onrender.com
TTL: 3600
```

#### For Fly.io:
```
Type: A
Name: @
Value: <fly-provided-ip>
TTL: 3600

Type: AAAA
Name: @
Value: <fly-provided-ipv6>
TTL: 3600
```

### 3. SSL Certificate
All recommended platforms provide automatic SSL certificates via Let's Encrypt.

## Post-Deployment Tasks

### 1. Verify Health Check
```bash
curl https://yourdomain.com/health
```

### 2. Test Critical Features
- [ ] User registration and login
- [ ] MFA setup and verification
- [ ] TastyTrade authentication
- [ ] Market scanner execution
- [ ] Order placement (in sandbox first!)
- [ ] Admin panel access
- [ ] Email notifications

### 3. Setup Monitoring

#### Uptime Monitoring
- UptimeRobot (free)
- Pingdom
- StatusCake

#### Error Tracking
Add to `Gemfile`:
```ruby
gem 'sentry-ruby'
gem 'sentry-rails'
```

Configure in `config/initializers/sentry.rb`:
```ruby
Sentry.init do |config|
  config.dsn = ENV['SENTRY_DSN']
  config.breadcrumbs_logger = [:active_support_logger]
  config.traces_sample_rate = 0.1
end
```

### 4. Configure Backups

#### For SQLite on Railway/Render:
```bash
# Create backup script
#!/bin/bash
# backup.sh
DATE=$(date +%Y%m%d_%H%M%S)
sqlite3 /data/production.sqlite3 ".backup /data/backups/backup_$DATE.db"

# Keep only last 7 days
find /data/backups -name "backup_*.db" -mtime +7 -delete
```

Add to crontab:
```
0 2 * * * /app/backup.sh
```

## Scaling Considerations

### When to Scale Up:
- Response times > 500ms consistently
- Memory usage > 80%
- Background job queue > 100 jobs
- Daily active users > 100

### Scaling Options:

#### Railway:
```bash
# Increase resources in dashboard
# Or use CLI:
railway scale --memory 2GB --cpu 2
```

#### Render:
- Upgrade plan in dashboard
- Enable auto-scaling

#### Fly.io:
```bash
fly scale memory 1024
fly scale count 3  # Horizontal scaling
```

## Troubleshooting

### Common Issues:

#### 1. "Database is locked" (SQLite)
**Solution**: Implement database connection pooling
```ruby
# config/database.yml
production:
  adapter: sqlite3
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000
  database: /data/production.sqlite3
```

#### 2. Sidekiq jobs not running
**Solution**: Ensure worker process is running
```bash
# Check worker logs
railway logs --service worker
# or
fly logs --app optionbotpro-worker
```

#### 3. Assets not loading
**Solution**: Set environment variable
```bash
RAILS_SERVE_STATIC_FILES=true
```

#### 4. WebSocket connection failed
**Solution**: Ensure Action Cable is configured
```ruby
# config/environments/production.rb
config.action_cable.allowed_request_origins = [
  'https://yourdomain.com',
  /https:\/\/.*\.yourdomain\.com/
]
```

## Security Best Practices

1. **Use Strong Secrets**
```bash
rails secret  # Generate new secret
```

2. **Enable Force SSL**
```ruby
# config/environments/production.rb
config.force_ssl = true
```

3. **Configure CORS**
```ruby
# Gemfile
gem 'rack-cors'

# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'yourdomain.com'
    resource '*', headers: :any, methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
```

4. **Rate Limiting**
```ruby
# Gemfile
gem 'rack-attack'

# config/initializers/rack_attack.rb
Rack::Attack.throttle('req/ip', limit: 100, period: 1.minute) do |req|
  req.ip
end
```

## Recommended Deployment Path

### For Quick Launch (This Week):
1. **Use Railway.app** - Fastest to deploy
2. Set up domain and SSL
3. Configure monitoring with UptimeRobot
4. Test thoroughly in production

### For Scale (Next Month):
1. Migrate to **Render.com** or **Fly.io**
2. Implement Redis for caching
3. Add CDN (Cloudflare)
4. Upgrade to PostgreSQL if needed

## Cost Optimization

### Monthly Budget Estimate:
- **Hosting**: $25-50 (Railway/Render)
- **Domain**: $1 (amortized yearly cost)
- **Monitoring**: $0 (free tier)
- **Email**: $0-25 (SendGrid free/starter)
- **Error Tracking**: $0 (Sentry free tier)
- **Total**: ~$26-76/month

### When to Upgrade:
- > 100 daily active users
- > 1000 trades/day
- Need guaranteed uptime SLA
- Require phone support

## Support Resources

### Platform Documentation:
- [Railway Docs](https://docs.railway.app)
- [Render Docs](https://render.com/docs)
- [Fly.io Docs](https://fly.io/docs)

### Getting Help:
- Railway Discord: https://discord.gg/railway
- Render Community: https://community.render.com
- Fly.io Forum: https://community.fly.io

---

## Quick Start Commands

### Railway (Fastest):
```bash
# Complete deployment in 5 minutes
railway login
railway init
railway up
railway domain
```

### Your app will be live at:
- https://optionbotpro.up.railway.app (temporary)
- https://yourdomain.com (after DNS setup)

---

*Last Updated: January 2025*
*Next Review: After first deployment*