#!/bin/bash

echo "🚀 Starting TastyTrades UI Application..."
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found!"
    echo "Please copy .env.example to .env and configure your settings"
    exit 1
fi

# Check if gems are installed
if [ ! -d vendor/bundle ]; then
    echo "📦 Installing gems..."
    bundle install
fi

# Check if database exists
if [ ! -f storage/development.sqlite3 ]; then
    echo "🗄️  Creating database..."
    bundle exec rails db:create
    bundle exec rails db:migrate
else
    echo "✅ Database exists"
fi

# Start Redis if installed (for caching)
if command -v redis-server &> /dev/null; then
    echo "🔴 Starting Redis in background..."
    redis-server --daemonize yes
else
    echo "⚠️  Redis not found - caching will use memory"
fi

echo ""
echo "🌐 Starting Rails server..."
echo "➡️  Application will be available at: http://localhost:3000"
echo "➡️  Press Ctrl+C to stop the server"
echo ""

# Start Rails server
bundle exec rails server --port=3000