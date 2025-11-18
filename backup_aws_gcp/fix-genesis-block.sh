#!/bin/bash

# ========================================
# FIX GENESIS BLOCK DIRECTORY ISSUE
# This script fixes the "is a directory" problem
# ========================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}========================================${NC}"
echo -e "${RED}  FIX: Genesis Block Directory Issue${NC}"
echo -e "${RED}========================================${NC}"

# Step 1: Check current state
echo -e "\n${YELLOW}[1/6] Checking current state...${NC}"
if [ -e "./system-genesis-block/genesis.block" ]; then
    if [ -d "./system-genesis-block/genesis.block" ]; then
        echo -e "${RED}✗ genesis.block is a DIRECTORY (this is the problem!)${NC}"
        ls -la ./system-genesis-block/genesis.block/
    elif [ -f "./system-genesis-block/genesis.block" ]; then
        echo -e "${GREEN}✓ genesis.block is a file${NC}"
        ls -lh ./system-genesis-block/genesis.block
    fi
else
    echo -e "${YELLOW}⚠ genesis.block doesn't exist${NC}"
fi

# Step 2: Stop orderer if running
echo -e "\n${YELLOW}[2/6] Stopping orderer...${NC}"
docker stop orderer.example.com 2>/dev/null || true
docker rm orderer.example.com 2>/dev/null || true
echo -e "${GREEN}✓ Orderer stopped${NC}"

# Step 3: Remove the problematic directory/file
echo -e "\n${YELLOW}[3/6] Removing problematic genesis.block...${NC}"
rm -rf ./system-genesis-block/genesis.block
rm -rf ./system-genesis-block/*
echo -e "${GREEN}✓ Cleaned system-genesis-block directory${NC}"

# Step 4: Generate fresh genesis block
echo -e "\n${YELLOW}[4/6] Generating fresh genesis block...${NC}"
if ! docker ps | grep -q cli; then
    echo -e "${RED}✗ CLI container not running. Starting containers...${NC}"
    docker-compose -f docker-compose-aws.yml up -d cli peer0.org1.example.com
    sleep 3
fi

# Generate genesis block in CLI container's working directory
docker exec cli bash -c "
cd /opt/gopath/src/github.com/hyperledger/fabric/peer
configtxgen -profile TwoOrgsOrdererGenesis \
  -channelID system-channel \
  -outputBlock genesis.block \
  -configPath /etc/hyperledger/fabric
"

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to generate genesis block${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Genesis block generated in CLI container${NC}"

# Step 5: Copy genesis block as a FILE (not to a directory path)
echo -e "\n${YELLOW}[5/6] Copying genesis block to host...${NC}"

# Copy to temp location first
docker cp cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/genesis.block /tmp/genesis.block

# Move to correct location
mv /tmp/genesis.block ./system-genesis-block/genesis.block

# Verify it's a file
if [ -f "./system-genesis-block/genesis.block" ]; then
    echo -e "${GREEN}✓ Genesis block copied successfully as a FILE${NC}"
    ls -lh ./system-genesis-block/genesis.block
    file ./system-genesis-block/genesis.block
else
    echo -e "${RED}✗ Genesis block is not a file!${NC}"
    exit 1
fi

# Step 6: Start orderer
echo -e "\n${YELLOW}[6/6] Starting orderer...${NC}"
docker-compose -f docker-compose-aws.yml up -d orderer.example.com
sleep 5

# Check orderer status
if docker ps | grep -q orderer.example.com; then
    echo -e "${GREEN}✓ Orderer is running!${NC}"
    docker ps | grep orderer.example.com

    echo -e "\n${YELLOW}Checking orderer logs...${NC}"
    sleep 2
    docker logs orderer.example.com 2>&1 | tail -20

    if docker logs orderer.example.com 2>&1 | grep -q "Beginning to serve"; then
        echo -e "\n${GREEN}========================================${NC}"
        echo -e "${GREEN}  ✓ ORDERER IS WORKING!${NC}"
        echo -e "${GREEN}========================================${NC}"
    elif docker logs orderer.example.com 2>&1 | grep -q "panic"; then
        echo -e "\n${RED}========================================${NC}"
        echo -e "${RED}  ✗ ORDERER STILL PANICKING${NC}"
        echo -e "${RED}========================================${NC}"
        docker logs orderer.example.com 2>&1 | grep -A5 "panic"
    fi
else
    echo -e "${RED}✗ Orderer failed to start${NC}"
    echo -e "${YELLOW}Checking logs...${NC}"
    docker logs orderer.example.com 2>&1 || echo "No logs available"
fi

echo -e "\n${YELLOW}Next steps:${NC}"
echo -e "1. Run: ${GREEN}./diagnose.sh${NC}"
echo -e "2. Run: ${GREEN}./create-channel-aws.sh${NC}"
