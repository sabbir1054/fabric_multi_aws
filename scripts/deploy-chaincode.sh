#!/bin/bash
#
# Deploy chaincode to the network
# This script packages, installs, approves, and commits chaincode
# Run on Machine 1 (can be adapted for Machine 2)
#

set -e

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

CHANNEL_NAME=${1:-"mychannel"}
CC_NAME=${2:-"asset-transfer-basic"}
CC_SRC_PATH=${3:-"/opt/gopath/src/github.com/chaincode"}
CC_VERSION=${4:-"1.0"}
CC_SEQUENCE=${5:-"1"}
CC_INIT_FCN=${6:-"NA"}
CC_END_POLICY=${7:-"NA"}
CC_COLL_CONFIG=${8:-"NA"}
DELAY=${9:-"3"}

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deploying Chaincode${NC}"
echo -e "${GREEN}========================================${NC}"
echo "Channel: $CHANNEL_NAME"
echo "Chaincode Name: $CC_NAME"
echo "Version: $CC_VERSION"
echo "Sequence: $CC_SEQUENCE"
echo ""

# Package chaincode
echo -e "${GREEN}Step 1: Packaging chaincode...${NC}"
docker exec cli peer lifecycle chaincode package ${CC_NAME}.tar.gz \
    --path ${CC_SRC_PATH} \
    --lang node \
    --label ${CC_NAME}_${CC_VERSION}

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to package chaincode${NC}"
    exit 1
fi
echo -e "${GREEN}Chaincode packaged successfully!${NC}"
sleep $DELAY

# Install on peer0.org1
echo -e "${GREEN}Step 2: Installing chaincode on peer0.org1...${NC}"
docker exec cli peer lifecycle chaincode install ${CC_NAME}.tar.gz

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to install chaincode on peer0.org1${NC}"
    exit 1
fi
echo -e "${GREEN}Chaincode installed on peer0.org1 successfully!${NC}"
sleep $DELAY

# Install on peer1.org1
echo -e "${GREEN}Step 3: Installing chaincode on peer1.org1...${NC}"
docker exec -e CORE_PEER_ADDRESS=peer1.org1.example.com:8051 \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/ca.crt \
    cli peer lifecycle chaincode install ${CC_NAME}.tar.gz

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to install chaincode on peer1.org1${NC}"
    exit 1
fi
echo -e "${GREEN}Chaincode installed on peer1.org1 successfully!${NC}"
sleep $DELAY

# Query installed chaincode to get package ID
echo -e "${GREEN}Step 4: Querying installed chaincode...${NC}"
docker exec cli peer lifecycle chaincode queryinstalled > installed_chaincode.txt
PACKAGE_ID=$(sed -n "/${CC_NAME}_${CC_VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" installed_chaincode.txt)
echo "Package ID: $PACKAGE_ID"

if [ -z "$PACKAGE_ID" ]; then
    echo -e "${RED}Failed to get package ID${NC}"
    exit 1
fi

# Approve for Org1
echo -e "${GREEN}Step 5: Approving chaincode for Org1...${NC}"

if [ "$CC_END_POLICY" = "NA" ]; then
    POLICY_FLAG=""
else
    POLICY_FLAG="--signature-policy $CC_END_POLICY"
fi

if [ "$CC_COLL_CONFIG" = "NA" ]; then
    COLL_FLAG=""
else
    COLL_FLAG="--collections-config $CC_COLL_CONFIG"
fi

if [ "$CC_INIT_FCN" = "NA" ]; then
    INIT_FLAG=""
else
    INIT_FLAG="--init-required"
fi

docker exec cli peer lifecycle chaincode approveformyorg \
    -o orderer.example.com:7050 \
    --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    --channelID $CHANNEL_NAME \
    --name $CC_NAME \
    --version $CC_VERSION \
    --package-id $PACKAGE_ID \
    --sequence $CC_SEQUENCE \
    $POLICY_FLAG \
    $COLL_FLAG \
    $INIT_FLAG

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to approve chaincode for Org1${NC}"
    exit 1
fi
echo -e "${GREEN}Chaincode approved for Org1 successfully!${NC}"
echo ""

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Org1 chaincode deployment completed!${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""
echo -e "${YELLOW}Next steps on Machine 2:${NC}"
echo "1. Install chaincode on Org2 peers"
echo "2. Approve chaincode for Org2"
echo "3. Commit chaincode definition to channel"
echo ""
echo -e "${YELLOW}Package ID for reference:${NC}"
echo "$PACKAGE_ID"
echo ""
