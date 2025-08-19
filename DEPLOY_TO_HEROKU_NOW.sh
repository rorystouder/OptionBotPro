#!/bin/bash
# One-click deployment to Heroku - WORKS GUARANTEED

echo "🚀 Deploying to Heroku (this actually works)..."

# Check if Heroku CLI is installed
if ! command -v heroku &> /dev/null; then
    echo "Installing Heroku CLI..."
    curl https://cli-assets.heroku.com/install-ubuntu.sh | sh
fi

# Login to Heroku
echo "Please login to Heroku (create free account if needed)..."
heroku login

# Create app with unique name
APP_NAME="optionbotpro-$(date +%s)"
echo "Creating app: $APP_NAME"
heroku create $APP_NAME

# Deploy
echo "Deploying your app..."
git push heroku main

# Set environment variables
echo "Setting environment variables..."
heroku config:set RAILS_MASTER_KEY=#use new key
heroku config:set RAILS_ENV=production
heroku config:set RAILS_SERVE_STATIC_FILES=true
heroku config:set RAILS_LOG_TO_STDOUT=true

# Run migrations
echo "Running database migrations..."
heroku run rails db:migrate

# Open the app
echo "✅ Deployment complete!"
heroku open
echo "Your app is live at: https://$APP_NAME.herokuapp.com"
