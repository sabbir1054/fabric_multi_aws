#!/bin/bash

# ========================================
# CLEANUP SCRIPT FOR AWS
# Removes all containers, volumes, and generated files
# ========================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  Cleanup Script for AWS${NC}"
echo -e "${YELLOW}========================================${NC}"

echo -e "\n${RED}WARNING: This will remove all containers, volumes, and generated artifacts!${NC}"
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo -e "${YELLOW}Cleanup cancelled.${NC}"
    exit 0
fi

# Step 1: Stop and remove containers
echo -e "\n${YELLOW}[1/5] Stopping containers...${NC}"
docker-compose -f docker-compose-aws.yml down -v 2>/dev/null || true
echo -e "${GREEN}✓ Containers stopped${NC}"

# Step 2: Remove any leftover containers
echo -e "\n${YELLOW}[2/5] Removing leftover containers...${NC}"
docker rm -f orderer.example.com peer0.org1.example.com cli 2>/dev/null || true
echo -e "${GREEN}✓ Leftover containers removed${NC}"

# Step 3: Clean up generated files
echo -e "\n${YELLOW}[3/5] Cleaning up generated files...${NC}"
rm -rf ./system-genesis-block/genesis.block
rm -rf ./channel-artifacts/*.block
rm -rf ./channel-artifacts/*.tx
echo -e "${GREEN}✓ Generated files cleaned${NC}"

# Step 4: Remove Docker volumes
echo -e "\n${YELLOW}[4/5] Removing Docker volumes...${NC}"
docker volume rm fabric-network_ordererdata 2>/dev/null || true
docker volume rm fabric-network_peer0org1data 2>/dev/null || true
echo -e "${GREEN}✓ Volumes removed${NC}"

# Step 5: Verify cleanup
echo -e "\n${YELLOW}[5/5] Verifying cleanup...${NC}"
if docker ps -a | grep -E "orderer.example.com|peer0.org1.example.com|cli"; then
    echo -e "${RED}✗ Some containers still exist${NC}"
else
    echo -e "${GREEN}✓ All containers removed${NC}"
fi

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Cleanup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\n${YELLOW}Next Steps:${NC}"
echo -e "1. Run: ${GREEN}./setup-aws.sh${NC}"
echo -e "2. Run: ${GREEN}./create-channel-aws.sh${NC}"
echo -e "3. Verify: ${GREEN}./diagnose.sh${NC}"
