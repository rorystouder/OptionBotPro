# Render.com Deployment Guide - EXACT STEPS

## Why Render Failed
Render failed silently because it was missing the `RAILS_MASTER_KEY` environment variable. Without it, Rails can't decrypt credentials and fails to start.

## Step-by-Step Deployment to Render

### 1. Go to Render Dashboard
https://dashboard.render.com

### 2. Create New Web Service
- Click "New +" → "Web Service"
- Connect your GitHub repository
- Select branch: `main`

### 3. Configure Build Settings (EXACT VALUES)
- **Name**: `optionbotpro`
- **Region**: Oregon (US West 1)
- **Branch**: `main`
- **Runtime**: `Ruby`
- **Build Command**: `bundle install; bundle exec rails assets:precompile; bundle exec rails db:migrate`
- **Start Command**: `bundle exec puma -C config/puma.rb`
- **Instance Type**: Free

### 4. Add Environment Variables (CRITICAL!)
Click "Advanced" and add these EXACT environment variables:

```
RAILS_MASTER_KEY=f0ba9719f1b640c7557048389e3f254e
RAILS_ENV=production
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
SECRET_KEY_BASE=50df9ebac297d916792751d674f88078a32cd646fd9f00cdc7f684c2aada8a204ec25c213613fba65354cfbf08d97d3eef61e0cd843c1aa3a80a2883f9abde72
DATABASE_URL=sqlite3:///opt/render/project/src/storage/production.sqlite3
```

### 5. Deploy
Click "Create Web Service"

### 6. Monitor the Build
Watch the logs for:
```
==> Installing dependencies via Bundler
==> Precompiling assets
==> Running migrations
==> Starting puma
==> Your service is live 🎉
```

## If It Still Fails

### Check Logs
In Render dashboard → Logs tab, look for:
- "Missing `secret_key_base`" → Add SECRET_KEY_BASE env var
- "Missing master key" → Add RAILS_MASTER_KEY env var
- "Database not found" → DATABASE_URL is wrong
- Silent failure → Usually missing env vars

### Alternative Start Commands to Try
If puma fails, try these start commands:
1. `bundle exec rails server -b 0.0.0.0 -p $PORT`
2. `bundle exec puma -p $PORT`
3. `bin/rails server -b 0.0.0.0 -p $PORT`

### Test Locally First
```bash
export RAILS_ENV=production
export RAILS_MASTER_KEY=f0ba9719f1b640c7557048389e3f254e
export SECRET_KEY_BASE=50df9ebac297d916792751d674f88078a32cd646fd9f00cdc7f684c2aada8a204ec25c213613fba65354cfbf08d97d3eef61e0cd843c1aa3a80a2883f9abde72
bundle exec rails assets:precompile
bundle exec rails db:create db:migrate
bundle exec rails server -b 0.0.0.0 -p 3000
```

If it works locally, it will work on Render with the same env vars.

## Common Issues and Fixes

1. **"We're sorry, but something went wrong"**
   - Missing RAILS_MASTER_KEY
   - Wrong DATABASE_URL path

2. **Build succeeds but app doesn't respond**
   - Wrong start command
   - Port binding issue (must use $PORT)

3. **"ActionView::Template::Error"**
   - Assets not precompiled
   - Add to build command: `bundle exec rails assets:precompile`

4. **"ActiveRecord::ConnectionNotEstablished"**
   - DATABASE_URL not set correctly
   - For SQLite: `sqlite3:///opt/render/project/src/storage/production.sqlite3`

## Success Indicators
Your app is working when you see:
- Green "Live" status in Render dashboard
- Logs show: "Listening on http://0.0.0.0:10000"
- Your URL loads without errors

## Your App URL
Once deployed: `https://optionbotpro.onrender.com`

## Still Having Issues?

The app works locally in production mode, so it's definitely an environment variable issue on Render. Double-check:
1. All env vars are set correctly (copy-paste from above)
2. Build command includes asset precompilation
3. Start command uses bundle exec

If Render still fails, use Heroku - it's more forgiving with Rails apps.