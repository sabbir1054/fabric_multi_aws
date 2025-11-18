#!/bin/bash
#
# Join Org2 peers to channel
# Run this script on Machine 2 after the channel has been created
#

set -e

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

CHANNEL_NAME=${1:-"mychannel"}
DELAY=${2:-"3"}

echo -e "${GREEN}Joining Org2 peers to channel '$CHANNEL_NAME'${NC}"

# Check if channel block exists
if [ ! -f "channel-artifacts/${CHANNEL_NAME}.block" ]; then
    echo -e "${RED}Channel block not found!${NC}"
    echo "Please copy the channel block from Machine 1:"
    echo "scp user@machine1:/path/to/fabric-network/channel-artifacts/${CHANNEL_NAME}.block ./channel-artifacts/"
    exit 1
fi

echo -e "${GREEN}Joining peer0.org2 to channel...${NC}"
docker exec cli peer channel join -b /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${CHANNEL_NAME}.block

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to join peer0.org2 to channel${NC}"
    exit 1
fi

echo -e "${GREEN}peer0.org2 joined channel successfully!${NC}"
sleep $DELAY

echo -e "${GREEN}Joining peer1.org2 to channel...${NC}"
docker exec -e CORE_PEER_ADDRESS=peer1.org2.example.com:10051 \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/tls/ca.crt \
    cli peer channel join -b /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${CHANNEL_NAME}.block

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to join peer1.org2 to channel${NC}"
    exit 1
fi

echo -e "${GREEN}peer1.org2 joined channel successfully!${NC}"
sleep $DELAY

echo -e "${GREEN}Updating anchor peer for Org2...${NC}"
docker exec cli peer channel update \
    -o orderer.example.com:7050 \
    -c $CHANNEL_NAME \
    -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/Org2MSPanchors.tx \
    --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to update anchor peer for Org2${NC}"
    exit 1
fi

echo -e "${GREEN}Anchor peer for Org2 updated successfully!${NC}"
echo ""
echo -e "${GREEN}All Org2 peers joined channel successfully!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Deploy chaincode using ./scripts/deploy-chaincode.sh"
echo ""
