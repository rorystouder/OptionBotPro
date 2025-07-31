# OptionBotPro Database Management Guide

This guide covers database management for the OptionBotPro application, including built-in tools and external SQLite utilities.

## Built-in Database Management (Recommended)

OptionBotPro includes a comprehensive database management interface accessible through the admin panel.

### Accessing Database Management

1. **Login as Admin**
   - Email: `admin@optionbotpro.com`
   - Password: Your secure admin password

2. **Navigate to Database Section**
   - Admin Panel → Database (in navigation bar)
   - URL: `http://localhost:3000/admin/database`

### Features Available

#### 1. Database Overview
- **Database Information**: File path, size, last modified
- **Table List**: All tables with row counts and associated models
- **Quick Stats**: Total tables, records, models, and database size

#### 2. Table Management
- **View Data**: Browse table contents with pagination
- **Column Information**: Data types, constraints, defaults
- **Schema Details**: Full table structure with SQLite PRAGMA info

#### 3. SQL Query Tool
- **Secure SELECT Queries**: Execute read-only queries safely
- **Query Examples**: Pre-built common queries
- **Performance Timing**: Execution time monitoring
- **Result Export**: Copy/download query results

#### 4. Security Features
- **Read-Only Access**: Only SELECT statements allowed
- **Admin Authentication**: Requires admin privileges
- **Input Validation**: Prevents SQL injection
- **Error Handling**: Safe error reporting

## Database Schema Overview

### Core Tables

#### Users Table
```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_digest VARCHAR(255) NOT NULL,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  admin BOOLEAN DEFAULT FALSE,
  active BOOLEAN DEFAULT TRUE,
  subscription_tier_id INTEGER,
  subscription_status VARCHAR(20) DEFAULT 'trial',
  trial_ends_at DATETIME,
  subscription_ends_at DATETIME,
  encrypted_tastytrade_username TEXT,
  encrypted_tastytrade_password TEXT,
  tastytrade_credentials_iv VARCHAR(255),
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
);
```

#### Orders Table
```sql
CREATE TABLE orders (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  symbol VARCHAR(20) NOT NULL,
  quantity INTEGER NOT NULL,
  order_type VARCHAR(20) NOT NULL,
  status VARCHAR(20) DEFAULT 'pending',
  filled_quantity INTEGER DEFAULT 0,
  average_fill_price DECIMAL(10,4),
  tastytrade_order_id VARCHAR(50),
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

#### Positions Table
```sql
CREATE TABLE positions (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  symbol VARCHAR(20) NOT NULL,
  quantity INTEGER NOT NULL,
  average_price DECIMAL(10,4) NOT NULL,
  current_price DECIMAL(10,4),
  tastytrade_account_id VARCHAR(50) NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

#### Subscription Tiers Table
```sql
CREATE TABLE subscription_tiers (
  id INTEGER PRIMARY KEY,
  name VARCHAR(50) NOT NULL,
  monthly_price DECIMAL(8,2) NOT NULL,
  max_daily_trades INTEGER,
  max_trading_capital DECIMAL(12,2),
  features TEXT, -- JSON array of features
  active BOOLEAN DEFAULT TRUE,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
);
```

## External SQLite Tools (Optional)

If you prefer external database tools, here are recommended options:

### 1. DB Browser for SQLite (Free, GUI)

**Installation:**
```bash
# Ubuntu/Debian
sudo apt-get install sqlitebrowser

# macOS (via Homebrew)
brew install --cask db-browser-for-sqlite

# Windows
# Download from: https://sqlitebrowser.org/dl/
```

**Usage:**
1. Open DB Browser for SQLite
2. File → Open Database
3. Navigate to: `/home/rorystouder/projects/tastytradesUI/db/development.sqlite3`

**Features:**
- Visual table browser
- SQL query editor
- Schema designer
- Data import/export
- Full CRUD operations

### 2. SQLite Command Line (Pre-installed)

**Access Database:**
```bash
cd /home/rorystouder/projects/tastytradesUI
sqlite3 db/development.sqlite3
```

**Common Commands:**
```sql
-- List all tables
.tables

-- Show table schema
.schema users

-- Show table info
PRAGMA table_info(users);

-- Export table to CSV
.headers on
.mode csv
.output users.csv
SELECT * FROM users;
.quit
```

### 3. VSCode SQLite Extension

**Installation:**
1. Install "SQLite" extension by alexcvzz
2. Open VSCode in project directory
3. Press Ctrl+Shift+P → "SQLite: Open Database"
4. Select `db/development.sqlite3`

**Features:**
- Integrated database explorer
- Query execution
- Table browsing
- IntelliSense for SQL

### 4. TablePlus (Commercial, Multi-platform)

**Installation:**
```bash
# macOS
brew install --cask tableplus

# Windows/Linux: Download from https://tableplus.com/
```

**Connection:**
- Database Type: SQLite
- File: `/path/to/project/db/development.sqlite3`

## Database Backup & Maintenance

### Backup Database
```bash
# Create backup
cp db/development.sqlite3 db/backups/development_$(date +%Y%m%d_%H%M%S).sqlite3

# Automated backup script
sqlite3 db/development.sqlite3 ".backup db/backups/backup_$(date +%Y%m%d).sqlite3"
```

### Database Statistics
```sql
-- Database size and page info
PRAGMA page_count;
PRAGMA page_size;
PRAGMA freelist_count;

-- Table row counts
SELECT name, 
       (SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name=m.name) as row_count
FROM sqlite_master m 
WHERE type='table' AND name NOT LIKE 'sqlite_%';
```

### Vacuum Database (Cleanup)
```sql
-- Reclaim unused space and defragment
VACUUM;

-- Analyze query planner statistics
ANALYZE;
```

## Security Considerations

### Production Environment
- **Never expose database files** to public web directory
- **Use environment-specific databases** (development/production)
- **Regular backups** before major operations
- **Limited user permissions** on database files

### Query Safety
- **Always use parameterized queries** in application code
- **Validate input** before database operations  
- **Audit sensitive operations** (user data changes)
- **Monitor query performance** and optimize slow queries

## Troubleshooting

### Common Issues

#### Database Locked Error
```bash
# Check for processes using the database
lsof db/development.sqlite3

# Kill Rails server if needed
pkill -f "rails server"
```

#### Permission Issues
```bash
# Fix file permissions
chmod 664 db/development.sqlite3
chmod 775 db/
```

#### Corruption Recovery
```bash
# Check database integrity
sqlite3 db/development.sqlite3 "PRAGMA integrity_check;"

# Repair if needed
sqlite3 db/development.sqlite3 ".recover" | sqlite3 db/recovered.sqlite3
```

### Performance Optimization

#### Add Indexes for Common Queries
```sql
-- User email lookups
CREATE INDEX idx_users_email ON users(email);

-- User orders
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);

-- Position lookups
CREATE INDEX idx_positions_user_symbol ON positions(user_id, symbol);
```

#### Query Optimization
```sql
-- Use EXPLAIN QUERY PLAN to analyze queries
EXPLAIN QUERY PLAN SELECT * FROM users WHERE email = ?;

-- Monitor slow queries
.timer on
SELECT COUNT(*) FROM orders WHERE created_at > date('now', '-30 days');
```

## Integration with Rails

### Rails Console Database Operations
```ruby
# Access database directly
ActiveRecord::Base.connection.execute("SELECT sqlite_version()")

# Table information
ActiveRecord::Base.connection.tables
ActiveRecord::Base.connection.columns("users")

# Query with logging
User.connection.select_all("SELECT COUNT(*) as total FROM users")
```

### Database Migrations
```bash
# Create new migration
rails generate migration AddIndexToUsersEmail

# Run migrations
rails db:migrate

# Rollback migration
rails db:rollback

# Reset database (DANGER - deletes all data)
rails db:drop db:create db:migrate db:seed
```

## Best Practices

1. **Use Built-in Admin Tools** - Safer than external tools for production
2. **Regular Backups** - Before migrations, updates, or major changes
3. **Monitor Performance** - Watch for slow queries and growing database size
4. **Security First** - Never expose database credentials or files
5. **Test Migrations** - Always test database changes in development first
6. **Documentation** - Keep schema changes documented
7. **Indexing Strategy** - Add indexes for commonly queried columns

---

**Last Updated:** July 31, 2025  
**Database Version:** SQLite 3.x  
**Rails Version:** 8.0.2