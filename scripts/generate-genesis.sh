#!/bin/bash
#
# Generate genesis block and channel configuration
# Run this script on Machine 1 after generating crypto materials
#

set -e

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

CHANNEL_NAME=${1:-"mychannel"}

echo -e "${GREEN}Generating genesis block and channel configuration...${NC}"
echo "Channel name: $CHANNEL_NAME"

# Create directories
mkdir -p system-genesis-block
mkdir -p channel-artifacts

# Set the fabric config path
export FABRIC_CFG_PATH=${PWD}/configtx

# Generate genesis block
echo -e "${GREEN}Generating genesis block...${NC}"
configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock ./system-genesis-block/genesis.block

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to generate genesis block${NC}"
    exit 1
fi

echo -e "${GREEN}Genesis block generated successfully!${NC}"

# Generate channel configuration transaction
echo -e "${GREEN}Generating channel configuration transaction...${NC}"
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to generate channel configuration transaction${NC}"
    exit 1
fi

echo -e "${GREEN}Channel configuration transaction generated successfully!${NC}"

# Generate anchor peer transaction for Org1
echo -e "${GREEN}Generating anchor peer transaction for Org1...${NC}"
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to generate anchor peer transaction for Org1${NC}"
    exit 1
fi

echo -e "${GREEN}Anchor peer transaction for Org1 generated successfully!${NC}"

# Generate anchor peer transaction for Org2
echo -e "${GREEN}Generating anchor peer transaction for Org2...${NC}"
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org2MSP

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to generate anchor peer transaction for Org2${NC}"
    exit 1
fi

echo -e "${GREEN}Anchor peer transaction for Org2 generated successfully!${NC}"
echo ""
echo -e "${GREEN}All artifacts generated successfully!${NC}"
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "1. Copy 'system-genesis-block' and 'channel-artifacts' directories to Machine 2"
echo "2. Start the network on Machine 1: docker-compose -f docker-compose-org1.yaml up -d"
echo "3. Start the network on Machine 2: docker-compose -f docker-compose-org2.yaml up -d"
echo "4. Create the channel: ./scripts/create-channel.sh $CHANNEL_NAME"
echo ""
