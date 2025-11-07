#!/bin/bash
# Detect PostgreSQL superuser in postgres container

POSTGRES_CONTAINER="postgres"

echo "Detecting PostgreSQL superuser..."
echo ""

# Try common usernames
USERS=("postgres" "keycloak" "admin" "root")

for USER in "${USERS[@]}"; do
    echo "Trying user: $USER"
    if docker exec -it $POSTGRES_CONTAINER psql -U $USER -c "SELECT version();" > /dev/null 2>&1; then
        echo "✅ Found working user: $USER"
        echo ""
        echo "Update your scripts to use: -U $USER"
        exit 0
    fi
done

# Try to list all users
echo ""
echo "Listing all users in PostgreSQL..."
docker exec -it $POSTGRES_CONTAINER psql -U postgres -c "\du" 2>&1 || \
docker exec -it $POSTGRES_CONTAINER psql -U keycloak -c "\du" 2>&1 || \
docker exec -it $POSTGRES_CONTAINER psql -c "\du" 2>&1

echo ""
echo "Please check the output above and identify the superuser."

