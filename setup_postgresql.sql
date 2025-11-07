-- CKAN PostgreSQL Database Setup SQL Script
-- Run this script inside the postgres container
-- Usage: docker exec -i postgres psql -U postgres < setup_postgresql.sql

-- ==========================================
-- Step 1: Create CKAN Database and User
-- ==========================================

-- Create CKAN database user (if not exists)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'ckan-user') THEN
        CREATE ROLE "ckan-user" WITH NOSUPERUSER CREATEDB CREATEROLE LOGIN PASSWORD 'ckan-pass';
        RAISE NOTICE 'User ckan-user created';
    ELSE
        RAISE NOTICE 'User ckan-user already exists';
    END IF;
END
$$;

-- Create CKAN main database (if not exists)
SELECT 'CREATE DATABASE "ckandb" OWNER "ckan-user" ENCODING ''utf-8'';'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'ckandb')\gexec

-- Grant privileges on CKAN database
GRANT ALL PRIVILEGES ON DATABASE "ckandb" TO "ckan-user";

-- ==========================================
-- Step 2: Create Datastore Database and Readonly User
-- ==========================================

-- Create readonly user for datastore (if not exists)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'readonlyuser') THEN
        CREATE ROLE "readonlyuser" WITH NOSUPERUSER NOCREATEDB NOCREATEROLE LOGIN PASSWORD 'readonlypass';
        RAISE NOTICE 'User readonlyuser created';
    ELSE
        RAISE NOTICE 'User readonlyuser already exists';
    END IF;
END
$$;

-- Create Datastore database (if not exists)
SELECT 'CREATE DATABASE "datastore" OWNER "ckan-user" ENCODING ''utf-8'';'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'datastore')\gexec

-- Grant privileges on Datastore database
GRANT ALL PRIVILEGES ON DATABASE "datastore" TO "ckan-user";
GRANT CONNECT ON DATABASE "datastore" TO "readonlyuser";

-- ==========================================
-- Step 3: Configure Datastore Permissions
-- ==========================================

-- Connect to datastore database and set permissions
\c datastore

-- Grant schema usage to readonly user
GRANT USAGE ON SCHEMA public TO "readonlyuser";

-- Grant select on all existing tables
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "readonlyuser";

-- Grant select on all future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO "readonlyuser";

-- Grant select on all existing sequences
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO "readonlyuser";

-- Grant select on all future sequences
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO "readonlyuser";

-- ==========================================
-- Step 4: Verification
-- ==========================================

-- List all databases
\c postgres
\l

-- List all users
\du

-- Test CKAN database connection
\c ckandb
SELECT 'CKAN database connection successful' AS status;

-- Test Datastore database connection
\c datastore
SELECT 'Datastore database connection successful' AS status;

-- ==========================================
-- Setup Complete!
-- ==========================================

