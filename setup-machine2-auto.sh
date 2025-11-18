#!/bin/bash
#
# MACHINE 2 - COMPLETE SETUP SCRIPT (AUTO VERSION)
# This script sets up Org2 on Machine 2
# Non-interactive - runs automatically without prompts
#
# Prerequisites:
# - Files transferred from Machine 1 (machine2-package.tar.gz)
# - Package extracted to current directory
#
# Usage: ./setup-machine2-auto.sh [channel_name] [chaincode_name]
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CHANNEL_NAME=${1:-"mychannel"}
CC_NAME=${2:-"asset-transfer-basic"}
CC_VERSION="1.0"
CC_SEQUENCE="1"
MACHINE1_IP="13.239.132.194"
DELAY=3

# Banner
echo -e "${BLUE}"
echo "================================================================================"
echo "  HYPERLEDGER FABRIC - MACHINE 2 SETUP (Org2)"
echo "  AUTO MODE - Fully automated deployment"
echo "================================================================================"
echo -e "${NC}"
echo "Channel Name: $CHANNEL_NAME"
echo "Chaincode: $CC_NAME v$CC_VERSION"
echo "Machine 1 IP: $MACHINE1_IP"
echo ""

# Function to print step
print_step() {
    echo -e "${GREEN}===> $1${NC}"
}

# Function to print error and exit
print_error() {
    echo -e "${RED}ERROR: $1${NC}"
    exit 1
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run as root"
fi

# Check prerequisites
print_step "Step 1/7: Checking prerequisites..."
command -v docker >/dev/null 2>&1 || print_error "Docker not found. Please install Docker first.\nRun: ./install-prerequisites.sh --machine2"
command -v docker-compose >/dev/null 2>&1 || print_error "Docker Compose not found. Please install Docker Compose first.\nRun: ./install-prerequisites.sh --machine2"
echo "✓ Docker and Docker Compose found"

# Check required files
if [ ! -f "docker-compose-org2.yaml" ]; then
    print_error "docker-compose-org2.yaml not found. Please extract machine2-package.tar.gz first."
fi
if [ ! -d "organizations" ]; then
    print_error "organizations directory not found. Please extract machine2-package.tar.gz first."
fi
if [ ! -d "channel-artifacts" ]; then
    print_error "channel-artifacts directory not found. Please extract machine2-package.tar.gz first."
fi
echo "✓ All required files found"

# Clean up existing containers and volumes
print_step "Step 2/7: Cleaning up existing containers and volumes..."
if docker ps -a | grep -q "peer0.org2.example.com"; then
    docker-compose -f docker-compose-org2.yaml down -v 2>/dev/null || true
    echo "✓ Cleaned up existing containers"
else
    echo "✓ No existing containers to clean up"
fi

# Start the network
print_step "Step 3/7: Starting Org2 network containers..."
docker-compose -f docker-compose-org2.yaml up -d
if [ $? -ne 0 ]; then
    print_error "Failed to start network"
fi
echo "✓ Network containers started"

# Wait for containers to be ready
echo "Waiting for containers to be ready..."
sleep 10

# Check if channel block exists
if [ ! -f "channel-artifacts/${CHANNEL_NAME}.block" ]; then
    print_error "Channel block not found. This should have been created on Machine 1."
fi

# Join channel
print_step "Step 4/7: Joining Org2 peers to channel '$CHANNEL_NAME'..."
echo "Joining peer0.org2 to channel..."
docker exec cli peer channel join -b /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${CHANNEL_NAME}.block
if [ $? -ne 0 ]; then
    print_error "Failed to join peer0.org2 to channel"
fi
echo "✓ peer0.org2 joined channel"
sleep $DELAY

echo "Joining peer1.org2 to channel..."
docker exec -e CORE_PEER_ADDRESS=peer1.org2.example.com:10051 \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/tls/ca.crt \
    cli peer channel join -b /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${CHANNEL_NAME}.block
if [ $? -ne 0 ]; then
    print_error "Failed to join peer1.org2 to channel"
fi
echo "✓ peer1.org2 joined channel"
sleep $DELAY

# Update anchor peer
echo "Updating anchor peer for Org2..."
docker exec cli peer channel update \
    -o orderer.example.com:7050 \
    -c $CHANNEL_NAME \
    -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/Org2MSPanchors.tx \
    --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
if [ $? -ne 0 ]; then
    print_error "Failed to update anchor peer for Org2"
fi
echo "✓ Anchor peer updated"

# Install chaincode
print_step "Step 5/7: Installing chaincode on Org2 peers..."

# Check if chaincode package exists
if [ ! -f "${CC_NAME}.tar.gz" ]; then
    echo "Chaincode package not found in current directory."
    echo "Creating package from chaincode source..."
    docker exec cli peer lifecycle chaincode package ${CC_NAME}.tar.gz \
        --path /opt/gopath/src/github.com/chaincode \
        --lang node \
        --label ${CC_NAME}_${CC_VERSION}
    if [ $? -ne 0 ]; then
        print_error "Failed to package chaincode"
    fi
    echo "✓ Chaincode packaged"
else
    echo "Using existing chaincode package"
    # Copy package into cli container
    docker cp ${CC_NAME}.tar.gz cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/${CC_NAME}.tar.gz
fi
sleep $DELAY

# Install on peer0.org2
echo "Installing chaincode on peer0.org2..."
docker exec cli peer lifecycle chaincode install ${CC_NAME}.tar.gz
if [ $? -ne 0 ]; then
    print_error "Failed to install chaincode on peer0.org2"
fi
echo "✓ Chaincode installed on peer0.org2"
sleep $DELAY

# Install on peer1.org2
echo "Installing chaincode on peer1.org2..."
docker exec -e CORE_PEER_ADDRESS=peer1.org2.example.com:10051 \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/tls/ca.crt \
    cli peer lifecycle chaincode install ${CC_NAME}.tar.gz
if [ $? -ne 0 ]; then
    print_error "Failed to install chaincode on peer1.org2"
fi
echo "✓ Chaincode installed on peer1.org2"
sleep $DELAY

# Get package ID
print_step "Step 6/7: Approving chaincode for Org2..."
docker exec cli peer lifecycle chaincode queryinstalled > /tmp/installed_chaincode.txt 2>&1
PACKAGE_ID=$(sed -n "/${CC_NAME}_${CC_VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" /tmp/installed_chaincode.txt | head -1)
echo "Package ID: $PACKAGE_ID"

if [ -z "$PACKAGE_ID" ]; then
    print_error "Failed to get package ID"
fi

# Approve for Org2
echo "Approving chaincode for Org2..."
docker exec cli peer lifecycle chaincode approveformyorg \
    -o orderer.example.com:7050 \
    --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    --channelID $CHANNEL_NAME \
    --name $CC_NAME \
    --version $CC_VERSION \
    --package-id $PACKAGE_ID \
    --sequence $CC_SEQUENCE
if [ $? -ne 0 ]; then
    print_error "Failed to approve chaincode for Org2"
fi
echo "✓ Chaincode approved for Org2"

# Check commit readiness
echo "Checking commit readiness..."
docker exec cli peer lifecycle chaincode checkcommitreadiness \
    --channelID $CHANNEL_NAME \
    --name $CC_NAME \
    --version $CC_VERSION \
    --sequence $CC_SEQUENCE \
    --output json

# Commit chaincode
print_step "Step 7/7: Committing chaincode to channel..."
docker exec cli peer lifecycle chaincode commit \
    -o orderer.example.com:7050 \
    --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    --channelID $CHANNEL_NAME \
    --name $CC_NAME \
    --version $CC_VERSION \
    --sequence $CC_SEQUENCE \
    --peerAddresses peer0.org1.example.com:7051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
    --peerAddresses peer0.org2.example.com:9051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
if [ $? -ne 0 ]; then
    print_error "Failed to commit chaincode"
fi
echo "✓ Chaincode committed to channel"

# Network status
echo ""
echo "Containers running:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "NAME|org2|cli|couchdb"
echo ""

# Verify chaincode is committed
echo "Verifying committed chaincode..."
docker exec cli peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME

# Final message
echo ""
echo -e "${YELLOW}"
echo "================================================================================"
echo "  MACHINE 2 SETUP COMPLETE!"
echo "================================================================================"
echo -e "${NC}"
echo ""
echo -e "${GREEN}Network is ready!${NC}"
echo ""
echo -e "${GREEN}Test the chaincode:${NC}"
echo ""
echo "1. Initialize the ledger:"
echo -e "${BLUE}docker exec cli peer chaincode invoke \\
    -o orderer.example.com:7050 --tls \\
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \\
    -C $CHANNEL_NAME -n $CC_NAME \\
    --peerAddresses peer0.org1.example.com:7051 \\
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \\
    --peerAddresses peer0.org2.example.com:9051 \\
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \\
    -c '{\"function\":\"InitLedger\",\"Args\":[]}'${NC}"
echo ""
echo "2. Query the ledger:"
echo -e "${BLUE}docker exec cli peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{\"Args\":[\"GetAllAssets\"]}'${NC}"
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "- Configure your backend (ph_water_backend) to connect to the network"
echo "- Start your frontend (ph_water_frontend)"
echo ""
