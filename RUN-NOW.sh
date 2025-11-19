#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║       FABRIC 2.3+ DEPLOYMENT - NO GENESIS BLOCK NEEDED          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"

# STEP 1: CLEANUP
echo -e "\n${YELLOW}[1/7] Cleanup...${NC}"
docker-compose -f docker-compose-aws.yml down -v 2>/dev/null || true
docker volume rm fabric-network_ordererdata fabric-network_peer0org1data 2>/dev/null || true
rm -rf ./channel-artifacts/*
mkdir -p ./channel-artifacts
echo -e "${GREEN}✓ Cleanup done${NC}"

# STEP 2: START CONTAINERS
echo -e "\n${YELLOW}[2/7] Starting containers...${NC}"
docker-compose -f docker-compose-aws.yml up -d
sleep 10
docker ps
echo -e "${GREEN}✓ Containers started${NC}"

# STEP 3: VERIFY ORDERER IS RUNNING
echo -e "\n${YELLOW}[3/7] Checking orderer...${NC}"
if ! docker ps | grep -q orderer.example.com; then
    echo -e "${RED}✗ Orderer not running!${NC}"
    docker logs orderer.example.com
    exit 1
fi
echo -e "${GREEN}✓ Orderer is running${NC}"

# STEP 4: GENERATE CHANNEL GENESIS
echo -e "\n${YELLOW}[4/7] Generating channel genesis block...${NC}"
docker exec cli configtxgen \
  -profile TwoOrgsApplicationGenesis \
  -channelID mychannel \
  -outputBlock ./channel-artifacts/mychannel.block \
  -configPath /etc/hyperledger/fabric

docker exec cli ls -lh ./channel-artifacts/mychannel.block
echo -e "${GREEN}✓ Channel genesis created${NC}"

# STEP 5: JOIN ORDERER TO CHANNEL
echo -e "\n${YELLOW}[5/7] Joining orderer to channel (osnadmin)...${NC}"
sleep 3
docker exec cli osnadmin channel join \
  --channelID mychannel \
  --config-block /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/mychannel.block \
  -o orderer.example.com:7053 \
  --ca-file /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  --client-cert /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt \
  --client-key /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key

echo -e "${GREEN}✓ Orderer joined${NC}"

# STEP 6: JOIN PEER TO CHANNEL
echo -e "\n${YELLOW}[6/7] Joining peer to channel...${NC}"
docker exec cli bash -c '
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
peer channel join -b ./channel-artifacts/mychannel.block
'
echo -e "${GREEN}✓ Peer joined${NC}"

# STEP 7: VERIFY
echo -e "\n${YELLOW}[7/7] Verification...${NC}"
echo -e "${YELLOW}Orderer channels:${NC}"
docker exec cli osnadmin channel list \
  -o orderer.example.com:7053 \
  --ca-file /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  --client-cert /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt \
  --client-key /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key

echo -e "\n${YELLOW}Peer channels:${NC}"
docker exec cli peer channel list

echo -e "\n${YELLOW}Channel info:${NC}"
docker exec cli bash -c '
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
peer channel getinfo -c mychannel
'

echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                       ✓✓✓ SUCCESS! ✓✓✓                           ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${GREEN}Your Fabric network is ready!${NC}"
echo -e "${YELLOW}Containers:${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}"
