#!/bin/bash

# ========================================
# CLEANUP SCRIPT FOR GCP
# Removes all containers, volumes, and generated files
# ========================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  Cleanup Script for GCP${NC}"
echo -e "${YELLOW}========================================${NC}"

echo -e "\n${RED}WARNING: This will remove all containers, volumes, and generated artifacts!${NC}"
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo -e "${YELLOW}Cleanup cancelled.${NC}"
    exit 0
fi

# Step 1: Stop and remove containers
echo -e "\n${YELLOW}[1/4] Stopping containers...${NC}"
docker-compose -f docker-compose-gcp.yml down -v 2>/dev/null || true
echo -e "${GREEN}✓ Containers stopped${NC}"

# Step 2: Remove any leftover containers
echo -e "\n${YELLOW}[2/4] Removing leftover containers...${NC}"
docker rm -f peer0.org2.example.com cli_org2 2>/dev/null || true
echo -e "${GREEN}✓ Leftover containers removed${NC}"

# Step 3: Remove Docker volumes
echo -e "\n${YELLOW}[3/4] Removing Docker volumes...${NC}"
docker volume rm fabric-network_peer0org2data 2>/dev/null || true
echo -e "${GREEN}✓ Volumes removed${NC}"

# Step 4: Verify cleanup
echo -e "\n${YELLOW}[4/4] Verifying cleanup...${NC}"
if docker ps -a | grep -E "peer0.org2.example.com|cli_org2"; then
    echo -e "${RED}✗ Some containers still exist${NC}"
else
    echo -e "${GREEN}✓ All containers removed${NC}"
fi

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Cleanup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\n${YELLOW}Next Steps:${NC}"
echo -e "1. Copy artifacts from AWS if needed"
echo -e "2. Run: ${GREEN}./setup-gcp.sh${NC}"
echo -e "3. Run: ${GREEN}./join-channel-gcp.sh${NC}"
echo -e "4. Verify: ${GREEN}./diagnose.sh${NC}"
