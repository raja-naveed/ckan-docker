#!/bin/bash
# CKAN PostgreSQL Database Setup Script (Fixed Version)
# This script detects and uses the correct PostgreSQL superuser

set -e

echo "=========================================="
echo "CKAN PostgreSQL Database Setup"
echo "=========================================="
echo ""

# Configuration
POSTGRES_CONTAINER="postgres"
CKAN_DB="ckandb"
CKAN_DB_USER="ckan-user"
CKAN_DB_PASSWORD="ckan-pass"
DATASTORE_DB="datastore"
DATASTORE_READONLY_USER="readonlyuser"
DATASTORE_READONLY_PASSWORD="readonlypass"

# Detect PostgreSQL superuser
echo "Step 0: Detecting PostgreSQL superuser..."
POSTGRES_USER=""

# Try common usernames
for USER in "postgres" "keycloak" "admin"; do
    if docker exec $POSTGRES_CONTAINER psql -U $USER -c "SELECT 1;" > /dev/null 2>&1; then
        POSTGRES_USER=$USER
        echo "✅ Found PostgreSQL superuser: $POSTGRES_USER"
        break
    fi
done

# If still not found, try without specifying user (uses default)
if [ -z "$POSTGRES_USER" ]; then
    if docker exec $POSTGRES_CONTAINER psql -c "SELECT 1;" > /dev/null 2>&1; then
        POSTGRES_USER=""  # Use default
        echo "✅ Using default PostgreSQL user"
    else
        echo "❌ Could not connect to PostgreSQL!"
        echo ""
        echo "Please check:"
        echo "  1. Container is running: docker ps | grep postgres"
        echo "  2. Try manual connection: docker exec -it postgres psql -U <username>"
        echo "  3. List users: docker exec -it postgres psql -U <username> -c '\du'"
        exit 1
    fi
fi

echo ""
echo "Step 1: Creating CKAN main database and user..."

# Build psql command with or without user
if [ -z "$POSTGRES_USER" ]; then
    PSQL_CMD="docker exec -i $POSTGRES_CONTAINER psql"
else
    PSQL_CMD="docker exec -i $POSTGRES_CONTAINER psql -U $POSTGRES_USER"
fi

$PSQL_CMD <<-EOSQL
    -- Create CKAN database user
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_user WHERE usename = '$CKAN_DB_USER') THEN
            CREATE ROLE "$CKAN_DB_USER" WITH NOSUPERUSER CREATEDB CREATEROLE LOGIN PASSWORD '$CKAN_DB_PASSWORD';
            RAISE NOTICE 'User $CKAN_DB_USER created';
        ELSE
            RAISE NOTICE 'User $CKAN_DB_USER already exists';
        END IF;
    END
    \$\$;

    -- Create CKAN main database
    SELECT 'CREATE DATABASE "$CKAN_DB" OWNER "$CKAN_DB_USER" ENCODING ''utf-8'';'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$CKAN_DB')\gexec

    -- Grant privileges on CKAN database
    GRANT ALL PRIVILEGES ON DATABASE "$CKAN_DB" TO "$CKAN_DB_USER";
EOSQL

echo ""
echo "✅ Step 1 Complete: CKAN database and user created"
echo ""

echo "Step 2: Creating Datastore database and readonly user..."

$PSQL_CMD <<-EOSQL
    -- Create readonly user for datastore
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_user WHERE usename = '$DATASTORE_READONLY_USER') THEN
            CREATE ROLE "$DATASTORE_READONLY_USER" WITH NOSUPERUSER NOCREATEDB NOCREATEROLE LOGIN PASSWORD '$DATASTORE_READONLY_PASSWORD';
            RAISE NOTICE 'User $DATASTORE_READONLY_USER created';
        ELSE
            RAISE NOTICE 'User $DATASTORE_READONLY_USER already exists';
        END IF;
    END
    \$\$;

    -- Create Datastore database
    SELECT 'CREATE DATABASE "$DATASTORE_DB" OWNER "$CKAN_DB_USER" ENCODING ''utf-8'';'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DATASTORE_DB')\gexec

    -- Grant privileges on Datastore database
    GRANT ALL PRIVILEGES ON DATABASE "$DATASTORE_DB" TO "$CKAN_DB_USER";
    GRANT CONNECT ON DATABASE "$DATASTORE_DB" TO "$DATASTORE_READONLY_USER";
EOSQL

echo ""
echo "✅ Step 2 Complete: Datastore database and readonly user created"
echo ""

echo "Step 3: Setting up Datastore permissions..."

if [ -z "$POSTGRES_USER" ]; then
    docker exec -i $POSTGRES_CONTAINER psql -d $DATASTORE_DB <<-EOSQL
GRANT USAGE ON SCHEMA public TO "$DATASTORE_READONLY_USER";
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "$DATASTORE_READONLY_USER";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO "$DATASTORE_READONLY_USER";
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO "$DATASTORE_READONLY_USER";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO "$DATASTORE_READONLY_USER";
EOSQL
else
    docker exec -i $POSTGRES_CONTAINER psql -U $POSTGRES_USER -d $DATASTORE_DB <<-EOSQL
GRANT USAGE ON SCHEMA public TO "$DATASTORE_READONLY_USER";
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "$DATASTORE_READONLY_USER";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO "$DATASTORE_READONLY_USER";
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO "$DATASTORE_READONLY_USER";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO "$DATASTORE_READONLY_USER";
EOSQL
fi

echo ""
echo "✅ Step 3 Complete: Datastore permissions configured"
echo ""

echo "Step 4: Verifying setup..."

if [ -z "$POSTGRES_USER" ]; then
    docker exec -i $POSTGRES_CONTAINER psql <<-EOSQL
    -- List databases
    \l
    
    -- List users
    \du
    
    -- Test connection to CKAN database
    \c "$CKAN_DB"
    SELECT 'CKAN database connection successful' AS status;
    
    -- Test connection to Datastore database
    \c "$DATASTORE_DB"
    SELECT 'Datastore database connection successful' AS status;
EOSQL
else
    docker exec -i $POSTGRES_CONTAINER psql -U $POSTGRES_USER <<-EOSQL
    -- List databases
    \l
    
    -- List users
    \du
    
    -- Test connection to CKAN database
    \c "$CKAN_DB"
    SELECT 'CKAN database connection successful' AS status;
    
    -- Test connection to Datastore database
    \c "$DATASTORE_DB"
    SELECT 'Datastore database connection successful' AS status;
EOSQL
fi

echo ""
echo "=========================================="
echo "✅ PostgreSQL Setup Complete!"
echo "=========================================="
echo ""
echo "PostgreSQL superuser used: ${POSTGRES_USER:-default}"
echo ""
echo "Databases created:"
echo "  - $CKAN_DB (owner: $CKAN_DB_USER)"
echo "  - $DATASTORE_DB (owner: $CKAN_DB_USER)"
echo ""
echo "Users created:"
echo "  - $CKAN_DB_USER (full access)"
echo "  - $DATASTORE_READONLY_USER (readonly access to datastore)"
echo ""
echo "Next steps:"
echo "  1. Start CKAN containers: docker-compose up -d"
echo "  2. Initialize CKAN database: docker exec -it <ckan-container> ckan db init"
echo "  3. Initialize Datastore: docker exec -it <ckan-container> ckan datastore set-permissions"
echo ""

