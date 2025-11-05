#!/bin/bash
# Quick PostgreSQL Setup for CKAN
# Run this on your server where keycloak_postgres container is running

POSTGRES_CONTAINER="keycloak_postgres"

echo "🚀 Setting up PostgreSQL databases for CKAN..."
echo ""

# Create databases and users
docker exec -i $POSTGRES_CONTAINER psql -U postgres <<EOF
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
docker exec -i $POSTGRES_CONTAINER psql -U postgres -d datastore <<EOF
GRANT USAGE ON SCHEMA public TO "readonlyuser";
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "readonlyuser";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO "readonlyuser";
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO "readonlyuser";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO "readonlyuser";
EOF

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

