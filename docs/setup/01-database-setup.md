# Database Setup

This guide helps you set up PostgreSQL database for the OptionBotPro application.

## Step 1: Install PostgreSQL (if not already installed)

### Ubuntu/Debian:
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
```

### macOS (with Homebrew):
```bash
brew install postgresql
brew services start postgresql
```

### Windows:
Download and install from: https://www.postgresql.org/download/windows/

## Step 2: Create Database User

Connect to PostgreSQL as the postgres user:

```bash
sudo -u postgres psql
```

Create a user for your Rails application:

```sql
CREATE USER rails WITH PASSWORD 'your_secure_password_here';
ALTER USER rails CREATEDB;
\q
```

**Important**: Replace `your_secure_password_here` with a strong password and remember it for the next step.

## Step 3: Create Databases

Create the development and test databases:

```bash
sudo -u postgres createdb -O rails tastytrades_development
sudo -u postgres createdb -O rails tastytrades_test
```

## Step 4: Test Database Connection

Test that you can connect to the database:

```bash
psql -h localhost -U rails -d tastytrades_development -W
```

You should be prompted for the password you created in Step 2. If successful, you'll see the PostgreSQL prompt.

Type `\q` to quit.

## Step 5: Configure Database Credentials

The database configuration is already set up in `config/database.yml`. You'll need to set the environment variables in the next setup step.

## Troubleshooting

### Connection Issues

If you get "peer authentication failed":

1. Edit the PostgreSQL config file:
   ```bash
   sudo nano /etc/postgresql/*/main/pg_hba.conf
   ```

2. Find the line that says:
   ```
   local   all             all                                     peer
   ```

3. Change it to:
   ```
   local   all             all                                     md5
   ```

4. Restart PostgreSQL:
   ```bash
   sudo systemctl restart postgresql
   ```

### Permission Issues

If you get permission denied errors:

```bash
sudo -u postgres psql
ALTER USER rails WITH SUPERUSER;
\q
```

### Database Already Exists

If databases already exist, you can drop and recreate them:

```bash
sudo -u postgres dropdb tastytrades_development
sudo -u postgres dropdb tastytrades_test
sudo -u postgres createdb -O rails tastytrades_development
sudo -u postgres createdb -O rails tastytrades_test
```

## Verification

Before proceeding to the next step, verify:

- [ ] PostgreSQL is running
- [ ] Rails user exists with correct permissions
- [ ] Development and test databases exist
- [ ] You can connect to the databases

## Next Step

Continue to [Environment Variables Setup](./02-environment-setup.md)