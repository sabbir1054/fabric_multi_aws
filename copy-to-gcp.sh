#!/bin/bash

# ========================================
# COPY ARTIFACTS TO GCP
# This script copies necessary files to GCP
# ========================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Copy Artifacts to GCP${NC}"
echo -e "${GREEN}========================================${NC}"

# Configuration - EDIT THESE VALUES
GCP_USER="ubuntu"
GCP_IP="178.16.139.239"
GCP_PATH="~/fabric-network"

echo -e "\n${YELLOW}Target GCP Machine:${NC}"
echo -e "  User: ${GCP_USER}"
echo -e "  IP: ${GCP_IP}"
echo -e "  Path: ${GCP_PATH}"
echo -e ""

read -p "Is this correct? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Please edit this script and update GCP_USER, GCP_IP, and GCP_PATH${NC}"
    exit 1
fi

# Step 1: Copy organizations directory (crypto materials)
echo -e "\n${YELLOW}[1/5] Copying organizations (crypto materials)...${NC}"
scp -r ./organizations ${GCP_USER}@${GCP_IP}:${GCP_PATH}/
echo -e "${GREEN}✓ Organizations copied${NC}"

# Step 2: Copy channel artifacts
echo -e "\n${YELLOW}[2/5] Copying channel artifacts...${NC}"
scp -r ./channel-artifacts ${GCP_USER}@${GCP_IP}:${GCP_PATH}/
echo -e "${GREEN}✓ Channel artifacts copied${NC}"

# Step 3: Copy configtx directory
echo -e "\n${YELLOW}[3/5] Copying configtx...${NC}"
scp -r ./configtx ${GCP_USER}@${GCP_IP}:${GCP_PATH}/
echo -e "${GREEN}✓ Configtx copied${NC}"

# Step 4: Copy chaincode
echo -e "\n${YELLOW}[4/5] Copying chaincode...${NC}"
scp -r ./chaincode ${GCP_USER}@${GCP_IP}:${GCP_PATH}/
echo -e "${GREEN}✓ Chaincode copied${NC}"

# Step 5: Copy docker-compose and scripts
echo -e "\n${YELLOW}[5/5] Copying docker-compose and scripts...${NC}"
scp ./docker-compose-gcp.yml ${GCP_USER}@${GCP_IP}:${GCP_PATH}/
scp ./setup-gcp.sh ${GCP_USER}@${GCP_IP}:${GCP_PATH}/
scp ./join-channel-gcp.sh ${GCP_USER}@${GCP_IP}:${GCP_PATH}/
echo -e "${GREEN}✓ Docker compose and scripts copied${NC}"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  All Artifacts Copied Successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\n${YELLOW}Next Steps:${NC}"
echo -e "1. SSH to GCP: ssh ${GCP_USER}@${GCP_IP}"
echo -e "2. cd ${GCP_PATH}"
echo -e "3. chmod +x *.sh"
echo -e "4. Run: ./setup-gcp.sh"
echo -e "5. Run: ./join-channel-gcp.sh"
