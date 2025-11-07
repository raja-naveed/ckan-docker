#!/bin/bash
# Quick PostgreSQL Setup for CKAN (Fixed Version)
# Auto-detects PostgreSQL superuser

POSTGRES_CONTAINER="postgres"

echo "🚀 Setting up PostgreSQL databases for CKAN..."
echo ""

# Detect PostgreSQL superuser
POSTGRES_USER=""
for USER in "postgres" "keycloak" "admin"; do
    if docker exec $POSTGRES_CONTAINER psql -U $USER -c "SELECT 1;" > /dev/null 2>&1; then
        POSTGRES_USER=$USER
        echo "✅ Using PostgreSQL user: $POSTGRES_USER"
        break
    fi
done

# If not found, try default
if [ -z "$POSTGRES_USER" ]; then
    if docker exec $POSTGRES_CONTAINER psql -c "SELECT 1;" > /dev/null 2>&1; then
        echo "✅ Using default PostgreSQL user"
        PSQL_CMD="docker exec -i $POSTGRES_CONTAINER psql"
    else
        echo "❌ Could not connect to PostgreSQL!"
        echo "Please check: docker exec -it postgres psql -U <username>"
        exit 1
    fi
else
    PSQL_CMD="docker exec -i $POSTGRES_CONTAINER psql -U $POSTGRES_USER"
fi

# Create databases and users
$PSQL_CMD <<EOF
-- Create CKAN user
DO \$\$ BEGIN
    IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'ckan-user') THEN
        CREATE ROLE "ckan-user" WITH NOSUPERUSER CREATEDB CREATEROLE LOGIN PASSWORD 'ckan-pass';
    END IF;
END \$\$;

-- Create readonly user
DO \$\$ BEGIN
    IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'readonlyuser') THEN
        CREATE ROLE "readonlyuser" WITH NOSUPERUSER NOCREATEDB NOCREATEROLE LOGIN PASSWORD 'readonlypass';
    END IF;
END \$\$;

-- Create CKAN database
SELECT 'CREATE DATABASE "ckandb" OWNER "ckan-user" ENCODING ''utf-8'';'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'ckandb')\gexec

-- Create Datastore database
SELECT 'CREATE DATABASE "datastore" OWNER "ckan-user" ENCODING ''utf-8'';'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'datastore')\gexec

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE "ckandb" TO "ckan-user";
GRANT ALL PRIVILEGES ON DATABASE "datastore" TO "ckan-user";
GRANT CONNECT ON DATABASE "datastore" TO "readonlyuser";
EOF

# Setup datastore permissions
if [ -z "$POSTGRES_USER" ]; then
    docker exec -i $POSTGRES_CONTAINER psql -d datastore <<EOF
GRANT USAGE ON SCHEMA public TO "readonlyuser";
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "readonlyuser";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO "readonlyuser";
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO "readonlyuser";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO "readonlyuser";
EOF
else
    docker exec -i $POSTGRES_CONTAINER psql -U $POSTGRES_USER -d datastore <<EOF
GRANT USAGE ON SCHEMA public TO "readonlyuser";
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "readonlyuser";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO "readonlyuser";
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO "readonlyuser";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO "readonlyuser";
EOF
fi

echo ""
echo "✅ PostgreSQL setup complete!"
echo ""
echo "Databases created:"
echo "  - ckandb"
echo "  - datastore"
echo ""
echo "Users created:"
echo "  - ckan-user (full access)"
echo "  - readonlyuser (read-only access)"
echo ""

