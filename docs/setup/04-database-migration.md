# Database Migration

This guide helps you create the database schema for the OptionBotPro application.

## Step 1: Verify Database Connection

First, ensure Rails can connect to your database:

```bash
bundle exec rails db:version
```

If this fails, go back to [Database Setup](./01-database-setup.md) and [Environment Setup](./02-environment-setup.md).

## Step 2: Create Databases

Create the development and test databases:

```bash
bundle exec rails db:create
```

You should see output like:
```
Created database 'tastytrades_development'
Created database 'tastytrades_test'
```

### If Databases Already Exist

If you get "database already exists" errors, that's fine. Continue to the next step.

### If Database Creation Fails

Check your database configuration:

```bash
# Test database connection
bundle exec rails runner "puts ActiveRecord::Base.connection.adapter_name"

# Check database configuration
bundle exec rails runner "puts Rails.application.config.database_configuration"
```

## Step 3: Run Database Migrations

Run all migrations to create the database schema:

```bash
bundle exec rails db:migrate
```

You should see output showing each migration being applied:

```
== 20250731000001 CreateUsers: migrating ======================================
-- create_table(:users)
-- add_index(:users, :email, {:unique=>true})
-- add_index(:users, :tastytrade_customer_id)
-- add_index(:users, :active)
== 20250731000001 CreateUsers: migrated (0.0123s) ============================

== 20250731000002 CreateOrders: migrating =====================================
-- create_table(:orders)
-- add_index(:orders, [:user_id, :status])
-- add_index(:orders, :symbol)
-- add_index(:orders, :tastytrade_order_id, {:unique=>true})
-- add_index(:orders, :status)
-- add_index(:orders, :created_at)
== 20250731000002 CreateOrders: migrated (0.0234s) ===========================

== 20250731000003 CreateOrderLegs: migrating ==================================
-- create_table(:order_legs)
-- add_index(:order_legs, [:order_id, :leg_number], {:unique=>true})
-- add_index(:order_legs, :symbol)
== 20250731000003 CreateOrderLegs: migrated (0.0145s) ========================

== 20250731000004 CreatePositions: migrating ==================================
-- create_table(:positions)
-- add_index(:positions, [:user_id, :symbol], {:unique=>true})
-- add_index(:positions, :symbol)
-- add_index(:positions, :tastytrade_account_id)
-- add_index(:positions, :last_updated_at)
== 20250731000004 CreatePositions: migrated (0.0156s) ========================
```

## Step 4: Verify Database Schema

Check that all tables were created:

```bash
bundle exec rails db:schema:dump
```

This creates `db/schema.rb`. Verify it contains your tables:

```bash
grep -E "(create_table|add_index)" db/schema.rb
```

## Step 5: Run Migrations for Test Database

Run migrations for the test environment:

```bash
bundle exec rails db:migrate RAILS_ENV=test
```

## Step 6: Verify Database Structure

Connect to your database and verify the structure:

```bash
# Connect to database
psql -h localhost -U rails -d tastytrades_development -W

# List all tables
\dt

# Describe users table
\d users

# Describe orders table  
\d orders

# Describe positions table
\d positions

# Describe order_legs table
\d order_legs

# Exit
\q
```

You should see all four tables with their columns and indexes.

## Step 7: Test Model Functionality

Test that your models work correctly:

```bash
bundle exec rails console
```

In the Rails console, test creating records:

```ruby
# Create a test user
user = User.new(
  email: "test@example.com",
  password: "password123",
  first_name: "Test",
  last_name: "User",
  tastytrade_customer_id: "TEST123"
)
user.save!

# Verify user was created
User.count
User.first

# Test user relationships
user.orders.count
user.positions.count

# Exit console
exit
```

## Step 8: Create Database Seeds (Optional)

Create a seed file for development data:

```bash
cat > db/seeds.rb << 'EOF'
# Create a default admin user for development
unless Rails.env.production?
  admin = User.find_or_create_by(email: 'admin@tastytrades.local') do |user|
    user.password = 'admin123'
    user.first_name = 'Admin'
    user.last_name = 'User'
    user.tastytrade_customer_id = 'ADMIN001'
    user.active = true
  end
  
  puts "Created admin user: #{admin.email}" if admin.persisted?
end
EOF
```

Run the seeds:

```bash
bundle exec rails db:seed
```

## Troubleshooting

### Migration Fails with "relation already exists"

If migrations fail because tables already exist:

```bash
# Reset the database
bundle exec rails db:reset

# Or drop and recreate
bundle exec rails db:drop
bundle exec rails db:create
bundle exec rails db:migrate
```

### Database Connection Errors

If you get connection errors:

1. **Check PostgreSQL is running:**
   ```bash
   sudo systemctl status postgresql
   # or
   brew services list | grep postgresql
   ```

2. **Check database exists:**
   ```bash
   psql -h localhost -U rails -l
   ```

3. **Verify credentials in .env file**

### Permission Errors

If you get permission errors during migration:

```bash
# Connect as postgres user and grant permissions
sudo -u postgres psql
GRANT ALL PRIVILEGES ON DATABASE tastytrades_development TO rails;
GRANT ALL PRIVILEGES ON DATABASE tastytrades_test TO rails;
\q
```

### Foreign Key Constraint Errors

If you get foreign key errors during testing:

```bash
# Disable foreign key checks temporarily
bundle exec rails runner "ActiveRecord::Base.connection.disable_referential_integrity { User.delete_all; Order.delete_all; Position.delete_all; OrderLeg.delete_all }"
```

## Rollback Migrations (if needed)

If you need to rollback migrations:

```bash
# Rollback last migration
bundle exec rails db:rollback

# Rollback specific number of migrations
bundle exec rails db:rollback STEP=2

# Rollback to specific version
bundle exec rails db:migrate VERSION=20250731000001
```

## Verification

Before proceeding to the next step, verify:

- [ ] Database creation completed successfully
- [ ] All 4 migrations ran without errors
- [ ] Schema.rb file was generated
- [ ] Test database is also migrated
- [ ] You can connect to the database
- [ ] Models can create and query records
- [ ] All tables and indexes exist

## Next Step

Continue to [TastyTrade API Setup](./05-tastytrade-setup.md)