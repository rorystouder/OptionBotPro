# Fix Railway Auto-Deploy Issues

Railway keeps auto-building with Docker and failing. Here's how to fix it:

## Step 1: Disable Auto-Deploy in Railway Dashboard

1. Go to your Railway project dashboard
2. Click on your service
3. Go to **Settings** tab
4. Scroll to **Source Repo**
5. **Uncheck "Auto Deploy"** (temporarily)
6. Save settings

## Step 2: Force Buildpack Mode

I've created these files to force Railway to use Heroku buildpacks instead of Docker:

- `railway.toml` - Forces Heroku builder
- `.railwayignore` - Ignores all Docker files
- Updated `package.json` - Node.js compatibility

## Step 3: Manual Deploy Test

In Railway dashboard:
1. Go to **Deployments** tab
2. Click **Deploy Now** button
3. Select your latest commit
4. Watch the build - should use buildpacks now

## Step 4: Set Environment Variables in Railway

In your Railway dashboard, add these environment variables:

```
RAILS_MASTER_KEY=<copy from config/master.key>
RAILS_ENV=production
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
BUNDLE_WITHOUT=development test
DATABASE_URL=sqlite3:///app/storage/production.sqlite3
```

## Step 5: Enable Auto-Deploy Again

Once manual deploy works:
1. Re-enable "Auto Deploy" in settings
2. Future commits will use buildpacks instead of Docker

## Alternative: Switch to Different Platform

If Railway keeps having issues, these platforms work perfectly:

### Heroku (Guaranteed Success):
```bash
heroku create optionbotpro
git push heroku main
heroku config:set RAILS_MASTER_KEY=$(cat config/master.key)
```

### Render.com (Free Option):
1. Connect GitHub repo
2. Auto-detects Rails
3. Works without configuration

## Expected Build Log (Success):

```
-----> Ruby app detected
-----> Installing bundler
-----> Installing dependencies via Bundler
-----> Precompiling assets
-----> Launching...
```

If you see Docker/Nixpacks errors, the platform is still using the wrong builder.

## Why This Happens:

Railway's auto-detection prioritizes Docker over buildpacks, but their Docker infrastructure has issues with:
- Experimental buildkit features
- Rails asset precompilation 
- Path resolution

The fix forces Railway to use proven Heroku buildpacks instead.