#!/bin/bash

# ========================================
# GCP SIDE SETUP SCRIPT
# This script sets up Hyperledger Fabric on GCP
# Components: Peer0.Org2 + CLI
# ========================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  GCP Fabric Network Setup Script${NC}"
echo -e "${GREEN}========================================${NC}"

# Step 1: Check if docker-compose is installed
echo -e "\n${YELLOW}[1/5] Checking Docker & Docker Compose...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed!${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Error: Docker Compose is not installed!${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker and Docker Compose are installed${NC}"

# Step 2: Stop any existing containers
echo -e "\n${YELLOW}[2/5] Stopping existing containers (if any)...${NC}"
docker-compose -f docker-compose-gcp.yml down 2>/dev/null || true
echo -e "${GREEN}✓ Existing containers stopped${NC}"

# Step 3: Check if organizations and crypto materials exist
echo -e "\n${YELLOW}[3/5] Checking crypto materials...${NC}"
if [ ! -d "./organizations/peerOrganizations/org2.example.com" ]; then
    echo -e "${RED}Error: Org2 crypto materials not found!${NC}"
    echo -e "${YELLOW}Please copy artifacts from AWS first${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Crypto materials found${NC}"

# Step 4: Check if channel artifacts exist
echo -e "\n${YELLOW}[4/5] Checking channel artifacts...${NC}"
if [ ! -d "./channel-artifacts" ]; then
    echo -e "${RED}Error: Channel artifacts not found!${NC}"
    echo -e "${YELLOW}Please copy artifacts from AWS first${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Channel artifacts found${NC}"

# Step 5: Start Docker containers
echo -e "\n${YELLOW}[5/5] Starting Docker containers...${NC}"
docker-compose -f docker-compose-gcp.yml up -d
sleep 5
echo -e "${GREEN}✓ Containers started${NC}"

# Check container status
echo -e "\n${YELLOW}Checking container status...${NC}"
docker ps --filter "name=peer0.org2.example.com" --filter "name=cli_org2"
echo -e "${GREEN}✓ Containers are running${NC}"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  GCP Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\n${YELLOW}Next Steps:${NC}"
echo -e "1. Run './join-channel-gcp.sh' to join Org2 peer to the channel"
echo -e "\n${YELLOW}To view logs:${NC}"
echo -e "docker logs -f peer0.org2.example.com"
echo -e "docker logs -f cli_org2"
