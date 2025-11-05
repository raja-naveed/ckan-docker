# 🐧 Ubuntu Server CKAN Setup Guide

Complete step-by-step guide for setting up CKAN on Ubuntu Server with your existing PostgreSQL, Redis, and network infrastructure.

## 📋 Prerequisites

### 1. Verify Docker Installation

```bash
# Check Docker version
docker --version
# Should show: Docker version 20.10 or higher

# Check Docker Compose version
docker-compose --version
# Should show: docker-compose version 1.29 or higher

# If not installed, install Docker:
# curl -fsSL https://get.docker.com -o get-docker.sh
# sudo sh get-docker.sh
# sudo usermod -aG docker $USER
# newgrp docker
```

### 2. Verify Existing Containers

```bash
# Check PostgreSQL container
docker ps | grep keycloak_postgres

# Check Redis container
docker ps | grep redis

# Check network
docker network ls | grep s4idtcities

# If network doesn't exist, create it:
docker network create s4idtcities
```

### 3. Navigate to CKAN Directory

```bash
# Navigate to your CKAN project directory
cd ~/ckan-docker
# or wherever you uploaded/extracted the CKAN code

# Verify you're in the right directory
ls -la docker-compose.yml
```

---

## 🗄️ Step 1: PostgreSQL Database Setup

### Option A: Quick Automated Setup (Recommended)

```bash
# Make script executable
chmod +x quick_setup.sh

# Run the setup script
./quick_setup.sh
```

**Expected Output:**
```
🚀 Setting up PostgreSQL databases for CKAN...

✅ PostgreSQL setup complete!

Databases created:
  - ckandb
  - datastore

Users created:
  - ckan-user (full access)
  - readonlyuser (read-only access)
```

### Option B: Detailed Setup Script

```bash
# Make script executable
chmod +x setup_postgresql.sh

# Run detailed setup
./setup_postgresql.sh
```

### Option C: Manual SQL Setup

```bash
# Connect to PostgreSQL container
docker exec -it keycloak_postgres psql -U postgres
```

Then run these SQL commands:

```sql
-- 1. Create CKAN database user
CREATE ROLE "ckan-user" WITH 
    NOSUPERUSER CREATEDB CREATEROLE LOGIN PASSWORD 'ckan-pass';

-- 2. Create readonly user for datastore
CREATE ROLE "readonlyuser" WITH 
    NOSUPERUSER NOCREATEDB NOCREATEROLE LOGIN PASSWORD 'readonlypass';

-- 3. Create CKAN main database
CREATE DATABASE "ckandb" OWNER "ckan-user" ENCODING 'utf-8';

-- 4. Create Datastore database
CREATE DATABASE "datastore" OWNER "ckan-user" ENCODING 'utf-8';

-- 5. Grant privileges on CKAN database
GRANT ALL PRIVILEGES ON DATABASE "ckandb" TO "ckan-user";

-- 6. Grant privileges on Datastore database
GRANT ALL PRIVILEGES ON DATABASE "datastore" TO "ckan-user";
GRANT CONNECT ON DATABASE "datastore" TO "readonlyuser";

-- 7. Connect to datastore and set permissions
\c datastore

GRANT USAGE ON SCHEMA public TO "readonlyuser";
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "readonlyuser";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO "readonlyuser";
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO "readonlyuser";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO "readonlyuser";

-- 8. Exit psql
\q
```

### Verify Database Setup

```bash
# List databases
docker exec -it keycloak_postgres psql -U postgres -c "\l" | grep -E "ckandb|datastore"

# List users
docker exec -it keycloak_postgres psql -U postgres -c "\du" | grep -E "ckan-user|readonlyuser"

# Test CKAN database connection
docker exec -it keycloak_postgres psql -U ckan-user -d ckandb -c "SELECT version();"

# Test Datastore database connection
docker exec -it keycloak_postgres psql -U ckan-user -d datastore -c "SELECT version();"

# Test readonly user (should work)
docker exec -it keycloak_postgres psql -U readonlyuser -d datastore -c "SELECT version();"
```

---

## 🚀 Step 2: Start CKAN Containers

### Start All Services

```bash
# Start all CKAN services in detached mode
docker-compose up -d

# Check status
docker-compose ps
```

**Expected Output:**
```
NAME                IMAGE                      STATUS
ckan                ckan/ckan:latest          Up (healthy)
datapusher          ckan/ckan-datapusher      Up (healthy)
solr                ckan/ckan-solr:2.11       Up (healthy)
```

### Monitor Startup Logs

```bash
# Watch CKAN logs (press Ctrl+C to exit)
docker-compose logs -f ckan

# Check all services logs
docker-compose logs -f

# Check specific service
docker-compose logs -f solr
```

**Wait for:** "Application startup complete" in CKAN logs

---

## 🔧 Step 3: Initialize CKAN

### Get CKAN Container Name

```bash
# Get CKAN container name/ID
CKAN_CONTAINER=$(docker-compose ps -q ckan)

# Verify container name
echo $CKAN_CONTAINER
docker ps | grep $CKAN_CONTAINER
```

### Initialize CKAN Database Schema

```bash
# Initialize CKAN database
docker exec -it $CKAN_CONTAINER ckan db init
```

**Expected Output:**
```
Initialising database: /srv/app/src/ckan/ckan/db/init.sql
Initialising database: /srv/app/src/ckan/ckan/db/init_sysadmin.sql
...
Successfully initialised database
```

### Setup Datastore Permissions

```bash
# Generate and apply datastore permissions
docker exec -it $CKAN_CONTAINER ckan datastore set-permissions | \
    docker exec -i keycloak_postgres psql -U postgres -d datastore
```

**Expected Output:**
```
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT CREATE ON SCHEMA public TO "ckan-user";
GRANT USAGE ON SCHEMA public TO "readonlyuser";
...
```

### Rebuild Search Index

```bash
# Rebuild Solr search index
docker exec -it $CKAN_CONTAINER ckan search-index rebuild
```

**Note:** This may take a few minutes depending on existing data.

---

## ✅ Step 4: Verification

### 1. Check Database Connection

```bash
# Test database connection
docker exec -it $CKAN_CONTAINER ckan db current

# Should show database version and connection info
```

### 2. Check API Status

```bash
# Test CKAN API
curl http://localhost:5000/api/action/status_show

# Or if running on different host:
curl http://your-server-ip:5000/api/action/status_show
```

**Expected Output:** JSON response with CKAN version info

### 3. Check Web Interface

```bash
# Test web interface
curl -I http://localhost:5000/

# Should return: HTTP/1.1 200 OK
```

### 4. Check Container Health

```bash
# Check all containers
docker-compose ps

# Check specific container health
docker inspect $(docker-compose ps -q ckan) | grep -A 10 Health
```

### 5. Check Logs for Errors

```bash
# View recent CKAN logs
docker-compose logs ckan | tail -50

# Check for errors
docker-compose logs ckan | grep -i error

# Should show no critical errors
```

---

## 🎯 Quick Reference Commands

### Start/Stop Services

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Restart services
docker-compose restart

# Stop and remove containers (keeps volumes)
docker-compose down

# Stop and remove everything including volumes
docker-compose down -v
```

### View Logs

```bash
# All services logs
docker-compose logs -f

# Specific service logs
docker-compose logs -f ckan
docker-compose logs -f solr
docker-compose logs -f datapusher

# Last 100 lines
docker-compose logs --tail=100 ckan
```

### Container Management

```bash
# Get container ID
CKAN_CONTAINER=$(docker-compose ps -q ckan)

# Execute commands in container
docker exec -it $CKAN_CONTAINER bash
docker exec -it $CKAN_CONTAINER ckan db init
docker exec -it $CKAN_CONTAINER ckan sysadmin list

# Check container status
docker-compose ps
docker ps | grep ckan
```

### Database Operations

```bash
# Connect to PostgreSQL
docker exec -it keycloak_postgres psql -U postgres

# Connect as CKAN user
docker exec -it keycloak_postgres psql -U ckan-user -d ckandb

# List databases
docker exec -it keycloak_postgres psql -U postgres -c "\l"

# List users
docker exec -it keycloak_postgres psql -U postgres -c "\du"
```

---

## 🔍 Troubleshooting

### Issue: Database Connection Failed

```bash
# 1. Verify PostgreSQL container is running
docker ps | grep keycloak_postgres

# 2. Test network connectivity from CKAN container
docker exec -it $(docker-compose ps -q ckan) ping -c 3 keycloak_postgres

# 3. Verify database exists
docker exec -it keycloak_postgres psql -U postgres -c "\l" | grep ckandb

# 4. Check connection string
docker exec -it $(docker-compose ps -q ckan) env | grep CKAN_SQLALCHEMY_URL
```

### Issue: Redis Connection Failed

```bash
# 1. Verify Redis container is running
docker ps | grep redis

# 2. Test Redis connectivity
docker exec -it $(docker-compose ps -q ckan) ping -c 3 redis

# 3. Test Redis connection
docker exec -it $(docker-compose ps -q ckan) redis-cli -h redis ping
# Should return: PONG
```

### Issue: Solr Connection Failed

```bash
# 1. Check Solr container
docker-compose ps solr

# 2. Check Solr logs
docker-compose logs solr

# 3. Test Solr connectivity
docker exec -it $(docker-compose ps -q ckan) wget -qO- http://solr:8983/solr/

# 4. Check Solr from host
curl http://localhost:8983/solr/
```

### Issue: Permission Denied

```bash
# Re-run database setup
./quick_setup.sh

# Or manually fix permissions
docker exec -i keycloak_postgres psql -U postgres -d datastore <<EOF
GRANT USAGE ON SCHEMA public TO "readonlyuser";
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "readonlyuser";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO "readonlyuser";
EOF
```

### Issue: Container Won't Start

```bash
# Check logs for errors
docker-compose logs ckan

# Check container status
docker-compose ps

# Restart containers
docker-compose down
docker-compose up -d

# Check system resources
free -h
df -h
```

### Issue: Network Not Found

```bash
# Create network if missing
docker network create s4idtcities

# Verify network
docker network ls | grep s4idtcities

# Check which containers are on network
docker network inspect s4idtcities
```

---

## 📊 Complete Setup Checklist

After completing all steps, verify:

- [ ] PostgreSQL databases created (`ckandb`, `datastore`)
- [ ] Database users created (`ckan-user`, `readonlyuser`)
- [ ] Database permissions configured
- [ ] CKAN containers running (`docker-compose ps`)
- [ ] CKAN database initialized (`ckan db init` completed)
- [ ] Datastore permissions set
- [ ] Search index rebuilt
- [ ] API responding (`curl http://localhost:5000/api/action/status_show`)
- [ ] Web interface accessible
- [ ] No errors in logs
- [ ] SAML2 login working (can authenticate via Keycloak)

---

## 🎉 All-in-One Setup Script

Create `setup_all.sh`:

```bash
#!/bin/bash
# Complete CKAN setup script for Ubuntu Server

set -e

echo "=========================================="
echo "CKAN Complete Setup Script"
echo "=========================================="
echo ""

# Step 1: PostgreSQL Setup
echo "🗄️  Step 1: Setting up PostgreSQL databases..."
if [ -f "./quick_setup.sh" ]; then
    chmod +x quick_setup.sh
    ./quick_setup.sh
else
    echo "❌ quick_setup.sh not found!"
    exit 1
fi

# Step 2: Start Containers
echo ""
echo "🚀 Step 2: Starting CKAN containers..."
docker-compose up -d

# Step 3: Wait for services
echo ""
echo "⏳ Step 3: Waiting for services to be ready..."
sleep 30

# Step 4: Initialize CKAN
echo ""
echo "🔧 Step 4: Initializing CKAN..."
CKAN_CONTAINER=$(docker-compose ps -q ckan)

if [ -z "$CKAN_CONTAINER" ]; then
    echo "❌ CKAN container not found!"
    exit 1
fi

echo "Initializing database schema..."
docker exec -it $CKAN_CONTAINER ckan db init

echo "Setting up datastore permissions..."
docker exec -it $CKAN_CONTAINER ckan datastore set-permissions | \
    docker exec -i keycloak_postgres psql -U postgres -d datastore

echo "Rebuilding search index..."
docker exec -it $CKAN_CONTAINER ckan search-index rebuild

# Step 5: Verification
echo ""
echo "✅ Step 5: Verifying installation..."
echo "Testing API..."
curl -s http://localhost:5000/api/action/status_show | head -5

echo ""
echo "=========================================="
echo "✅ Setup Complete!"
echo "=========================================="
echo ""
echo "CKAN is now running at: http://localhost:5000"
echo "API available at: http://localhost:5000/api"
echo ""
echo "Next steps:"
echo "  1. Access CKAN web interface"
echo "  2. Login via SAML2 (click Login button)"
echo "  3. Create your first dataset"
echo ""
```

Make it executable and run:

```bash
chmod +x setup_all.sh
./setup_all.sh
```

---

## 🔒 Security Notes

1. **Change Default Passwords**: Update passwords in `docker-compose.yml` and scripts
2. **Firewall**: Configure firewall rules for your server
3. **SSL/TLS**: Configure HTTPS via Nginx reverse proxy
4. **Database Backups**: Set up regular PostgreSQL backups
5. **Container Updates**: Keep containers updated regularly

---

## 📚 Additional Resources

- **CKAN Documentation**: https://docs.ckan.org/
- **CKAN API**: http://your-server:5000/api/action/help_show
- **PostgreSQL Docs**: https://www.postgresql.org/docs/
- **Docker Docs**: https://docs.docker.com/

---

**Your CKAN instance is now ready on Ubuntu Server!** 🚀

For support, check logs: `docker-compose logs -f`

