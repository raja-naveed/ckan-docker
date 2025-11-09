#!/bin/bash

###############################################################################
# Complete CKAN SAML2 Deployment Script
# Domain: datagate.snap4idtcity.com
# Database: postgres (in s4idtcities network)
###############################################################################

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CKAN_CONTAINER="ckan-docker-ckan-1"
DOMAIN="datagate.snap4idtcity.com"
ENTITY_ID="https://${DOMAIN}/saml2/metadata"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  CKAN SAML2 Deployment Script${NC}"
echo -e "${BLUE}  Domain: ${DOMAIN}${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Step 1: Check prerequisites
echo -e "${YELLOW}[1/10] Checking prerequisites...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}ERROR: Docker is not installed${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}ERROR: Docker Compose is not installed${NC}"
    exit 1
fi

if [ ! -f ".env" ]; then
    echo -e "${YELLOW}WARNING: .env file not found. Creating from .env.example...${NC}"
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo -e "${RED}Please edit .env file with your actual values before continuing!${NC}"
        exit 1
    else
        echo -e "${RED}ERROR: .env.example file not found${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✓ Prerequisites check passed${NC}"
echo ""

# Step 2: Verify network exists
echo -e "${YELLOW}[2/10] Verifying Docker network...${NC}"
if ! docker network inspect s4idtcities &> /dev/null; then
    echo -e "${RED}ERROR: Docker network 's4idtcities' does not exist${NC}"
    echo -e "${YELLOW}Creating network...${NC}"
    docker network create s4idtcities || {
        echo -e "${RED}Failed to create network. Please create it manually:${NC}"
        echo "docker network create s4idtcities"
        exit 1
    }
fi
echo -e "${GREEN}✓ Network verified${NC}"
echo ""

# Step 3: Build and start services
echo -e "${YELLOW}[3/10] Building and starting Docker services...${NC}"
docker compose down 2>/dev/null || true
docker compose build --no-cache
docker compose up -d

echo -e "${GREEN}✓ Services started${NC}"
echo ""

# Step 4: Wait for services to be healthy
echo -e "${YELLOW}[4/10] Waiting for services to be healthy...${NC}"
echo "Waiting for CKAN to be ready (this may take 2-3 minutes)..."
for i in {1..60}; do
    if docker compose ps | grep -q "ckan.*healthy"; then
        echo -e "${GREEN}✓ CKAN is healthy${NC}"
        break
    fi
    if [ $i -eq 60 ]; then
        echo -e "${RED}ERROR: CKAN did not become healthy within 5 minutes${NC}"
        echo "Check logs with: docker compose logs ckan"
        exit 1
    fi
    sleep 5
    echo -n "."
done
echo ""

# Step 5: Apply session persistence fix
echo -e "${YELLOW}[5/10] Applying session persistence fix...${NC}"
if [ -f "fix_session.py" ]; then
    docker cp fix_session.py ${CKAN_CONTAINER}:/tmp/ 2>/dev/null || {
        echo -e "${YELLOW}Container name might be different, trying to find it...${NC}"
        CKAN_CONTAINER=$(docker compose ps -q ckan)
        if [ -z "$CKAN_CONTAINER" ]; then
            echo -e "${RED}ERROR: Could not find CKAN container${NC}"
            exit 1
        fi
        docker cp fix_session.py ${CKAN_CONTAINER}:/tmp/
    }
    
    docker exec -u root ${CKAN_CONTAINER} python3 /tmp/fix_session.py || {
        echo -e "${RED}ERROR: Failed to apply session fix${NC}"
        exit 1
    }
    echo -e "${GREEN}✓ Session fix applied${NC}"
else
    echo -e "${RED}ERROR: fix_session.py not found${NC}"
    exit 1
fi
echo ""

# Step 6: Apply ACS endpoint fix
echo -e "${YELLOW}[6/10] Applying ACS endpoint fix...${NC}"
if [ -f "fix_acs_endpoint.py" ]; then
    docker cp fix_acs_endpoint.py ${CKAN_CONTAINER}:/tmp/ 2>/dev/null || {
        docker cp fix_acs_endpoint.py ${CKAN_CONTAINER}:/tmp/
    }
    
    docker exec -u root ${CKAN_CONTAINER} python3 /tmp/fix_acs_endpoint.py || {
        echo -e "${RED}ERROR: Failed to apply ACS endpoint fix${NC}"
        exit 1
    }
    echo -e "${GREEN}✓ ACS endpoint fix applied${NC}"
else
    echo -e "${YELLOW}WARNING: fix_acs_endpoint.py not found (may not be needed)${NC}"
fi
echo ""

# Step 7: Enable file uploads
echo -e "${YELLOW}[7/10] Configuring file uploads...${NC}"
docker exec ${CKAN_CONTAINER} ckan -c /srv/app/ckan.ini config-tool /srv/app/ckan.ini "ckan.uploads_enabled = true" || true
docker exec ${CKAN_CONTAINER} ckan -c /srv/app/ckan.ini config-tool /srv/app/ckan.ini "ckan.storage_path = /var/lib/ckan/default" || true
docker exec -u root ${CKAN_CONTAINER} mkdir -p /var/lib/ckan/default/storage/uploads || true
docker exec -u root ${CKAN_CONTAINER} chown -R 503:502 /var/lib/ckan/default || true
echo -e "${GREEN}✓ File uploads configured${NC}"
echo ""

# Step 8: Restart CKAN to apply all fixes
echo -e "${YELLOW}[8/10] Restarting CKAN to apply fixes...${NC}"
docker compose restart ckan
echo "Waiting for CKAN to restart..."
sleep 20
echo -e "${GREEN}✓ CKAN restarted${NC}"
echo ""

# Step 9: Verify installation
echo -e "${YELLOW}[9/10] Verifying installation...${NC}"

# Check if session fix is applied
if docker exec ${CKAN_CONTAINER} grep -q "session_info_copy" /usr/local/lib/python3.10/site-packages/ckanext/saml2auth/cache.py 2>/dev/null; then
    echo -e "${GREEN}✓ Session fix verified${NC}"
else
    echo -e "${RED}WARNING: Session fix verification failed${NC}"
fi

# Check if ACS endpoint is fixed
if docker exec ${CKAN_CONTAINER} grep -q "acs_endpoint = '/saml2/acs'" /usr/local/lib/python3.10/site-packages/ckanext/saml2auth/views/saml2auth.py 2>/dev/null; then
    echo -e "${GREEN}✓ ACS endpoint fix verified${NC}"
else
    echo -e "${YELLOW}WARNING: ACS endpoint fix verification failed (may not be needed)${NC}"
fi

# Check services status
if docker compose ps | grep -q "Up"; then
    echo -e "${GREEN}✓ All services are running${NC}"
else
    echo -e "${RED}WARNING: Some services may not be running${NC}"
fi

echo ""

# Step 10: Final status
echo -e "${YELLOW}[10/10] Deployment Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Domain: ${GREEN}${DOMAIN}${NC}"
echo -e "Entity ID: ${GREEN}${ENTITY_ID}${NC}"
echo -e "Database: ${GREEN}postgres (s4idtcities network)${NC}"
echo ""
echo -e "${GREEN}✓ Deployment completed successfully!${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Update Keycloak client configuration:"
echo "   - Client ID: ${ENTITY_ID}"
echo "   - Valid Redirect URIs: https://${DOMAIN}/saml2/acs"
echo "   - Valid Post Logout Redirect URIs: https://${DOMAIN}/*"
echo "   - Web Origins: https://${DOMAIN}"
echo ""
echo "2. Test the installation:"
echo "   - Access: https://${DOMAIN}"
echo "   - Test login: https://${DOMAIN}/user/saml2login"
echo ""
echo "3. Check logs if needed:"
echo "   docker compose logs -f ckan"
echo ""
echo -e "${BLUE}========================================${NC}"


