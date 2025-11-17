#!/bin/bash

# ========================================
# CREATE CHANNEL ON AWS
# This script creates the channel and joins Org1 peer
# ========================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Create Channel & Join Org1 Peer${NC}"
echo -e "${GREEN}========================================${NC}"

# Step 1: Set environment for Org1
echo -e "\n${YELLOW}[1/3] Creating channel 'mychannel'...${NC}"
docker exec cli bash -c "
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt

peer channel create \
  -o orderer.example.com:7050 \
  -c mychannel \
  -f ./channel-artifacts/channel.tx \
  --outputBlock ./channel-artifacts/mychannel.block \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls \
  --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Channel created successfully${NC}"
else
    echo -e "${RED}✗ Failed to create channel${NC}"
    exit 1
fi

# Step 2: Join Org1 Peer to the channel
echo -e "\n${YELLOW}[2/3] Joining Org1 peer to channel...${NC}"
docker exec cli bash -c "
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt

peer channel join -b ./channel-artifacts/mychannel.block
"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Org1 peer joined successfully${NC}"
else
    echo -e "${RED}✗ Failed to join Org1 peer${NC}"
    exit 1
fi

# Step 3: Update anchor peer for Org1
echo -e "\n${YELLOW}[3/3] Updating anchor peer for Org1...${NC}"
docker exec cli bash -c "
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt

peer channel update \
  -o orderer.example.com:7050 \
  -c mychannel \
  -f ./channel-artifacts/Org1MSPanchors.tx \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls \
  --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Anchor peer updated successfully${NC}"
else
    echo -e "${YELLOW}⚠ Warning: Anchor peer update failed (may not be critical)${NC}"
fi

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Channel Setup Complete on AWS!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\n${YELLOW}Next Steps:${NC}"
echo -e "1. Copy mychannel.block to GCP using './copy-to-gcp.sh'"
echo -e "2. Run './join-channel-gcp.sh' on GCP machine"
echo -e "\n${YELLOW}To verify:${NC}"
echo -e "docker exec cli peer channel list"
echo -e "docker exec cli peer channel getinfo -c mychannel"
