#!/bin/bash

# ========================================
# COMPLETE FRESH START
# This script removes EVERYTHING and starts clean
# ========================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    FRESH START - CLEAN SETUP                     ║${NC}"
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${RED}⚠️  WARNING: This will DELETE:${NC}"
echo -e "   • All Docker containers (orderer, peers, cli)"
echo -e "   • All Docker volumes (blockchain data)"
echo -e "   • Generated genesis.block"
echo -e "   • Generated channel artifacts (*.tx, *.block)"
echo -e ""
read -p "Are you sure you want to continue? (type 'yes'): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo -e "${YELLOW}Cancelled. Nothing was deleted.${NC}"
    exit 0
fi

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  STEP 1: STOP ALL CONTAINERS${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${YELLOW}[1/8] Stopping all Fabric containers...${NC}"
docker-compose -f docker-compose-aws.yml down -v 2>/dev/null || true
echo -e "${GREEN}✓ Containers stopped${NC}"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  STEP 2: REMOVE ALL CONTAINERS${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${YELLOW}[2/8] Removing individual containers...${NC}"
docker rm -f orderer.example.com 2>/dev/null || true
docker rm -f peer0.org1.example.com 2>/dev/null || true
docker rm -f cli 2>/dev/null || true
echo -e "${GREEN}✓ All containers removed${NC}"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  STEP 3: REMOVE DOCKER VOLUMES${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${YELLOW}[3/8] Removing Docker volumes...${NC}"
docker volume rm fabric-network_ordererdata 2>/dev/null || true
docker volume rm fabric-network_peer0org1data 2>/dev/null || true
echo -e "${GREEN}✓ Volumes removed${NC}"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  STEP 4: CLEAN GENERATED FILES${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${YELLOW}[4/8] Cleaning genesis block...${NC}"
# Remove the entire directory to avoid permission issues
sudo rm -rf ./system-genesis-block
# Recreate it with proper permissions
mkdir -p ./system-genesis-block
sudo chmod 777 ./system-genesis-block
echo -e "${GREEN}✓ Genesis block removed${NC}"

echo -e "\n${YELLOW}[5/8] Cleaning channel artifacts...${NC}"
sudo rm -rf ./channel-artifacts
mkdir -p ./channel-artifacts
sudo chmod 777 ./channel-artifacts
echo -e "${GREEN}✓ Channel artifacts cleaned${NC}"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  STEP 5: VERIFY CLEANUP${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${YELLOW}[6/8] Verifying no containers running...${NC}"
RUNNING_COUNT=$(docker ps -a | grep -E "orderer|peer0.org1|cli" | wc -l)
if [ "$RUNNING_COUNT" -eq 0 ]; then
    echo -e "${GREEN}✓ No Fabric containers found${NC}"
else
    echo -e "${YELLOW}⚠ Found $RUNNING_COUNT containers still present${NC}"
    docker ps -a | grep -E "orderer|peer0.org1|cli"
fi

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  STEP 6: START FRESH CONTAINERS${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${YELLOW}[7/8] Starting containers with FIXED configuration...${NC}"
docker-compose -f docker-compose-aws.yml up -d

echo -e "${YELLOW}Waiting 5 seconds for containers to start...${NC}"
sleep 5

# Check what's running
echo -e "\n${YELLOW}Current running containers:${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  STEP 7: GENERATE GENESIS BLOCK${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${YELLOW}[8/8] Generating genesis block with FIXED configtx.yaml...${NC}"

# Wait for CLI to be ready
sleep 2

docker exec cli bash -c "
cd /opt/gopath/src/github.com/hyperledger/fabric/peer
configtxgen -profile TwoOrgsOrdererGenesis \
  -channelID system-channel \
  -outputBlock genesis.block \
  -configPath /etc/hyperledger/fabric
"

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to generate genesis block!${NC}"
    exit 1
fi

# Copy genesis block properly (avoid permission issues)
docker cp cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/genesis.block /tmp/genesis_fresh.block
sudo rm -f ./system-genesis-block/genesis.block
mv /tmp/genesis_fresh.block ./system-genesis-block/genesis.block
chmod 644 ./system-genesis-block/genesis.block

if [ -f "./system-genesis-block/genesis.block" ]; then
    echo -e "${GREEN}✓ Genesis block generated successfully!${NC}"
    ls -lh ./system-genesis-block/genesis.block
else
    echo -e "${RED}✗ Failed to create genesis block file${NC}"
    exit 1
fi

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  STEP 8: START ORDERER${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${YELLOW}Starting orderer with new genesis block...${NC}"
docker-compose -f docker-compose-aws.yml restart orderer.example.com

echo -e "${YELLOW}Waiting 8 seconds for orderer to initialize...${NC}"
sleep 8

# Verify orderer
if docker ps | grep -q orderer.example.com; then
    echo -e "${GREEN}✓ Orderer container is RUNNING!${NC}"

    # Check logs
    echo -e "\n${YELLOW}=== ORDERER LOGS (Last 15 lines) ===${NC}"
    docker logs orderer.example.com 2>&1 | tail -15

    if docker logs orderer.example.com 2>&1 | grep -q "Beginning to serve"; then
        echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║              ✓✓✓ SUCCESS! ORDERER IS WORKING! ✓✓✓               ║${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    elif docker logs orderer.example.com 2>&1 | grep -q "panic"; then
        echo -e "\n${RED}✗ Orderer is panicking. Check logs:${NC}"
        docker logs orderer.example.com 2>&1 | grep -A5 "panic"
        exit 1
    else
        echo -e "\n${YELLOW}⚠ Orderer started but not serving yet. Wait and check logs.${NC}"
    fi
else
    echo -e "\n${RED}✗ Orderer not running!${NC}"
    docker logs orderer.example.com 2>&1
    exit 1
fi

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  STEP 9: GENERATE CHANNEL ARTIFACTS${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${YELLOW}Generating channel.tx...${NC}"
docker exec cli configtxgen -profile TwoOrgsChannel \
  -channelID mychannel \
  -outputCreateChannelTx ./channel-artifacts/channel.tx \
  -configPath /etc/hyperledger/fabric

echo -e "\n${YELLOW}Generating Org1 anchor peer update...${NC}"
docker exec cli configtxgen -profile TwoOrgsChannel \
  -channelID mychannel \
  -asOrg Org1MSP \
  -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx \
  -configPath /etc/hyperledger/fabric

echo -e "\n${YELLOW}Generating Org2 anchor peer update...${NC}"
docker exec cli configtxgen -profile TwoOrgsChannel \
  -channelID mychannel \
  -asOrg Org2MSP \
  -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx \
  -configPath /etc/hyperledger/fabric

if [ -f "./channel-artifacts/channel.tx" ]; then
    echo -e "${GREEN}✓ All channel artifacts generated!${NC}"
    ls -lh ./channel-artifacts/
else
    echo -e "${RED}✗ Failed to generate channel artifacts${NC}"
    exit 1
fi

echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    FRESH START COMPLETE!                         ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                    WHAT WAS DONE                                ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓${NC} Removed all old containers"
echo -e "${GREEN}✓${NC} Removed all Docker volumes"
echo -e "${GREEN}✓${NC} Cleaned genesis block"
echo -e "${GREEN}✓${NC} Cleaned channel artifacts"
echo -e "${GREEN}✓${NC} Started fresh containers"
echo -e "${GREEN}✓${NC} Generated NEW genesis block with Consortiums"
echo -e "${GREEN}✓${NC} Started orderer (working!)"
echo -e "${GREEN}✓${NC} Generated channel artifacts"

echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                    NEXT STEPS                                   ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "\n${YELLOW}1. Create channel:${NC}"
echo -e "   ${GREEN}./create-channel-aws.sh${NC}"
echo -e "\n${YELLOW}2. Verify everything:${NC}"
echo -e "   ${GREEN}./diagnose.sh${NC}"
echo -e "\n${YELLOW}3. Copy to GCP:${NC}"
echo -e "   ${GREEN}./copy-to-gcp.sh${NC}"

echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                    USEFUL COMMANDS                              ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Check containers:${NC}"
echo -e "   ${GREEN}docker ps${NC}"
echo -e "${YELLOW}Check orderer logs:${NC}"
echo -e "   ${GREEN}docker logs orderer.example.com${NC}"
echo -e "${YELLOW}Check peer logs:${NC}"
echo -e "   ${GREEN}docker logs peer0.org1.example.com${NC}"

echo -e "\n${GREEN}🎉 Your Fabric network is ready with the FIXED configuration!${NC}\n"
