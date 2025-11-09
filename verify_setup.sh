#!/bin/bash

###############################################################################
# CKAN Setup Verification Script
# Verifies all configurations are correct before deployment
###############################################################################

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOMAIN="datagate.snap4idtcity.com"
ENTITY_ID="https://${DOMAIN}/saml2/metadata"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  CKAN Setup Verification${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

ERRORS=0

# Check 1: Domain in docker-compose.yml
echo -e "${YELLOW}[1/8] Checking domain configuration...${NC}"
if grep -q "datagate.snap4idtcity.com" docker-compose.yml; then
    echo -e "${GREEN}✓ Domain configured correctly${NC}"
else
    echo -e "${RED}✗ Domain not found in docker-compose.yml${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check 2: Entity ID in docker-compose.yml
if grep -q "${ENTITY_ID}" docker-compose.yml; then
    echo -e "${GREEN}✓ Entity ID configured correctly${NC}"
else
    echo -e "${RED}✗ Entity ID not found in docker-compose.yml${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check 3: Database configuration
echo -e "${YELLOW}[2/8] Checking database configuration...${NC}"
if grep -q "postgres:5432" docker-compose.yml; then
    echo -e "${GREEN}✓ Database host configured correctly${NC}"
else
    echo -e "${RED}✗ Database host not configured correctly${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check 4: Required files exist
echo -e "${YELLOW}[3/8] Checking required files...${NC}"
REQUIRED_FILES=(
    "docker-compose.yml"
    "Dockerfile.custom"
    "fix_session.py"
    "fix_acs_endpoint.py"
    "ckan/setup/prerun.py.override"
    "nginx/setup/default.conf"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓ $file exists${NC}"
    else
        echo -e "${RED}✗ $file missing${NC}"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check 5: Nginx server_name
echo -e "${YELLOW}[4/8] Checking Nginx configuration...${NC}"
if grep -q "server_name.*datagate.snap4idtcity.com" nginx/setup/default.conf; then
    echo -e "${GREEN}✓ Nginx server_name configured correctly${NC}"
else
    echo -e "${RED}✗ Nginx server_name not configured correctly${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check 6: Docker network
echo -e "${YELLOW}[5/8] Checking Docker network...${NC}"
if docker network inspect s4idtcities &> /dev/null; then
    echo -e "${GREEN}✓ Docker network 's4idtcities' exists${NC}"
else
    echo -e "${YELLOW}⚠ Docker network 's4idtcities' does not exist (will be created)${NC}"
fi

# Check 7: .env file
echo -e "${YELLOW}[6/8] Checking environment file...${NC}"
if [ -f ".env" ]; then
    echo -e "${GREEN}✓ .env file exists${NC}"
    if grep -q "datagate.snap4idtcity.com" .env 2>/dev/null; then
        echo -e "${GREEN}✓ Domain in .env file${NC}"
    else
        echo -e "${YELLOW}⚠ Domain not found in .env (may be in docker-compose.yml)${NC}"
    fi
else
    echo -e "${YELLOW}⚠ .env file not found (create from .env.example)${NC}"
fi

# Check 8: Fix scripts are executable
echo -e "${YELLOW}[7/8] Checking fix scripts...${NC}"
if [ -x "fix_session.py" ] || [ -f "fix_session.py" ]; then
    echo -e "${GREEN}✓ fix_session.py ready${NC}"
else
    echo -e "${RED}✗ fix_session.py not accessible${NC}"
    ERRORS=$((ERRORS + 1))
fi

if [ -x "fix_acs_endpoint.py" ] || [ -f "fix_acs_endpoint.py" ]; then
    echo -e "${GREEN}✓ fix_acs_endpoint.py ready${NC}"
else
    echo -e "${YELLOW}⚠ fix_acs_endpoint.py not found (may not be needed)${NC}"
fi

# Check 9: Docker and Docker Compose
echo -e "${YELLOW}[8/8] Checking Docker installation...${NC}"
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓ Docker installed${NC}"
    docker --version
else
    echo -e "${RED}✗ Docker not installed${NC}"
    ERRORS=$((ERRORS + 1))
fi

if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
    echo -e "${GREEN}✓ Docker Compose installed${NC}"
else
    echo -e "${RED}✗ Docker Compose not installed${NC}"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo -e "${BLUE}========================================${NC}"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed! Ready to deploy.${NC}"
    echo ""
    echo "Next step: Run ./deploy.sh"
    exit 0
else
    echo -e "${RED}✗ Found $ERRORS error(s). Please fix before deploying.${NC}"
    exit 1
fi


