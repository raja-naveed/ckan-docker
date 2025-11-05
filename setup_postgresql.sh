#!/bin/bash
# CKAN PostgreSQL Database Setup Script
# This script sets up databases and users for CKAN in the existing keycloak_postgres container

set -e

echo "=========================================="
echo "CKAN PostgreSQL Database Setup"
echo "=========================================="
echo ""

# Database configuration
CKAN_DB="ckandb"
CKAN_DB_USER="ckan-user"
CKAN_DB_PASSWORD="ckan-pass"

DATASTORE_DB="datastore"
DATASTORE_READONLY_USER="readonlyuser"
DATASTORE_READONLY_PASSWORD="readonlypass"

POSTGRES_CONTAINER="keycloak_postgres"
POSTGRES_USER="postgres"  # Default postgres superuser

echo "Step 1: Creating CKAN main database and user..."
docker exec -i $POSTGRES_CONTAINER psql -U $POSTGRES_USER <<-EOSQL
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
docker exec -i $POSTGRES_CONTAINER psql -U $POSTGRES_USER <<-EOSQL
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
docker exec -i $POSTGRES_CONTAINER psql -U $POSTGRES_USER -d $DATASTORE_DB <<-EOSQL
    -- Grant schema usage to readonly user
    GRANT USAGE ON SCHEMA public TO "$DATASTORE_READONLY_USER";
    
    -- Grant select on all existing tables
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO "$DATASTORE_READONLY_USER";
    
    -- Grant select on all future tables
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO "$DATASTORE_READONLY_USER";
    
    -- Grant select on all existing sequences
    GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO "$DATASTORE_READONLY_USER";
    
    -- Grant select on all future sequences
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO "$DATASTORE_READONLY_USER";
EOSQL

echo ""
echo "✅ Step 3 Complete: Datastore permissions configured"
echo ""

echo "Step 4: Verifying setup..."
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

echo ""
echo "=========================================="
echo "✅ PostgreSQL Setup Complete!"
echo "=========================================="
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

