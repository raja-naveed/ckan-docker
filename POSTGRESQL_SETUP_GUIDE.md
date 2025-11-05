# 📊 PostgreSQL Database Setup Guide for CKAN

This guide will help you set up PostgreSQL databases and users for CKAN on your existing `keycloak_postgres` container.

## 🎯 Prerequisites

- Docker installed and running
- `keycloak_postgres` container running
- Access to PostgreSQL superuser (usually `postgres`)

## 📋 Quick Setup (Automated Script)

### Option 1: Using Bash Script (Recommended)

```bash
# Make script executable
chmod +x setup_postgresql.sh

# Run the setup script
./setup_postgresql.sh
```

The script will:
- ✅ Create `ckandb` database
- ✅ Create `datastore` database
- ✅ Create `ckan-user` with full privileges
- ✅ Create `readonlyuser` with read-only access
- ✅ Configure proper permissions

### Option 2: Using SQL Script

```bash
# Copy SQL script to container or use directly
docker exec -i keycloak_postgres psql -U postgres < setup_postgresql.sql
```

## 🔧 Manual Setup (Step by Step)

### Step 1: Connect to PostgreSQL Container

```bash
docker exec -it keycloak_postgres psql -U postgres
```

### Step 2: Create CKAN Database and User

```sql
-- Create CKAN database user
CREATE ROLE "ckan-user" WITH 
    NOSUPERUSER 
    CREATEDB 
    CREATEROLE 
    LOGIN 
    PASSWORD 'ckan-pass';

-- Create CKAN main database
CREATE DATABASE "ckandb" 
    OWNER "ckan-user" 
    ENCODING 'utf-8';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE "ckandb" TO "ckan-user";
```

### Step 3: Create Datastore Database and Readonly User

```sql
-- Create readonly user for datastore
CREATE ROLE "readonlyuser" WITH 
    NOSUPERUSER 
    NOCREATEDB 
    NOCREATEROLE 
    LOGIN 
    PASSWORD 'readonlypass';

-- Create Datastore database
CREATE DATABASE "datastore" 
    OWNER "ckan-user" 
    ENCODING 'utf-8';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE "datastore" TO "ckan-user";
GRANT CONNECT ON DATABASE "datastore" TO "readonlyuser";
```

### Step 4: Configure Datastore Permissions

```sql
-- Connect to datastore database
\c datastore

-- Grant schema usage
GRANT USAGE ON SCHEMA public TO "readonlyuser";

-- Grant select on existing tables
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "readonlyuser";

-- Grant select on future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
    GRANT SELECT ON TABLES TO "readonlyuser";

-- Grant select on existing sequences
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO "readonlyuser";

-- Grant select on future sequences
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
    GRANT SELECT ON SEQUENCES TO "readonlyuser";
```

### Step 5: Verify Setup

```sql
-- List all databases
\l

-- List all users
\du

-- Test CKAN database connection
\c ckandb
SELECT 'CKAN database ready' AS status;

-- Test Datastore database connection
\c datastore
SELECT 'Datastore database ready' AS status;
```

## 🔍 Verification Commands

### Check if databases exist:

```bash
docker exec -it keycloak_postgres psql -U postgres -c "\l" | grep -E "ckandb|datastore"
```

### Check if users exist:

```bash
docker exec -it keycloak_postgres psql -U postgres -c "\du" | grep -E "ckan-user|readonlyuser"
```

### Test database connections:

```bash
# Test CKAN database
docker exec -it keycloak_postgres psql -U ckan-user -d ckandb -c "SELECT version();"

# Test Datastore database
docker exec -it keycloak_postgres psql -U ckan-user -d datastore -c "SELECT version();"

# Test readonly user (should work)
docker exec -it keycloak_postgres psql -U readonlyuser -d datastore -c "SELECT version();"

# Test readonly user (should fail on write)
docker exec -it keycloak_postgres psql -U readonlyuser -d datastore -c "CREATE TABLE test (id INT);"
# Expected: Permission denied error
```

## 📝 Database Configuration Summary

| Database | User | Password | Permissions |
|----------|------|----------|-------------|
| `ckandb` | `ckan-user` | `ckan-pass` | Full access (owner) |
| `datastore` | `ckan-user` | `ckan-pass` | Full access (owner) |
| `datastore` | `readonlyuser` | `readonlypass` | Read-only (SELECT only) |

## 🚀 Next Steps After Database Setup

### 1. Initialize CKAN Database Schema

Once your CKAN container is running:

```bash
# Initialize CKAN database
docker exec -it <ckan-container-name> ckan db init

# This will create all necessary tables in the ckandb database
```

### 2. Initialize Datastore Permissions

```bash
# Set up datastore permissions script
docker exec -it <ckan-container-name> ckan datastore set-permissions

# This sets up proper permissions for the datastore database
```

### 3. Verify CKAN Can Connect

```bash
# Check CKAN status
docker exec -it <ckan-container-name> ckan sysadmin list

# Should show no errors if database connection is working
```

## 🔧 Troubleshooting

### Issue: "database already exists"

**Solution:** The database already exists. You can either:
- Skip the creation (safe to ignore)
- Drop and recreate: `DROP DATABASE ckandb;` (⚠️ **WARNING:** This deletes all data!)

### Issue: "role already exists"

**Solution:** The user already exists. You can either:
- Skip the creation (safe to ignore)
- Update password: `ALTER USER "ckan-user" WITH PASSWORD 'new-password';`

### Issue: "permission denied"

**Solution:** Make sure you're running commands as the `postgres` superuser:
```bash
docker exec -it keycloak_postgres psql -U postgres
```

### Issue: "cannot connect to database"

**Solution:** Check:
1. Container is running: `docker ps | grep keycloak_postgres`
2. Network connectivity: `docker network inspect s4idtcities`
3. Database name is correct: `\l` to list databases

## 📊 Database Connection Strings

Your `docker-compose.yml` uses these connection strings:

```yaml
# CKAN main database
CKAN_SQLALCHEMY_URL=postgresql://ckan-user:ckan-pass@keycloak_postgres:5432/ckandb

# Datastore write access
CKAN_DATASTORE_WRITE_URL=postgresql://ckan-user:ckan-pass@keycloak_postgres:5432/datastore

# Datastore read-only access
CKAN_DATASTORE_READ_URL=postgresql://readonlyuser:readonlypass@keycloak_postgres:5432/datastore
```

## ✅ Success Checklist

After running the setup, verify:

- [ ] `ckandb` database exists
- [ ] `datastore` database exists
- [ ] `ckan-user` user exists and can connect
- [ ] `readonlyuser` user exists and can connect
- [ ] `ckan-user` has full privileges on both databases
- [ ] `readonlyuser` has read-only access to datastore
- [ ] Datastore permissions are configured correctly

## 🎉 Setup Complete!

Once all steps are completed, you can proceed with:
1. Starting CKAN containers: `docker-compose up -d`
2. Initializing CKAN: `docker exec -it <ckan-container> ckan db init`
3. Setting up datastore: `docker exec -it <ckan-container> ckan datastore set-permissions`

Your CKAN instance will be ready to use! 🚀

