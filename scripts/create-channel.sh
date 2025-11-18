#!/bin/bash
#
# Create channel and join peers
# Run this script on Machine 1 after starting the network on both machines
#

set -e

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

CHANNEL_NAME=${1:-"mychannel"}
DELAY=${2:-"3"}
MAX_RETRY=${3:-"5"}
VERBOSE=${4:-"false"}

: ${CONTAINER_CLI:="docker"}
: ${CONTAINER_CLI_COMPOSE:="${CONTAINER_CLI}-compose"}
COMPOSE_FILE_ORG1=docker-compose-org1.yaml

echo -e "${GREEN}Creating channel '$CHANNEL_NAME'${NC}"

# Set environment for peer0.org1
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export FABRIC_CFG_PATH=${PWD}/configtx

echo -e "${GREEN}Creating channel...${NC}"

# Create channel
docker exec cli peer channel create \
    -o orderer.example.com:7050 \
    -c $CHANNEL_NAME \
    -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${CHANNEL_NAME}.tx \
    --outputBlock /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${CHANNEL_NAME}.block \
    --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to create channel${NC}"
    exit 1
fi

echo -e "${GREEN}Channel '$CHANNEL_NAME' created successfully!${NC}"
echo ""

# Wait for channel to be created
sleep $DELAY

echo -e "${GREEN}Joining peer0.org1 to channel...${NC}"
docker exec cli peer channel join -b /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${CHANNEL_NAME}.block

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to join peer0.org1 to channel${NC}"
    exit 1
fi

echo -e "${GREEN}peer0.org1 joined channel successfully!${NC}"
sleep $DELAY

echo -e "${GREEN}Joining peer1.org1 to channel...${NC}"
docker exec -e CORE_PEER_ADDRESS=peer1.org1.example.com:8051 \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/ca.crt \
    cli peer channel join -b /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${CHANNEL_NAME}.block

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to join peer1.org1 to channel${NC}"
    exit 1
fi

echo -e "${GREEN}peer1.org1 joined channel successfully!${NC}"
sleep $DELAY

echo -e "${GREEN}Updating anchor peer for Org1...${NC}"
docker exec cli peer channel update \
    -o orderer.example.com:7050 \
    -c $CHANNEL_NAME \
    -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/Org1MSPanchors.tx \
    --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to update anchor peer for Org1${NC}"
    exit 1
fi

echo -e "${GREEN}Anchor peer for Org1 updated successfully!${NC}"
echo ""
echo -e "${GREEN}Channel creation and Org1 peers join completed!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Copy the channel block to Machine 2: scp channel-artifacts/${CHANNEL_NAME}.block user@machine2:/path/to/fabric-network/channel-artifacts/"
echo "2. Run the join-channel.sh script on Machine 2 to join Org2 peers"
echo ""
