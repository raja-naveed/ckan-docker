#!/bin/bash
# Complete CKAN Setup Script for Ubuntu Server
# This script automates the entire CKAN setup process

set -e  # Exit on any error

echo "=========================================="
echo "🚀 CKAN Complete Setup Script"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
POSTGRES_CONTAINER="postgres"
CKAN_DB="ckandb"
CKAN_DB_USER="ckan-user"
CKAN_DB_PASSWORD="ckan-pass"
DATASTORE_DB="datastore"
DATASTORE_READONLY_USER="readonlyuser"
DATASTORE_READONLY_PASSWORD="readonlypass"

# Function to print status
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Step 1: Verify Prerequisites
echo "📋 Step 1: Verifying prerequisites..."
echo ""

# Check Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed!"
    exit 1
fi
print_status "Docker is installed"

# Check Docker Compose
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed!"
    exit 1
fi
print_status "Docker Compose is installed"

# Check PostgreSQL container
if ! docker ps | grep -q "$POSTGRES_CONTAINER"; then
    print_error "PostgreSQL container '$POSTGRES_CONTAINER' is not running!"
    exit 1
fi
print_status "PostgreSQL container is running"

# Check Redis container
if ! docker ps | grep -q "redis"; then
    print_warning "Redis container is not running (may still work if on network)"
else
    print_status "Redis container is running"
fi

# Check network
if ! docker network ls | grep -q "s4idtcities"; then
    print_warning "Network 's4idtcities' not found, creating it..."
    docker network create s4idtcities
    print_status "Network 's4idtcities' created"
else
    print_status "Network 's4idtcities' exists"
fi

echo ""
echo "=========================================="
echo "🗄️  Step 2: Setting up PostgreSQL databases..."
echo "=========================================="
echo ""

# Detect PostgreSQL superuser
echo "Detecting PostgreSQL superuser..."
POSTGRES_USER=""
for USER in "postgres" "keycloak" "admin"; do
    if docker exec $POSTGRES_CONTAINER psql -U $USER -c "SELECT 1;" > /dev/null 2>&1; then
        POSTGRES_USER=$USER
        print_status "Found PostgreSQL superuser: $POSTGRES_USER"
        break
    fi
done

# If not found, try default
if [ -z "$POSTGRES_USER" ]; then
    if docker exec $POSTGRES_CONTAINER psql -c "SELECT 1;" > /dev/null 2>&1; then
        POSTGRES_USER=""  # Use default
        print_status "Using default PostgreSQL user"
        PSQL_CMD="docker exec -i $POSTGRES_CONTAINER psql"
    else
        print_error "Could not connect to PostgreSQL!"
        print_warning "Please check: docker exec -it postgres psql -U <username>"
        exit 1
    fi
else
    PSQL_CMD="docker exec -i $POSTGRES_CONTAINER psql -U $POSTGRES_USER"
fi

# Create databases and users
echo "Creating CKAN database and user..."
$PSQL_CMD <<EOF
-- Create CKAN user
DO \$\$ BEGIN
    IF NOT EXISTS (SELECT FROM pg_user WHERE usename = '$CKAN_DB_USER') THEN
        CREATE ROLE "$CKAN_DB_USER" WITH NOSUPERUSER CREATEDB CREATEROLE LOGIN PASSWORD '$CKAN_DB_PASSWORD';
        RAISE NOTICE 'User $CKAN_DB_USER created';
    ELSE
        RAISE NOTICE 'User $CKAN_DB_USER already exists';
    END IF;
END \$\$;

-- Create readonly user
DO \$\$ BEGIN
    IF NOT EXISTS (SELECT FROM pg_user WHERE usename = '$DATASTORE_READONLY_USER') THEN
        CREATE ROLE "$DATASTORE_READONLY_USER" WITH NOSUPERUSER NOCREATEDB NOCREATEROLE LOGIN PASSWORD '$DATASTORE_READONLY_PASSWORD';
        RAISE NOTICE 'User $DATASTORE_READONLY_USER created';
    ELSE
        RAISE NOTICE 'User $DATASTORE_READONLY_USER already exists';
    END IF;
END \$\$;

-- Create CKAN database
SELECT 'CREATE DATABASE "$CKAN_DB" OWNER "$CKAN_DB_USER" ENCODING ''utf-8'';'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$CKAN_DB')\gexec

-- Create Datastore database
SELECT 'CREATE DATABASE "$DATASTORE_DB" OWNER "$CKAN_DB_USER" ENCODING ''utf-8'';'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DATASTORE_DB')\gexec

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE "$CKAN_DB" TO "$CKAN_DB_USER";
GRANT ALL PRIVILEGES ON DATABASE "$DATASTORE_DB" TO "$CKAN_DB_USER";
GRANT CONNECT ON DATABASE "$DATASTORE_DB" TO "$DATASTORE_READONLY_USER";
EOF

print_status "Databases and users created"

# Setup datastore permissions
echo "Setting up datastore permissions..."
if [ -z "$POSTGRES_USER" ]; then
    docker exec -i $POSTGRES_CONTAINER psql -d $DATASTORE_DB <<EOF
GRANT USAGE ON SCHEMA public TO "$DATASTORE_READONLY_USER";
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "$DATASTORE_READONLY_USER";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO "$DATASTORE_READONLY_USER";
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO "$DATASTORE_READONLY_USER";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO "$DATASTORE_READONLY_USER";
EOF
else
    docker exec -i $POSTGRES_CONTAINER psql -U $POSTGRES_USER -d $DATASTORE_DB <<EOF
GRANT USAGE ON SCHEMA public TO "$DATASTORE_READONLY_USER";
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "$DATASTORE_READONLY_USER";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO "$DATASTORE_READONLY_USER";
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO "$DATASTORE_READONLY_USER";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO "$DATASTORE_READONLY_USER";
EOF
fi

print_status "Datastore permissions configured"

# Verify databases
echo ""
echo "Verifying database setup..."
if [ -z "$POSTGRES_USER" ]; then
    DB_COUNT=$(docker exec -i $POSTGRES_CONTAINER psql -t -c "SELECT COUNT(*) FROM pg_database WHERE datname IN ('$CKAN_DB', '$DATASTORE_DB');" | tr -d ' ')
else
    DB_COUNT=$(docker exec -i $POSTGRES_CONTAINER psql -U $POSTGRES_USER -t -c "SELECT COUNT(*) FROM pg_database WHERE datname IN ('$CKAN_DB', '$DATASTORE_DB');" | tr -d ' ')
fi
if [ "$DB_COUNT" = "2" ]; then
    print_status "Both databases verified"
else
    print_error "Database verification failed!"
    exit 1
fi

echo ""
echo "=========================================="
echo "🚀 Step 3: Starting CKAN containers..."
echo "=========================================="
echo ""

# Start containers
echo "Starting Docker Compose services..."
docker-compose up -d

# Wait for containers to be ready
echo "Waiting for services to initialize (30 seconds)..."
sleep 30

# Check container status
CKAN_CONTAINER=$(docker-compose ps -q ckan 2>/dev/null || echo "")
if [ -z "$CKAN_CONTAINER" ]; then
    print_error "CKAN container not found! Check logs: docker-compose logs ckan"
    exit 1
fi

print_status "CKAN containers started"

echo ""
echo "=========================================="
echo "🔧 Step 4: Initializing CKAN..."
echo "=========================================="
echo ""

# Wait for CKAN to be ready
echo "Waiting for CKAN to be ready..."
MAX_WAIT=60
WAITED=0
while ! docker exec $CKAN_CONTAINER wget -qO- http://localhost:5000/api/action/status_show > /dev/null 2>&1; do
    if [ $WAITED -ge $MAX_WAIT ]; then
        print_error "CKAN did not become ready within $MAX_WAIT seconds"
        print_warning "Check logs: docker-compose logs ckan"
        exit 1
    fi
    sleep 5
    WAITED=$((WAITED + 5))
    echo "  Waiting... ($WAITED/$MAX_WAIT seconds)"
done

print_status "CKAN is ready"

# Initialize database
echo "Initializing CKAN database schema..."
if docker exec -it $CKAN_CONTAINER ckan db init 2>&1 | grep -q "Successfully\|already"; then
    print_status "Database initialized"
else
    print_warning "Database initialization may have issues, check output above"
fi

# Setup datastore
echo "Setting up datastore permissions..."
if [ -z "$POSTGRES_USER" ]; then
    docker exec -it $CKAN_CONTAINER ckan datastore set-permissions 2>&1 | \
        docker exec -i $POSTGRES_CONTAINER psql -d $DATASTORE_DB > /dev/null 2>&1
else
    docker exec -it $CKAN_CONTAINER ckan datastore set-permissions 2>&1 | \
        docker exec -i $POSTGRES_CONTAINER psql -U $POSTGRES_USER -d $DATASTORE_DB > /dev/null 2>&1
fi
print_status "Datastore permissions configured"

# Rebuild search index
echo "Rebuilding search index..."
docker exec -it $CKAN_CONTAINER ckan search-index rebuild > /dev/null 2>&1
print_status "Search index rebuilt"

echo ""
echo "=========================================="
echo "✅ Step 5: Verifying installation..."
echo "=========================================="
echo ""

# Test API
echo "Testing CKAN API..."
if curl -s http://localhost:5000/api/action/status_show > /dev/null 2>&1; then
    print_status "API is responding"
    API_VERSION=$(curl -s http://localhost:5000/api/action/status_show | grep -o '"ckan_version":"[^"]*' | cut -d'"' -f4)
    echo "  CKAN Version: $API_VERSION"
else
    print_warning "API test failed (may need more time to start)"
fi

# Test web interface
echo "Testing web interface..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/ | grep -q "200"; then
    print_status "Web interface is accessible"
else
    print_warning "Web interface test failed"
fi

# Check container health
echo "Checking container health..."
HEALTHY_COUNT=$(docker-compose ps | grep -c "healthy" || echo "0")
echo "  Healthy containers: $HEALTHY_COUNT"

echo ""
echo "=========================================="
echo "🎉 Setup Complete!"
echo "=========================================="
echo ""
echo "📊 Summary:"
echo "  - Databases: $CKAN_DB, $DATASTORE_DB"
echo "  - Users: $CKAN_DB_USER, $DATASTORE_READONLY_USER"
echo "  - CKAN Container: $CKAN_CONTAINER"
echo ""
echo "🌐 Access CKAN:"
echo "  - Web Interface: http://localhost:5000"
echo "  - API: http://localhost:5000/api"
echo ""
echo "📝 Useful Commands:"
echo "  - View logs: docker-compose logs -f ckan"
echo "  - Check status: docker-compose ps"
echo "  - Stop services: docker-compose down"
echo "  - Restart services: docker-compose restart"
echo ""
echo "🔐 Next Steps:"
echo "  1. Access CKAN web interface"
echo "  2. Login via SAML2 (click 'Login' button)"
echo "  3. Create your first dataset"
echo ""
print_status "Setup completed successfully!"

