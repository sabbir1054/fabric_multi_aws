#!/bin/bash

# Regenerate genesis block with FIXED configtx.yaml

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Regenerating Genesis Block${NC}"
echo -e "${GREEN}  (Fixed: Added Consortiums)${NC}"
echo -e "${GREEN}========================================${NC}"

# Step 1: Stop and remove orderer
echo -e "\n${YELLOW}[1/5] Stopping orderer...${NC}"
docker stop orderer.example.com 2>/dev/null || true
docker rm orderer.example.com 2>/dev/null || true
echo -e "${GREEN}✓ Orderer removed${NC}"

# Step 2: Delete old genesis block
echo -e "\n${YELLOW}[2/5] Removing old genesis block...${NC}"
rm -rf ./system-genesis-block/*
mkdir -p ./system-genesis-block
echo -e "${GREEN}✓ Old genesis block removed${NC}"

# Step 3: Make sure CLI is running
echo -e "\n${YELLOW}[3/5] Ensuring CLI is running...${NC}"
if ! docker ps | grep -q cli; then
    docker-compose -f docker-compose-aws.yml up -d cli
    sleep 3
fi
echo -e "${GREEN}✓ CLI is running${NC}"

# Step 4: Generate NEW genesis block with FIXED configtx.yaml
echo -e "\n${YELLOW}[4/5] Generating NEW genesis block with Consortiums...${NC}"
docker exec cli bash -c "
cd /opt/gopath/src/github.com/hyperledger/fabric/peer
configtxgen -profile TwoOrgsOrdererGenesis \
  -channelID system-channel \
  -outputBlock genesis.block \
  -configPath /etc/hyperledger/fabric
"

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to generate genesis block!${NC}"
    echo -e "${YELLOW}Check configtx.yaml for errors${NC}"
    exit 1
fi

# Copy to host properly
docker cp cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/genesis.block /tmp/genesis_new.block
mv /tmp/genesis_new.block ./system-genesis-block/genesis.block

# Verify
if [ -f "./system-genesis-block/genesis.block" ]; then
    echo -e "${GREEN}✓ Genesis block regenerated successfully!${NC}"
    ls -lh ./system-genesis-block/genesis.block
else
    echo -e "${RED}✗ Failed to create genesis block file${NC}"
    exit 1
fi

# Step 5: Start orderer with NEW genesis block
echo -e "\n${YELLOW}[5/5] Starting orderer with new genesis block...${NC}"
docker-compose -f docker-compose-aws.yml up -d orderer.example.com

echo -e "${YELLOW}Waiting 8 seconds for orderer to start...${NC}"
sleep 8

# Check if orderer is running
if docker ps | grep -q orderer.example.com; then
    echo -e "${GREEN}✓ Orderer is RUNNING!${NC}"
    docker ps | grep orderer

    echo -e "\n${YELLOW}Checking orderer logs...${NC}"
    docker logs orderer.example.com 2>&1 | tail -20

    if docker logs orderer.example.com 2>&1 | grep -q "Beginning to serve"; then
        echo -e "\n${GREEN}========================================${NC}"
        echo -e "${GREEN}  ✓✓✓ ORDERER IS WORKING! ✓✓✓${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo -e "\n${YELLOW}Next steps:${NC}"
        echo -e "1. Run: ${GREEN}./create-channel-aws.sh${NC}"
        echo -e "2. Run: ${GREEN}./diagnose.sh${NC}"
    elif docker logs orderer.example.com 2>&1 | grep -q "panic"; then
        echo -e "\n${RED}========================================${NC}"
        echo -e "${RED}  ✗ ORDERER STILL PANICKING${NC}"
        echo -e "${RED}========================================${NC}"
        docker logs orderer.example.com 2>&1 | grep -A5 "panic"
        echo -e "\n${YELLOW}Check full logs:${NC}"
        echo -e "${GREEN}docker logs orderer.example.com${NC}"
    else
        echo -e "\n${YELLOW}Orderer started but not serving yet...${NC}"
        echo -e "${YELLOW}Wait 10 more seconds and check:${NC}"
        echo -e "${GREEN}docker logs orderer.example.com${NC}"
    fi
else
    echo -e "\n${RED}========================================${NC}"
    echo -e "${RED}  ✗ ORDERER FAILED TO START${NC}"
    echo -e "${RED}========================================${NC}"
    docker logs orderer.example.com 2>&1
fi
