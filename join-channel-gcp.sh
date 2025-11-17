#!/bin/bash

# ========================================
# JOIN CHANNEL ON GCP
# This script joins Org2 peer to the channel
# ========================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Join Org2 Peer to Channel${NC}"
echo -e "${GREEN}========================================${NC}"

# Step 1: Check if mychannel.block exists
echo -e "\n${YELLOW}[1/3] Checking for mychannel.block...${NC}"
if [ ! -f "./channel-artifacts/mychannel.block" ]; then
    echo -e "${RED}Error: mychannel.block not found!${NC}"
    echo -e "${YELLOW}Please copy it from AWS first${NC}"
    exit 1
fi
echo -e "${GREEN}✓ mychannel.block found${NC}"

# Step 2: Join Org2 Peer to the channel
echo -e "\n${YELLOW}[2/3] Joining Org2 peer to channel...${NC}"
docker exec cli_org2 bash -c "
export CORE_PEER_LOCALMSPID=Org2MSP
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=peer0.org2.example.com:7051

peer channel join -b ./channel-artifacts/mychannel.block
"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Org2 peer joined successfully${NC}"
else
    echo -e "${RED}✗ Failed to join Org2 peer${NC}"
    exit 1
fi

# Step 3: Update anchor peer for Org2
echo -e "\n${YELLOW}[3/3] Updating anchor peer for Org2...${NC}"
docker exec cli_org2 bash -c "
export CORE_PEER_LOCALMSPID=Org2MSP
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=peer0.org2.example.com:7051

peer channel update \
  -o orderer.example.com:7050 \
  -c mychannel \
  -f ./channel-artifacts/Org2MSPanchors.tx
"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Anchor peer updated successfully${NC}"
else
    echo -e "${YELLOW}⚠ Warning: Anchor peer update failed (may not be critical)${NC}"
fi

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Channel Join Complete on GCP!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\n${YELLOW}To verify:${NC}"
echo -e "docker exec cli_org2 peer channel list"
echo -e "docker exec cli_org2 peer channel getinfo -c mychannel"
echo -e "\n${YELLOW}To check peer discovery:${NC}"
echo -e "docker logs peer0.org2.example.com | grep -i 'joining gossip network'"
