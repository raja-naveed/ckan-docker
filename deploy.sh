#!/bin/bash

###############################################################################
# Complete CKAN Deployment Script
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

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  CKAN Deployment Script${NC}"
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

# Step 5: Apply CKAN configuration
echo -e "${YELLOW}[5/7] Applying CKAN configuration...${NC}"
docker exec ${CKAN_CONTAINER} ckan -c /srv/app/ckan.ini config-tool /srv/app/ckan.ini \
  "ckan.uploads_enabled = true" \
  "ckan.storage_path = /var/lib/ckan/default" \
  "ckan.site_url = https://${DOMAIN}" \
  "ckan.auth.login_view = user.login" \
  "ckan.plugins = image_view text_view datatables_view pdf_view geo_view geojson_view shp_view wmts_view video_view audio_view webpage_view resource_proxy datastore xloader envvars custom_theme" \
  "ckan.views.default_views = datatables_view"

# Remove any legacy SAML configuration that might remain
docker exec ${CKAN_CONTAINER} ckan -c /srv/app/ckan.ini config-tool /srv/app/ckan.ini \
  "ckanext.saml2auth.idp_metadata.location =" \
  "ckanext.saml2auth.idp_metadata.remote_url =" \
  "ckanext.saml2auth.entity_id =" \
  "ckanext.saml2auth.acs_endpoint =" \
  "ckanext.saml2auth.user_email =" \
  "ckanext.saml2auth.user_firstname =" \
  "ckanext.saml2auth.user_lastname =" \
  "ckanext.saml2auth.user_fullname =" \
  "ckanext.saml2auth.enable_ckan_internal_login =" \
  "ckanext.saml2auth.want_response_signed =" \
  "ckanext.saml2auth.want_assertions_signed =" \
  "ckanext.saml2auth.assertion_consumer_service_binding =" \
  "ckanext.saml2auth.sp.name_id_format ="

docker exec -u root ${CKAN_CONTAINER} mkdir -p /var/lib/ckan/default/storage/uploads || true
docker exec -u root ${CKAN_CONTAINER} chown -R 503:502 /var/lib/ckan/default || true
echo -e "${GREEN}✓ CKAN configuration applied${NC}"
echo ""

# Step 6: Restart CKAN to apply all changes
echo -e "${YELLOW}[6/7] Restarting CKAN to apply changes...${NC}"
docker compose restart ckan
echo "Waiting for CKAN to restart..."
sleep 20
echo -e "${GREEN}✓ CKAN restarted${NC}"
echo ""

# Step 7: Final status
echo -e "${YELLOW}[7/7] Deployment Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Domain: ${GREEN}${DOMAIN}${NC}"
echo -e "Database: ${GREEN}postgres (s4idtcities network)${NC}"
echo ""
echo -e "${GREEN}✓ Deployment completed successfully!${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Access CKAN: https://${DOMAIN}"
echo "2. Log in using the built-in CKAN login page: https://${DOMAIN}/user/login"
echo "3. Check logs if needed:"
echo "   docker compose logs -f ckan"
echo ""
echo -e "${BLUE}========================================${NC}"


