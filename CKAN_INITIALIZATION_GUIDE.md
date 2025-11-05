# 🚀 CKAN Initialization Guide

Complete guide for initializing CKAN after PostgreSQL setup.

## 📋 Prerequisites

- ✅ PostgreSQL databases created (`ckandb` and `datastore`)
- ✅ CKAN containers running (`docker-compose up -d`)
- ✅ Network connectivity verified

## 🔧 Step-by-Step Initialization

### Step 1: Start CKAN Containers

```bash
# Navigate to CKAN directory
cd /path/to/ckan-docker

# Start all services
docker-compose up -d

# Check container status
docker-compose ps
```

### Step 2: Wait for CKAN to be Ready

```bash
# Check CKAN logs
docker-compose logs -f ckan

# Wait until you see: "Application startup complete"
# Press Ctrl+C to exit log view
```

### Step 3: Initialize CKAN Database Schema

```bash
# Get CKAN container name
CKAN_CONTAINER=$(docker-compose ps -q ckan)

# Initialize CKAN database
docker exec -it $CKAN_CONTAINER ckan db init

# Expected output:
# Initialising database: /srv/app/src/ckan/ckan/db/init.sql
# Initialising database: /srv/app/src/ckan/ckan/db/init_sysadmin.sql
# ...
# Successfully initialised database
```

### Step 4: Create System Administrator

```bash
# Create admin user (replace with your details)
docker exec -it $CKAN_CONTAINER ckan sysadmin add admin \
    email=admin@example.com \
    password=SecurePassword123 \
    fullname="System Administrator"

# Expected output:
# Added user admin as sysadmin
```

**Note:** If using SAML2 authentication, you may not need this step as users will be created automatically on first login.

### Step 5: Initialize Datastore Permissions

```bash
# Set up datastore permissions
docker exec -it $CKAN_CONTAINER ckan datastore set-permissions

# This creates a SQL script to set permissions
# You need to run it manually:

# Get the generated SQL
docker exec -it $CKAN_CONTAINER ckan datastore set-permissions | \
    docker exec -i keycloak_postgres psql -U postgres -d datastore
```

### Step 6: Verify Installation

```bash
# Check CKAN status
docker exec -it $CKAN_CONTAINER ckan sysadmin list

# Check API status
curl http://localhost:5000/api/action/status_show

# Check if you can access CKAN
curl http://localhost:5000/
```

## 🎯 Quick Initialization Script

Create and run this script for automated initialization:

```bash
#!/bin/bash
# quick_init_ckan.sh

echo "🚀 Initializing CKAN..."

# Get container name
CKAN_CONTAINER=$(docker-compose ps -q ckan)

if [ -z "$CKAN_CONTAINER" ]; then
    echo "❌ CKAN container not found!"
    exit 1
fi

echo "📊 Step 1: Initializing database schema..."
docker exec -it $CKAN_CONTAINER ckan db init

echo ""
echo "📊 Step 2: Setting up datastore permissions..."
docker exec -it $CKAN_CONTAINER ckan datastore set-permissions | \
    docker exec -i keycloak_postgres psql -U postgres -d datastore

echo ""
echo "✅ CKAN initialization complete!"
echo ""
echo "Next steps:"
echo "  1. Access CKAN: http://localhost:5000"
echo "  2. Login via SAML2: Click 'Login' button"
echo "  3. First user to login will be auto-created"
echo ""
```

## 🔍 Verification Checklist

After initialization, verify:

### Database Connection
```bash
# Test database connection
docker exec -it $CKAN_CONTAINER ckan db current

# Should show database version and connection info
```

### API Status
```bash
# Check API
curl http://localhost:5000/api/action/status_show

# Expected JSON response with CKAN version
```

### Web Interface
```bash
# Check if CKAN is accessible
curl -I http://localhost:5000/

# Should return HTTP 200 OK
```

### Datastore Status
```bash
# Check datastore
docker exec -it $CKAN_CONTAINER ckan datastore info

# Should show datastore connection info
```

## 🐛 Troubleshooting

### Issue: "database does not exist"

**Solution:** Make sure PostgreSQL setup completed:
```bash
docker exec -it keycloak_postgres psql -U postgres -c "\l" | grep ckandb
```

### Issue: "permission denied"

**Solution:** Check database user permissions:
```bash
docker exec -it keycloak_postgres psql -U postgres -c "\du" | grep ckan-user
```

### Issue: "connection refused"

**Solution:** 
1. Check if container is running: `docker-compose ps`
2. Check network: `docker network inspect s4idtcities`
3. Verify database URLs in `docker-compose.yml`

### Issue: "ckan: command not found"

**Solution:** Make sure you're using the correct container:
```bash
# Check container name
docker-compose ps

# Use full container name
docker exec -it <container-name> ckan db init
```

## 📝 Post-Initialization Tasks

### 1. Configure Site Settings

```bash
# Set site title
docker exec -it $CKAN_CONTAINER ckan config-tool \
    "ckan.site_title = 'My Data Portal'"

# Set site description
docker exec -it $CKAN_CONTAINER ckan config-tool \
    "ckan.site_description = 'Open data portal'"
```

### 2. Enable Plugins

Verify plugins are enabled in `ckan.ini`:
```bash
docker exec -it $CKAN_CONTAINER grep "ckan.plugins" /srv/app/ckan.ini
```

### 3. Rebuild Search Index

```bash
# Rebuild Solr index
docker exec -it $CKAN_CONTAINER ckan search-index rebuild

# This will index all existing datasets
```

## 🎉 Success Indicators

You'll know CKAN is ready when:

- ✅ Database initialization completes without errors
- ✅ API returns status: `curl http://localhost:5000/api/action/status_show`
- ✅ Web interface loads: `http://localhost:5000`
- ✅ Login button works and redirects to SAML2
- ✅ Datastore permissions are set correctly

## 🚀 Next Steps

1. **Access CKAN**: `http://localhost:5000` (or your configured domain)
2. **Login via SAML2**: Click login, authenticate with Keycloak
3. **Create First Dataset**: Test the full workflow
4. **Configure Nginx**: Set up reverse proxy if needed
5. **Monitor Logs**: `docker-compose logs -f`

## 📚 Additional Resources

- CKAN Documentation: https://docs.ckan.org/
- API Documentation: http://localhost:5000/api/action/help_show
- Admin Interface: Access via `/user/<admin-username>`

---

**Your CKAN instance is now ready for use!** 🎊

