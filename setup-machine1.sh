#!/bin/bash
#
# MACHINE 1 - COMPLETE SETUP SCRIPT
# This script sets up Org1 + Orderer on Machine 1
#
# Usage: ./setup-machine1.sh [channel_name] [chaincode_name]
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
MACHINE2_IP="178.16.139.239"
DELAY=3

# Banner
echo -e "${BLUE}"
echo "================================================================================"
echo "  HYPERLEDGER FABRIC - MACHINE 1 SETUP (Org1 + Orderer)"
echo "================================================================================"
echo -e "${NC}"
echo "Channel Name: $CHANNEL_NAME"
echo "Chaincode: $CC_NAME v$CC_VERSION"
echo "Machine 2 IP: $MACHINE2_IP"
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

# Function to install Fabric binaries
install_fabric_binaries() {
    echo -e "${YELLOW}Hyperledger Fabric binaries not found.${NC}"
    echo -e "${GREEN}Installing automatically...${NC}"

    # Create temp directory
    TEMP_DIR=$(mktemp -d)
    cd $TEMP_DIR

    # Download and install
    echo "Downloading Fabric binaries v2.4.0..."
    curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.4.0 1.5.2

    # Copy binaries to /usr/local/bin
    if [ -d "fabric-samples/bin" ]; then
        echo "Installing binaries to /usr/local/bin..."
        sudo cp fabric-samples/bin/* /usr/local/bin/ 2>/dev/null || {
            # If sudo fails, try copying to user's home
            mkdir -p $HOME/bin
            cp fabric-samples/bin/* $HOME/bin/
            export PATH=$PATH:$HOME/bin
            echo 'export PATH=$PATH:$HOME/bin' >> ~/.bashrc
            echo -e "${YELLOW}Binaries installed to $HOME/bin${NC}"
            echo -e "${YELLOW}Added to PATH for this session${NC}"
        }
    else
        cd $OLDPWD
        rm -rf $TEMP_DIR
        print_error "Failed to download Fabric binaries"
    fi

    # Copy to project bin directory as well
    cd $OLDPWD
    mkdir -p bin
    cp -r $TEMP_DIR/fabric-samples/bin/* bin/ 2>/dev/null || true
    export PATH=$PATH:$(pwd)/bin

    # Cleanup
    rm -rf $TEMP_DIR

    echo -e "${GREEN}✓ Fabric binaries installed successfully${NC}"
}

# Check prerequisites
print_step "Step 1/9: Checking prerequisites..."
command -v docker >/dev/null 2>&1 || print_error "Docker not found. Please install Docker first.\nRun: ./install-prerequisites.sh --machine1"
command -v docker-compose >/dev/null 2>&1 || print_error "Docker Compose not found. Please install Docker Compose first.\nRun: ./install-prerequisites.sh --machine1"

# Check for Fabric binaries, install if not found
if ! command -v cryptogen >/dev/null 2>&1 || ! command -v configtxgen >/dev/null 2>&1; then
    echo -e "${YELLOW}Fabric binaries (cryptogen, configtxgen) not found${NC}"
    read -p "Install them automatically? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_fabric_binaries
        # Verify installation
        command -v cryptogen >/dev/null 2>&1 || print_error "Failed to install cryptogen. Please run: ./install-prerequisites.sh --machine1"
        command -v configtxgen >/dev/null 2>&1 || print_error "Failed to install configtxgen. Please run: ./install-prerequisites.sh --machine1"
    else
        print_error "Fabric binaries are required. Please install them:\n  ./install-prerequisites.sh --machine1\nOr manually:\n  curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.4.0 1.5.2"
    fi
fi

echo "✓ All prerequisites found"

# Clean up existing containers and volumes
print_step "Step 2/9: Cleaning up existing containers and volumes..."
if docker ps -a | grep -q "peer0.org1.example.com\|orderer.example.com"; then
    docker-compose -f docker-compose-org1.yaml down -v 2>/dev/null || true
    echo "✓ Cleaned up existing containers"
else
    echo "✓ No existing containers to clean up"
fi

# Generate crypto materials
print_step "Step 3/9: Generating crypto materials..."
if [ -d "organizations" ]; then
    echo "Removing existing organizations directory..."
    rm -rf organizations
fi

echo "Running: cryptogen generate --config=./crypto-config.yaml"
cryptogen generate --config=./crypto-config.yaml
if [ $? -ne 0 ]; then
    print_error "Failed to generate crypto materials.\nMake sure crypto-config.yaml exists and cryptogen is installed."
fi

# Verify crypto materials were created
if [ ! -d "organizations/ordererOrganizations" ] || [ ! -d "organizations/peerOrganizations" ]; then
    print_error "Crypto materials not generated properly. Organizations directory is missing."
fi

# Verify orderer TLS certs exist (needed for genesis block)
if [ ! -f "organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt" ]; then
    print_error "Orderer TLS certificates not found. Crypto generation may have failed."
fi

echo "✓ Crypto materials generated successfully"
echo "  - Orderer certificates: ✓"
echo "  - Org1 certificates: ✓"
echo "  - Org2 certificates: ✓"

# Generate genesis block and channel artifacts
print_step "Step 4/9: Generating genesis block and channel artifacts..."
mkdir -p system-genesis-block channel-artifacts

# Set FABRIC_CFG_PATH to configtx directory
export FABRIC_CFG_PATH=${PWD}/configtx
echo "FABRIC_CFG_PATH set to: $FABRIC_CFG_PATH"

# Verify configtx.yaml exists
if [ ! -f "${FABRIC_CFG_PATH}/configtx.yaml" ]; then
    print_error "configtx.yaml not found at ${FABRIC_CFG_PATH}/configtx.yaml"
fi

# Verify crypto materials exist before generating genesis block
if [ ! -f "organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt" ]; then
    print_error "Orderer TLS certificates not found. Cannot create genesis block.\nPlease ensure crypto materials were generated in Step 3."
fi

# Generate genesis block
echo "Generating genesis block..."
configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock ./system-genesis-block/genesis.block
if [ $? -ne 0 ]; then
    print_error "Failed to generate genesis block.\nCheck that:\n  1. Crypto materials exist in organizations/\n  2. configtx.yaml paths are correct\n  3. FABRIC_CFG_PATH is set to ${PWD}/configtx"
fi

# Verify genesis block was created
if [ ! -f "system-genesis-block/genesis.block" ]; then
    print_error "Genesis block was not created"
fi

echo "✓ Genesis block generated ($(du -h system-genesis-block/genesis.block | cut -f1))"

# Generate channel configuration
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME
if [ $? -ne 0 ]; then
    print_error "Failed to generate channel configuration"
fi
echo "✓ Channel configuration generated"

# Generate anchor peer transactions
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org2MSP
echo "✓ Anchor peer transactions generated"

# Create package for Machine 2
print_step "Step 5/9: Creating package for Machine 2..."
tar -czf machine2-package.tar.gz \
    organizations/ \
    system-genesis-block/ \
    channel-artifacts/ \
    configtx/ \
    chaincode/ \
    scripts/ \
    docker-compose-org2.yaml \
    2>/dev/null
echo "✓ Package created: machine2-package.tar.gz"

# Start the network
print_step "Step 6/9: Starting Org1 network containers..."
docker-compose -f docker-compose-org1.yaml up -d
if [ $? -ne 0 ]; then
    print_error "Failed to start network"
fi
echo "✓ Network containers started"

# Wait for containers to be ready
echo "Waiting for containers to be ready..."
sleep 10

# Create channel
print_step "Step 7/9: Creating channel '$CHANNEL_NAME'..."
docker exec cli peer channel create \
    -o orderer.example.com:7050 \
    -c $CHANNEL_NAME \
    -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${CHANNEL_NAME}.tx \
    --outputBlock /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${CHANNEL_NAME}.block \
    --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
if [ $? -ne 0 ]; then
    print_error "Failed to create channel"
fi
echo "✓ Channel created"
sleep $DELAY

# Join peer0.org1 to channel
echo "Joining peer0.org1 to channel..."
docker exec cli peer channel join -b /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${CHANNEL_NAME}.block
if [ $? -ne 0 ]; then
    print_error "Failed to join peer0.org1 to channel"
fi
echo "✓ peer0.org1 joined channel"
sleep $DELAY

# Join peer1.org1 to channel
echo "Joining peer1.org1 to channel..."
docker exec -e CORE_PEER_ADDRESS=peer1.org1.example.com:8051 \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/ca.crt \
    cli peer channel join -b /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${CHANNEL_NAME}.block
if [ $? -ne 0 ]; then
    print_error "Failed to join peer1.org1 to channel"
fi
echo "✓ peer1.org1 joined channel"
sleep $DELAY

# Update anchor peer
echo "Updating anchor peer for Org1..."
docker exec cli peer channel update \
    -o orderer.example.com:7050 \
    -c $CHANNEL_NAME \
    -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/Org1MSPanchors.tx \
    --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
if [ $? -ne 0 ]; then
    print_error "Failed to update anchor peer for Org1"
fi
echo "✓ Anchor peer updated"

# Package and install chaincode
print_step "Step 8/9: Deploying chaincode..."
docker exec cli peer lifecycle chaincode package ${CC_NAME}.tar.gz \
    --path /opt/gopath/src/github.com/chaincode \
    --lang node \
    --label ${CC_NAME}_${CC_VERSION}
if [ $? -ne 0 ]; then
    print_error "Failed to package chaincode"
fi
echo "✓ Chaincode packaged"
sleep $DELAY

# Install on peer0.org1
echo "Installing chaincode on peer0.org1..."
docker exec cli peer lifecycle chaincode install ${CC_NAME}.tar.gz
if [ $? -ne 0 ]; then
    print_error "Failed to install chaincode on peer0.org1"
fi
echo "✓ Chaincode installed on peer0.org1"
sleep $DELAY

# Install on peer1.org1
echo "Installing chaincode on peer1.org1..."
docker exec -e CORE_PEER_ADDRESS=peer1.org1.example.com:8051 \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/ca.crt \
    cli peer lifecycle chaincode install ${CC_NAME}.tar.gz
if [ $? -ne 0 ]; then
    print_error "Failed to install chaincode on peer1.org1"
fi
echo "✓ Chaincode installed on peer1.org1"
sleep $DELAY

# Get package ID
docker exec cli peer lifecycle chaincode queryinstalled > /tmp/installed_chaincode.txt 2>&1
PACKAGE_ID=$(sed -n "/${CC_NAME}_${CC_VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" /tmp/installed_chaincode.txt | head -1)
echo "Package ID: $PACKAGE_ID"

if [ -z "$PACKAGE_ID" ]; then
    print_error "Failed to get package ID"
fi

# Save package ID for Machine 2
echo "$PACKAGE_ID" > package-id.txt

# Approve for Org1
echo "Approving chaincode for Org1..."
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
    print_error "Failed to approve chaincode for Org1"
fi
echo "✓ Chaincode approved for Org1"

# Network status
print_step "Step 9/9: Verifying network status..."
echo ""
echo "Containers running:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "NAME|org1|orderer|cli|couchdb"
echo ""

# Final instructions
echo -e "${YELLOW}"
echo "================================================================================"
echo "  MACHINE 1 SETUP COMPLETE!"
echo "================================================================================"
echo -e "${NC}"
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo ""
echo "1. Transfer the package to Machine 2:"
echo -e "${BLUE}   scp machine2-package.tar.gz user@$MACHINE2_IP:/path/to/fabric-network/${NC}"
echo ""
echo "2. On Machine 2, extract and run setup:"
echo -e "${BLUE}   tar -xzf machine2-package.tar.gz${NC}"
echo -e "${BLUE}   ./setup-machine2.sh $CHANNEL_NAME $CC_NAME${NC}"
echo ""
echo "3. After Machine 2 setup completes, commit the chaincode (run on either machine):"
echo ""
echo -e "${BLUE}docker exec cli peer lifecycle chaincode commit \\
    -o orderer.example.com:7050 --tls \\
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \\
    --channelID $CHANNEL_NAME \\
    --name $CC_NAME \\
    --version $CC_VERSION \\
    --sequence $CC_SEQUENCE \\
    --peerAddresses peer0.org1.example.com:7051 \\
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \\
    --peerAddresses peer0.org2.example.com:9051 \\
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt${NC}"
echo ""
echo -e "${YELLOW}Package ID for reference: ${PACKAGE_ID}${NC}"
echo -e "${YELLOW}Package ID saved to: package-id.txt${NC}"
echo ""
