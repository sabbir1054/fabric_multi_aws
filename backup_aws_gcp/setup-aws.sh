#!/bin/bash

# ========================================
# AWS SIDE SETUP SCRIPT
# This script sets up Hyperledger Fabric on AWS
# Components: Orderer + Peer0.Org1 + CLI
# ========================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  AWS Fabric Network Setup Script${NC}"
echo -e "${GREEN}========================================${NC}"

# Step 1: Check if docker-compose is installed
echo -e "\n${YELLOW}[1/8] Checking Docker & Docker Compose...${NC}"
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
echo -e "\n${YELLOW}[2/8] Stopping existing containers (if any)...${NC}"
docker-compose -f docker-compose-aws.yml down 2>/dev/null || true
echo -e "${GREEN}✓ Existing containers stopped${NC}"

# Step 3: Clean up old volumes (optional - uncomment if needed)
# echo -e "\n${YELLOW}[3/8] Cleaning up old volumes...${NC}"
# docker volume rm fabric-network_ordererdata 2>/dev/null || true

# Step 4: Check if organizations and crypto materials exist
echo -e "\n${YELLOW}[3/8] Checking crypto materials...${NC}"
if [ ! -d "./organizations/ordererOrganizations" ] || [ ! -d "./organizations/peerOrganizations" ]; then
    echo -e "${RED}Error: Crypto materials not found!${NC}"
    echo -e "${YELLOW}Please generate crypto materials first using cryptogen or fabric-ca${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Crypto materials found${NC}"

# Step 5: Create system-genesis-block directory if not exists
echo -e "\n${YELLOW}[4/8] Creating required directories...${NC}"
mkdir -p ./system-genesis-block
mkdir -p ./channel-artifacts
echo -e "${GREEN}✓ Directories created${NC}"

# Step 6: Start Docker containers
echo -e "\n${YELLOW}[5/8] Starting Docker containers...${NC}"
docker-compose -f docker-compose-aws.yml up -d
sleep 5
echo -e "${GREEN}✓ Containers started${NC}"

# Step 7: Check container status
echo -e "\n${YELLOW}[6/8] Checking container status...${NC}"
docker ps --filter "name=orderer.example.com" --filter "name=peer0.org1.example.com" --filter "name=cli"
echo -e "${GREEN}✓ Containers are running${NC}"

# Step 8: Generate Genesis Block
echo -e "\n${YELLOW}[7/8] Generating genesis block...${NC}"

# CRITICAL: Completely clean the system-genesis-block directory
# to avoid "is a directory" error
echo -e "${YELLOW}Cleaning system-genesis-block directory...${NC}"
rm -rf ./system-genesis-block/*
mkdir -p ./system-genesis-block

# Generate genesis block inside CLI container
echo -e "${YELLOW}Generating genesis block with configtxgen...${NC}"
docker exec cli bash -c "
cd /opt/gopath/src/github.com/hyperledger/fabric/peer
configtxgen -profile TwoOrgsOrdererGenesis \
    -channelID system-channel \
    -outputBlock genesis.block \
    -configPath /etc/hyperledger/fabric
"

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to generate genesis block with configtxgen${NC}"
    exit 1
fi

# Copy to temp location first to ensure we get a FILE, not a directory
echo -e "${YELLOW}Copying genesis block to host...${NC}"
docker cp cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/genesis.block /tmp/genesis.block.tmp

# Move to final location
mv /tmp/genesis.block.tmp ./system-genesis-block/genesis.block

# Verify it's a FILE (not a directory)
if [ -f "./system-genesis-block/genesis.block" ] && [ ! -d "./system-genesis-block/genesis.block" ]; then
    echo -e "${GREEN}✓ Genesis block generated successfully as a FILE${NC}"
    ls -lh ./system-genesis-block/genesis.block
    file ./system-genesis-block/genesis.block
else
    echo -e "${RED}✗ Genesis block is not a proper file!${NC}"
    echo -e "${YELLOW}Contents of system-genesis-block:${NC}"
    ls -la ./system-genesis-block/
    exit 1
fi

# Restart orderer to pick up the new genesis block
echo -e "${YELLOW}Restarting orderer with new genesis block...${NC}"
docker-compose -f docker-compose-aws.yml restart orderer.example.com
sleep 3

# Step 9: Generate Channel Artifacts
echo -e "\n${YELLOW}[8/8] Generating channel artifacts...${NC}"

# Generate channel.tx
docker exec cli configtxgen -profile TwoOrgsChannel \
    -channelID mychannel \
    -outputCreateChannelTx ./channel-artifacts/channel.tx \
    -configPath /etc/hyperledger/fabric

# Generate anchor peer updates for Org1
docker exec cli configtxgen -profile TwoOrgsChannel \
    -channelID mychannel \
    -asOrg Org1MSP \
    -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx \
    -configPath /etc/hyperledger/fabric

# Generate anchor peer updates for Org2
docker exec cli configtxgen -profile TwoOrgsChannel \
    -channelID mychannel \
    -asOrg Org2MSP \
    -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx \
    -configPath /etc/hyperledger/fabric

echo -e "${GREEN}✓ Channel artifacts generated${NC}"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  AWS Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\n${YELLOW}Next Steps:${NC}"
echo -e "1. Run './create-channel-aws.sh' to create the channel"
echo -e "2. Copy artifacts to GCP using './copy-to-gcp.sh'"
echo -e "3. Run setup on GCP side"
echo -e "\n${YELLOW}To view logs:${NC}"
echo -e "docker logs -f orderer.example.com"
echo -e "docker logs -f peer0.org1.example.com"
