# 🎯 Complete CKAN Setup Instructions

Complete step-by-step guide for setting up CKAN with your existing PostgreSQL, Redis, and network infrastructure.

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [PostgreSQL Database Setup](#postgresql-database-setup)
3. [Start CKAN Containers](#start-ckan-containers)
4. [Initialize CKAN](#initialize-ckan)
5. [Verification](#verification)
6. [Troubleshooting](#troubleshooting)

---

## ✅ Prerequisites

Before starting, ensure:

- ✅ Docker and Docker Compose installed
- ✅ `keycloak_postgres` container running
- ✅ `redis` container running
- ✅ `s4idtcities` Docker network exists
- ✅ CKAN code uploaded to server

### Verify Prerequisites

```bash
# Check Docker
docker --version
docker-compose --version

# Check existing containers
docker ps | grep -E "keycloak_postgres|redis"

# Check network
docker network ls | grep s4idtcities

# Check if network exists, if not create it:
docker network create s4idtcities
```

---

## 🗄️ PostgreSQL Database Setup

### Option 1: Quick Setup (Recommended)

```bash
# Make script executable
chmod +x quick_setup.sh

# Run setup
./quick_setup.sh
```

### Option 2: Manual Setup

```bash
# Connect to PostgreSQL
docker exec -it keycloak_postgres psql -U postgres
```

Then run these SQL commands:

```sql
-- 1. Create CKAN user
CREATE ROLE "ckan-user" WITH 
    NOSUPERUSER CREATEDB CREATEROLE LOGIN PASSWORD 'ckan-pass';

-- 2. Create readonly user
CREATE ROLE "readonlyuser" WITH 
    NOSUPERUSER NOCREATEDB NOCREATEROLE LOGIN PASSWORD 'readonlypass';

-- 3. Create CKAN database
CREATE DATABASE "ckandb" OWNER "ckan-user" ENCODING 'utf-8';

-- 4. Create Datastore database
CREATE DATABASE "datastore" OWNER "ckan-user" ENCODING 'utf-8';

-- 5. Grant privileges
GRANT ALL PRIVILEGES ON DATABASE "ckandb" TO "ckan-user";
GRANT ALL PRIVILEGES ON DATABASE "datastore" TO "ckan-user";
GRANT CONNECT ON DATABASE "datastore" TO "readonlyuser";

-- 6. Connect to datastore and set permissions
\c datastore
GRANT USAGE ON SCHEMA public TO "readonlyuser";
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "readonlyuser";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO "readonlyuser";
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO "readonlyuser";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO "readonlyuser";

-- 7. Verify
\c postgres
\l
\du
```

### Verify Database Setup

```bash
# Check databases exist
docker exec -it keycloak_postgres psql -U postgres -c "\l" | grep -E "ckandb|datastore"

# Check users exist
docker exec -it keycloak_postgres psql -U postgres -c "\du" | grep -E "ckan-user|readonlyuser"

# Test connections
docker exec -it keycloak_postgres psql -U ckan-user -d ckandb -c "SELECT version();"
docker exec -it keycloak_postgres psql -U readonlyuser -d datastore -c "SELECT version();"
```

---

## 🚀 Start CKAN Containers

### Step 1: Navigate to CKAN Directory

```bash
cd /path/to/ckan-docker
# or wherever you uploaded the CKAN code
```

### Step 2: Check Configuration

```bash
# Verify docker-compose.yml
cat docker-compose.yml | grep -A 5 "keycloak_postgres"
cat docker-compose.yml | grep -A 5 "redis"

# Should show:
# - CKAN_SQLALCHEMY_URL pointing to keycloak_postgres
# - CKAN_REDIS_URL pointing to redis
# - Network: s4idtcities
```

### Step 3: Start Services

```bash
# Start all CKAN services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f ckan
```

### Step 4: Wait for Services to be Ready

```bash
# Check CKAN health
docker-compose ps

# All services should show "Up" status
# CKAN should show "healthy" after a few minutes
```

---

## 🔧 Initialize CKAN

### Step 1: Initialize Database Schema

```bash
# Get CKAN container name
CKAN_CONTAINER=$(docker-compose ps -q ckan)

# Initialize CKAN database
docker exec -it $CKAN_CONTAINER ckan db init

# Expected output:
# Initialising database: /srv/app/src/ckan/ckan/db/init.sql
# Successfully initialised database
```

### Step 2: Setup Datastore Permissions

```bash
# Generate and apply datastore permissions
docker exec -it $CKAN_CONTAINER ckan datastore set-permissions | \
    docker exec -i keycloak_postgres psql -U postgres -d datastore
```

### Step 3: Create System Admin (Optional)

**Note:** If using SAML2, users are created automatically on first login. You can skip this step.

```bash
# Create admin user (optional)
docker exec -it $CKAN_CONTAINER ckan sysadmin add admin \
    email=admin@example.com \
    password=SecurePassword123 \
    fullname="System Administrator"
```

### Step 4: Rebuild Search Index

```bash
# Rebuild Solr index
docker exec -it $CKAN_CONTAINER ckan search-index rebuild
```

---

## ✅ Verification

### 1. Check Database Connection

```bash
# Test database connection
docker exec -it $CKAN_CONTAINER ckan db current

# Should show database version
```

### 2. Check API Status

```bash
# Test API
curl http://localhost:5000/api/action/status_show

# Expected: JSON response with CKAN version info
```

### 3. Check Web Interface

```bash
# Test web interface
curl -I http://localhost:5000/

# Should return: HTTP/1.1 200 OK
```

### 4. Check Logs

```bash
# View CKAN logs
docker-compose logs ckan | tail -50

# Should show no errors
```

### 5. Test SAML2 Login

1. Open browser: `http://localhost:5000` (or your domain)
2. Click "Login" button
3. Should redirect to Keycloak
4. After authentication, should return to CKAN logged in

---

## 🔍 Troubleshooting

### Issue: Database Connection Failed

**Symptoms:**
```
Error: could not connect to server
```

**Solutions:**
```bash
# 1. Verify PostgreSQL container is running
docker ps | grep keycloak_postgres

# 2. Test network connectivity
docker exec -it $(docker-compose ps -q ckan) ping keycloak_postgres

# 3. Verify database exists
docker exec -it keycloak_postgres psql -U postgres -c "\l" | grep ckandb

# 4. Check connection string in docker-compose.yml
docker-compose config | grep CKAN_SQLALCHEMY_URL
```

### Issue: Redis Connection Failed

**Symptoms:**
```
Error: Error connecting to Redis
```

**Solutions:**
```bash
# 1. Verify Redis container is running
docker ps | grep redis

# 2. Test network connectivity
docker exec -it $(docker-compose ps -q ckan) ping redis

# 3. Test Redis connection
docker exec -it $(docker-compose ps -q ckan) redis-cli -h redis ping

# Should return: PONG
```

### Issue: Solr Connection Failed

**Symptoms:**
```
Error: Solr connection error
```

**Solutions:**
```bash
# 1. Check if Solr container is running
docker-compose ps solr

# 2. Check Solr logs
docker-compose logs solr

# 3. Test Solr connectivity
docker exec -it $(docker-compose ps -q ckan) wget -qO- http://solr:8983/solr/
```

### Issue: Network Not Found

**Symptoms:**
```
Error: network s4idtcities not found
```

**Solutions:**
```bash
# Create network if it doesn't exist
docker network create s4idtcities

# Verify network exists
docker network ls | grep s4idtcities

# Restart containers
docker-compose up -d
```

### Issue: Permission Denied

**Symptoms:**
```
Error: permission denied for database
```

**Solutions:**
```bash
# Re-run database setup
./quick_setup.sh

# Or manually fix permissions
docker exec -it keycloak_postgres psql -U postgres -d datastore <<EOF
GRANT USAGE ON SCHEMA public TO "readonlyuser";
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "readonlyuser";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO "readonlyuser";
EOF
```

---

## 📊 Summary Checklist

After completing all steps, verify:

- [ ] PostgreSQL databases created (`ckandb`, `datastore`)
- [ ] Database users created (`ckan-user`, `readonlyuser`)
- [ ] CKAN containers running (`docker-compose ps`)
- [ ] CKAN database initialized (`ckan db init` completed)
- [ ] Datastore permissions set (`ckan datastore set-permissions`)
- [ ] API responding (`curl http://localhost:5000/api/action/status_show`)
- [ ] Web interface accessible (`curl -I http://localhost:5000/`)
- [ ] SAML2 login working (can authenticate via Keycloak)
- [ ] No errors in logs (`docker-compose logs ckan`)

---

## 🎉 Quick Reference Commands

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f ckan

# Check status
docker-compose ps

# Initialize database
docker exec -it $(docker-compose ps -q ckan) ckan db init

# Setup datastore
docker exec -it $(docker-compose ps -q ckan) ckan datastore set-permissions | \
    docker exec -i keycloak_postgres psql -U postgres -d datastore

# Rebuild search index
docker exec -it $(docker-compose ps -q ckan) ckan search-index rebuild

# Create admin (optional)
docker exec -it $(docker-compose ps -q ckan) ckan sysadmin add admin \
    email=admin@example.com password=SecurePassword123
```

---

## 📚 Additional Resources

- **PostgreSQL Setup**: See `POSTGRESQL_SETUP_GUIDE.md`
- **CKAN Initialization**: See `CKAN_INITIALIZATION_GUIDE.md`
- **CKAN Documentation**: https://docs.ckan.org/
- **API Documentation**: http://localhost:5000/api/action/help_show

---

**Setup Complete! Your CKAN instance is ready to use.** 🚀

For support, check logs: `docker-compose logs -f`

