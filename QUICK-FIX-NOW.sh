#!/bin/bash

# ========================================
# QUICK FIX - Run this to fix genesis.block directory issue
# Then continue with deployment
# ========================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    QUICK FIX - Genesis Block                     ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${YELLOW}Problem: genesis.block is a directory instead of a file${NC}"
echo -e "${YELLOW}Solution: Remove it properly and recreate${NC}\n"

# Step 1: Stop containers
echo -e "${YELLOW}[1/5] Stopping containers...${NC}"
docker-compose -f docker-compose-aws.yml down -v 2>/dev/null || true
docker rm -f orderer.example.com peer0.org1.example.com cli 2>/dev/null || true
echo -e "${GREEN}✓ Containers stopped${NC}"

# Step 2: Remove volumes
echo -e "\n${YELLOW}[2/5] Removing Docker volumes...${NC}"
docker volume rm fabric-network_ordererdata 2>/dev/null || true
docker volume rm fabric-network_peer0org1data 2>/dev/null || true
echo -e "${GREEN}✓ Volumes removed${NC}"

# Step 3: Fix genesis.block directory issue
echo -e "\n${YELLOW}[3/5] Fixing genesis.block directory issue...${NC}"

# Remove the problematic directory with sudo
if [ -d "./system-genesis-block/genesis.block" ]; then
    echo -e "${YELLOW}Found directory at genesis.block location. Removing with sudo...${NC}"
    sudo rm -rf ./system-genesis-block/genesis.block
    echo -e "${GREEN}✓ Removed genesis.block directory${NC}"
fi

# Clean entire directory
sudo rm -rf ./system-genesis-block
sudo rm -rf ./channel-artifacts

# Recreate with proper permissions
mkdir -p ./system-genesis-block
mkdir -p ./channel-artifacts
sudo chmod 777 ./system-genesis-block
sudo chmod 777 ./channel-artifacts

echo -e "${GREEN}✓ Directories cleaned and ready${NC}"

# Step 4: Start containers
echo -e "\n${YELLOW}[4/5] Starting containers...${NC}"
docker-compose -f docker-compose-aws.yml up -d
sleep 5
echo -e "${GREEN}✓ Containers started${NC}"

# Step 5: Verify
echo -e "\n${YELLOW}[5/5] Verifying containers...${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}"

echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                         FIX COMPLETE!                            ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                    NEXT STEPS                                   ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"

echo -e "\n${YELLOW}Now run these commands one by one:${NC}\n"

echo -e "${GREEN}# 1. Generate channel genesis block${NC}"
echo -e 'docker exec cli configtxgen \\'
echo -e '  -profile TwoOrgsApplicationGenesis \\'
echo -e '  -channelID mychannel \\'
echo -e '  -outputBlock ./channel-artifacts/mychannel.block \\'
echo -e '  -configPath /etc/hyperledger/fabric'
echo -e ""

echo -e "${GREEN}# 2. Join orderer to channel${NC}"
echo -e 'docker exec cli osnadmin channel join \\'
echo -e '  --channelID mychannel \\'
echo -e '  --config-block /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/mychannel.block \\'
echo -e '  -o orderer.example.com:7053 \\'
echo -e '  --ca-file /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \\'
echo -e '  --client-cert /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt \\'
echo -e '  --client-key /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key'
echo -e ""

echo -e "${GREEN}# 3. Join peer to channel${NC}"
echo -e 'docker exec cli bash -c "
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
peer channel join -b ./channel-artifacts/mychannel.block
"'
echo -e ""

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "\n${YELLOW}Copy and paste these commands one by one!${NC}\n"
