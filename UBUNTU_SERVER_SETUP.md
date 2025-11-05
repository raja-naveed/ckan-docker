# 🐧 Ubuntu Server CKAN Setup Guide

Complete step-by-step guide for setting up CKAN on Ubuntu Server with your existing PostgreSQL, Redis, and network infrastructure.

## 📋 Prerequisites

### Step 1.1: Verify Docker Installation

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

### Step 1.2: Verify Existing Containers

```bash
# Check PostgreSQL container is running
docker ps | grep keycloak_postgres

# Check Redis container is running
docker ps | grep redis

# Check network exists
docker network ls | grep s4idtcities

# If network doesn't exist, create it:
docker network create s4idtcities
```

### Step 1.3: Navigate to CKAN Directory

```bash
# Navigate to your CKAN project directory
cd ~/Snap4IdtCities/CKANDOCKER/ckan-docker
# or wherever you uploaded/extracted the CKAN code

# Verify you're in the right directory
ls -la docker-compose.yml

# List available setup scripts
ls -la *.sh
```

---

## 🗄️ Step 2: Detect PostgreSQL Superuser

**IMPORTANT:** Before setting up databases, we need to detect the correct PostgreSQL superuser.

### Step 2.1: Detect PostgreSQL User

```bash
# Make detection script executable
chmod +x detect_postgres_user.sh

# Run detection script
./detect_postgres_user.sh
```

**OR manually test:**

```bash
# Try common usernames one by one
docker exec -it keycloak_postgres psql -U keycloak -c "SELECT version();"
docker exec -it keycloak_postgres psql -U postgres -c "SELECT version();"
docker exec -it keycloak_postgres psql -c "SELECT version();"
```

**Note which username works!** (Usually it's `keycloak` for Keycloak PostgreSQL containers)

### Step 2.2: List All PostgreSQL Users (Optional)

```bash
# Try to list users (use the username that worked above)
docker exec -it keycloak_postgres psql -U keycloak -c "\du"
# or
docker exec -it keycloak_postgres psql -U postgres -c "\du"
```

---

## 🗄️ Step 3: PostgreSQL Database Setup

### Option A: Quick Automated Setup (Recommended) ⭐

**This script auto-detects the PostgreSQL user!**

```bash
# Make fixed script executable
chmod +x quick_setup_fixed.sh

# Run the setup script (auto-detects PostgreSQL user)
./quick_setup_fixed.sh
```

**Expected Output:**
```
🚀 Setting up PostgreSQL databases for CKAN...
✅ Using PostgreSQL user: keycloak
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
# Make fixed script executable
chmod +x setup_postgresql_fixed.sh

# Run detailed setup (auto-detects PostgreSQL user)
./setup_postgresql_fixed.sh
```

### Option C: Manual SQL Setup

If scripts don't work, do it manually:

```bash
# Connect to PostgreSQL container (use the username that worked in Step 2)
docker exec -it keycloak_postgres psql -U keycloak
# Replace 'keycloak' with the username you detected
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

### Step 3.1: Verify Database Setup

```bash
# List databases (use detected username)
docker exec -it keycloak_postgres psql -U keycloak -c "\l" | grep -E "ckandb|datastore"

# List users
docker exec -it keycloak_postgres psql -U keycloak -c "\du" | grep -E "ckan-user|readonlyuser"

# Test CKAN database connection
docker exec -it keycloak_postgres psql -U ckan-user -d ckandb -c "SELECT version();"

# Test Datastore database connection
docker exec -it keycloak_postgres psql -U ckan-user -d datastore -c "SELECT version();"

# Test readonly user (should work)
docker exec -it keycloak_postgres psql -U readonlyuser -d datastore -c "SELECT version();"
```

**Expected:** All commands should succeed without errors.

---

## 🚀 Step 4: Start CKAN Containers

### Step 4.1: Review Configuration

```bash
# Check docker-compose.yml exists
cat docker-compose.yml | head -30

# Verify database connection strings
grep -A 2 "CKAN_SQLALCHEMY_URL" docker-compose.yml
grep -A 2 "CKAN_REDIS_URL" docker-compose.yml
```

### Step 4.2: Start All Services

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

### Step 4.3: Monitor Startup Logs

```bash
# Watch CKAN logs (press Ctrl+C to exit)
docker-compose logs -f ckan

# Check all services logs
docker-compose logs -f

# Check specific service
docker-compose logs -f solr
```

**Wait for:** "Application startup complete" in CKAN logs (may take 1-2 minutes)

---

## 🔧 Step 5: Initialize CKAN

### Step 5.1: Get CKAN Container Name

```bash
# Get CKAN container name/ID
CKAN_CONTAINER=$(docker-compose ps -q ckan)

# Verify container name
echo $CKAN_CONTAINER
docker ps | grep $CKAN_CONTAINER
```

### Step 5.2: Initialize CKAN Database Schema

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

**If you see errors about connection, wait a bit and try again:**
```bash
# Wait 30 seconds for CKAN to fully start
sleep 30
docker exec -it $CKAN_CONTAINER ckan db init
```

### Step 5.3: Setup Datastore Permissions

```bash
# Generate and apply datastore permissions
# Use the PostgreSQL username you detected earlier (e.g., keycloak)
docker exec -it $CKAN_CONTAINER ckan datastore set-permissions | \
    docker exec -i keycloak_postgres psql -U keycloak -d datastore
```

**Replace `keycloak` with the username you detected in Step 2!**

**Expected Output:**
```
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT CREATE ON SCHEMA public TO "ckan-user";
GRANT USAGE ON SCHEMA public TO "readonlyuser";
...
```

### Step 5.4: Rebuild Search Index

```bash
# Rebuild Solr search index
docker exec -it $CKAN_CONTAINER ckan search-index rebuild
```

**Note:** This may take a few minutes depending on existing data.

---

## ✅ Step 6: Verification

### Step 6.1: Check Database Connection

```bash
# Test database connection
docker exec -it $CKAN_CONTAINER ckan db current

# Should show database version and connection info
```

### Step 6.2: Check API Status

```bash
# Test CKAN API
curl http://localhost:5000/api/action/status_show

# Or if running on different host:
curl http://your-server-ip:5000/api/action/status_show
```

**Expected Output:** JSON response with CKAN version info

### Step 6.3: Check Web Interface

```bash
# Test web interface
curl -I http://localhost:5000/

# Should return: HTTP/1.1 200 OK
```

### Step 6.4: Check Container Health

```bash
# Check all containers
docker-compose ps

# Check specific container health
docker inspect $(docker-compose ps -q ckan) | grep -A 10 Health
```

### Step 6.5: Check Logs for Errors

```bash
# View recent CKAN logs
docker-compose logs ckan | tail -50

# Check for errors
docker-compose logs ckan | grep -i error

# Should show no critical errors
```

---

## 🎯 Complete Setup Checklist

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

## 🔧 Quick Reference Commands

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
# Connect to PostgreSQL (use detected username, e.g., keycloak)
docker exec -it keycloak_postgres psql -U keycloak

# Connect as CKAN user
docker exec -it keycloak_postgres psql -U ckan-user -d ckandb

# List databases
docker exec -it keycloak_postgres psql -U keycloak -c "\l"

# List users
docker exec -it keycloak_postgres psql -U keycloak -c "\du"
```

---

## 🐛 Troubleshooting

### Issue: "role 'postgres' does not exist"

**Solution:** Use the fixed scripts that auto-detect the user:

```bash
chmod +x quick_setup_fixed.sh
./quick_setup_fixed.sh
```

Or manually detect and use the correct username:

```bash
# Detect username
docker exec -it keycloak_postgres psql -U keycloak -c "SELECT version();"
# If that works, use 'keycloak' instead of 'postgres'
```

### Issue: Database Connection Failed

```bash
# 1. Verify PostgreSQL container is running
docker ps | grep keycloak_postgres

# 2. Test network connectivity from CKAN container
docker exec -it $(docker-compose ps -q ckan) ping -c 3 keycloak_postgres

# 3. Verify database exists (use detected username)
docker exec -it keycloak_postgres psql -U keycloak -c "\l" | grep ckandb

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
# Re-run database setup with fixed script
./quick_setup_fixed.sh

# Or manually fix permissions (use detected username)
docker exec -i keycloak_postgres psql -U keycloak -d datastore <<EOF
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

## 🎉 All-in-One Setup Script

If you want to automate everything, use the complete setup script:

```bash
# Make script executable
chmod +x setup_all.sh

# Run complete setup
./setup_all.sh
```

**Note:** Make sure to update `setup_all.sh` to use the detected PostgreSQL username if needed.

---

## 📊 Summary

### What Gets Created

**PostgreSQL Databases:**
- `ckandb` — Main CKAN database
- `datastore` — Data storage database

**PostgreSQL Users:**
- `ckan-user` — Full access (password: `ckan-pass`)
- `readonlyuser` — Read-only access (password: `readonlypass`)

**Docker Containers:**
- `ckan` — Main CKAN application
- `datapusher` — Data processing service
- `solr` — Search engine

### Connection Strings Used

Your `docker-compose.yml` uses these connection strings:

```yaml
# CKAN main database
CKAN_SQLALCHEMY_URL=postgresql://ckan-user:ckan-pass@keycloak_postgres:5432/ckandb

# Datastore write access
CKAN_DATASTORE_WRITE_URL=postgresql://ckan-user:ckan-pass@keycloak_postgres:5432/datastore

# Datastore read-only access
CKAN_DATASTORE_READ_URL=postgresql://readonlyuser:readonlypass@keycloak_postgres:5432/datastore
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

## 🚀 Next Steps After Setup

1. **Access CKAN**: `http://your-server-ip:5000` (or your configured domain)
2. **Login via SAML2**: Click "Login" button, authenticate with Keycloak
3. **Create First Dataset**: Test the full workflow
4. **Configure Nginx**: Set up reverse proxy if needed
5. **Monitor Logs**: `docker-compose logs -f`

---

**Your CKAN instance is now ready on Ubuntu Server!** 🎊

For support, check logs: `docker-compose logs -f`
