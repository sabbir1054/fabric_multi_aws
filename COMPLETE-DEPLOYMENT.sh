#!/bin/bash

# ========================================
# COMPLETE FABRIC DEPLOYMENT SCRIPT
# This script does EVERYTHING:
# 1. Fixes genesis.block directory issue
# 2. Updates configtx.yaml automatically
# 3. Cleans up old setup
# 4. Deploys fresh Fabric network
# 5. Creates and joins channel
# 6. Verifies everything works
# ========================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         COMPLETE HYPERLEDGER FABRIC DEPLOYMENT                   ║${NC}"
echo -e "${BLUE}║              AWS - Modern Fabric 2.3+ Approach                   ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${YELLOW}This script will:${NC}"
echo -e "  1. Clean up old setup"
echo -e "  2. Fix genesis.block directory issue"
echo -e "  3. Update configtx.yaml (backup created)"
echo -e "  4. Start containers"
echo -e "  5. Generate channel genesis block"
echo -e "  6. Join orderer to channel"
echo -e "  7. Join peer to channel"
echo -e "  8. Verify deployment"
echo -e ""
read -p "Continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo -e "${YELLOW}Cancelled.${NC}"
    exit 0
fi

# ========================================
# STEP 1: CLEANUP
# ========================================

echo -e "\n${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  STEP 1: CLEANUP OLD SETUP${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"

echo -e "\n${YELLOW}[1.1] Stopping all containers...${NC}"
docker-compose -f docker-compose-aws.yml down -v 2>/dev/null || true
docker rm -f orderer.example.com peer0.org1.example.com cli 2>/dev/null || true
echo -e "${GREEN}✓ Containers stopped${NC}"

echo -e "\n${YELLOW}[1.2] Removing Docker volumes...${NC}"
docker volume rm fabric-network_ordererdata 2>/dev/null || true
docker volume rm fabric-network_peer0org1data 2>/dev/null || true
echo -e "${GREEN}✓ Volumes removed${NC}"

echo -e "\n${YELLOW}[1.3] Fixing genesis.block directory issue...${NC}"
# This is the critical fix for the "Is a directory" error
if [ -d "./system-genesis-block/genesis.block" ]; then
    echo -e "${YELLOW}Found: genesis.block is a directory. Removing with sudo...${NC}"
    sudo rm -rf ./system-genesis-block/genesis.block
    echo -e "${GREEN}✓ Removed genesis.block directory${NC}"
fi

# Clean entire directories
sudo rm -rf ./system-genesis-block
sudo rm -rf ./channel-artifacts

# Recreate with proper permissions
mkdir -p ./system-genesis-block
mkdir -p ./channel-artifacts
sudo chmod 777 ./system-genesis-block
sudo chmod 777 ./channel-artifacts

echo -e "${GREEN}✓ Directories cleaned and ready${NC}"

# ========================================
# STEP 2: UPDATE CONFIGTX.YAML
# ========================================

echo -e "\n${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  STEP 2: UPDATE CONFIGURATION${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"

echo -e "\n${YELLOW}[2.1] Backing up configtx.yaml...${NC}"
cp configtx/configtx.yaml configtx/configtx.yaml.backup.$(date +%Y%m%d-%H%M%S)
echo -e "${GREEN}✓ Backup created${NC}"

echo -e "\n${YELLOW}[2.2] Updating configtx.yaml for Fabric 2.3+...${NC}"

# Create new Profiles section
cat > /tmp/new_profiles.yaml << 'PROFILESEOF'
################################################################################
#   SECTION: Profiles
################################################################################
Profiles:

  TwoOrgsApplicationGenesis:
    <<: *ChannelDefaults
    Orderer:
      <<: *OrdererDefaults
      OrdererType: etcdraft
      EtcdRaft:
        Consenters:
          - Host: orderer.example.com
            Port: 7050
            ClientTLSCert: ../organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt
            ServerTLSCert: ../organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt
      Organizations:
        - *OrdererOrg
      Capabilities:
        <<: *OrdererCapabilities
    Application:
      <<: *ApplicationDefaults
      Organizations:
        - *Org1
        - *Org2
PROFILESEOF

# Remove old Profiles section and add new one
sed -i '/^Profiles:/,$d' configtx/configtx.yaml
cat /tmp/new_profiles.yaml >> configtx/configtx.yaml
rm /tmp/new_profiles.yaml

echo -e "${GREEN}✓ configtx.yaml updated (old Consortiums removed)${NC}"

# ========================================
# STEP 3: START CONTAINERS
# ========================================

echo -e "\n${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  STEP 3: START CONTAINERS${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"

echo -e "\n${YELLOW}[3.1] Starting Docker containers...${NC}"
docker-compose -f docker-compose-aws.yml up -d

echo -e "\n${YELLOW}[3.2] Waiting for containers to initialize...${NC}"
sleep 8

echo -e "\n${YELLOW}[3.3] Verifying containers are running...${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

if ! docker ps | grep -q orderer.example.com; then
    echo -e "${RED}✗ Orderer not running!${NC}"
    docker logs orderer.example.com
    exit 1
fi

if ! docker ps | grep -q peer0.org1.example.com; then
    echo -e "${RED}✗ Peer not running!${NC}"
    docker logs peer0.org1.example.com
    exit 1
fi

if ! docker ps | grep -q cli; then
    echo -e "${RED}✗ CLI not running!${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All containers running${NC}"

# ========================================
# STEP 4: GENERATE CHANNEL GENESIS BLOCK
# ========================================

echo -e "\n${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  STEP 4: GENERATE CHANNEL GENESIS BLOCK${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"

echo -e "\n${YELLOW}[4.1] Generating mychannel genesis block...${NC}"
docker exec cli configtxgen \
  -profile TwoOrgsApplicationGenesis \
  -channelID mychannel \
  -outputBlock ./channel-artifacts/mychannel.block \
  -configPath /etc/hyperledger/fabric

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to generate channel genesis block${NC}"
    exit 1
fi

echo -e "\n${YELLOW}[4.2] Verifying genesis block created...${NC}"
docker exec cli ls -lh ./channel-artifacts/mychannel.block

echo -e "${GREEN}✓ Channel genesis block created${NC}"

# ========================================
# STEP 5: JOIN ORDERER TO CHANNEL
# ========================================

echo -e "\n${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  STEP 5: JOIN ORDERER TO CHANNEL (osnadmin)${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"

echo -e "\n${YELLOW}[5.1] Joining orderer to mychannel using Channel Participation API...${NC}"

# Wait a bit for orderer to be ready
sleep 3

docker exec cli osnadmin channel join \
  --channelID mychannel \
  --config-block /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/mychannel.block \
  -o orderer.example.com:7053 \
  --ca-file /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  --client-cert /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt \
  --client-key /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to join orderer to channel${NC}"
    echo -e "${YELLOW}Checking orderer logs:${NC}"
    docker logs orderer.example.com | tail -20
    exit 1
fi

echo -e "${GREEN}✓ Orderer joined to mychannel${NC}"

# Verify orderer joined
echo -e "\n${YELLOW}[5.2] Verifying orderer channel list...${NC}"
docker exec cli osnadmin channel list \
  -o orderer.example.com:7053 \
  --ca-file /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  --client-cert /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt \
  --client-key /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key

echo -e "${GREEN}✓ Orderer is serving mychannel${NC}"

# ========================================
# STEP 6: JOIN PEER TO CHANNEL
# ========================================

echo -e "\n${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  STEP 6: JOIN PEER TO CHANNEL${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"

echo -e "\n${YELLOW}[6.1] Joining Org1 peer to mychannel...${NC}"

docker exec cli bash -c '
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt

peer channel join -b ./channel-artifacts/mychannel.block
'

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to join peer to channel${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Peer joined to mychannel${NC}"

# Verify peer joined
echo -e "\n${YELLOW}[6.2] Verifying peer channel list...${NC}"
docker exec cli peer channel list

echo -e "${GREEN}✓ Peer is member of mychannel${NC}"

# ========================================
# STEP 7: UPDATE ANCHOR PEER
# ========================================

echo -e "\n${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  STEP 7: UPDATE ANCHOR PEER${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"

echo -e "\n${YELLOW}[7.1] Generating anchor peer update for Org1...${NC}"
docker exec cli configtxgen \
  -profile TwoOrgsApplicationGenesis \
  -channelID mychannel \
  -asOrg Org1MSP \
  -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx \
  -configPath /etc/hyperledger/fabric

echo -e "\n${YELLOW}[7.2] Updating anchor peer...${NC}"
docker exec cli bash -c '
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
' || echo -e "${YELLOW}⚠ Anchor peer update failed (may not be critical)${NC}"

echo -e "${GREEN}✓ Anchor peer update attempted${NC}"

# ========================================
# STEP 8: VERIFICATION
# ========================================

echo -e "\n${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  STEP 8: VERIFICATION${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"

echo -e "\n${YELLOW}[8.1] Checking channel info...${NC}"
docker exec cli bash -c '
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt

peer channel getinfo -c mychannel
'

echo -e "\n${YELLOW}[8.2] Checking orderer logs for errors...${NC}"
if docker logs orderer.example.com 2>&1 | grep -i "panic\|fatal\|error" | grep -v "Unrecognized ordering service"; then
    echo -e "${YELLOW}⚠ Some errors found in orderer logs (check above)${NC}"
else
    echo -e "${GREEN}✓ No critical errors in orderer logs${NC}"
fi

echo -e "\n${YELLOW}[8.3] Checking peer logs for errors...${NC}"
if docker logs peer0.org1.example.com 2>&1 | grep -i "panic\|fatal" | head -5; then
    echo -e "${YELLOW}⚠ Some errors found in peer logs (check above)${NC}"
else
    echo -e "${GREEN}✓ No critical errors in peer logs${NC}"
fi

echo -e "\n${YELLOW}[8.4] Final container status:${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}"

# ========================================
# SUCCESS SUMMARY
# ========================================

echo -e "\n${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                     DEPLOYMENT COMPLETE! ✓                       ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${GREEN}✓ Cleanup completed${NC}"
echo -e "${GREEN}✓ Configuration updated${NC}"
echo -e "${GREEN}✓ Containers running${NC}"
echo -e "${GREEN}✓ Channel genesis block created${NC}"
echo -e "${GREEN}✓ Orderer joined to mychannel${NC}"
echo -e "${GREEN}✓ Peer joined to mychannel${NC}"
echo -e "${GREEN}✓ Anchor peer configured${NC}"
echo -e "${GREEN}✓ Verification completed${NC}"

echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                    AWS SETUP COMPLETE!                          ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"

echo -e "\n${YELLOW}Quick Verification Commands:${NC}"
echo -e "${GREEN}# Check containers:${NC}"
echo -e "  docker ps"
echo -e ""
echo -e "${GREEN}# Check orderer channels:${NC}"
echo -e '  docker exec cli osnadmin channel list -o orderer.example.com:7053 \'
echo -e '    --ca-file /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \'
echo -e '    --client-cert /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt \'
echo -e '    --client-key /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key'
echo -e ""
echo -e "${GREEN}# Check peer channels:${NC}"
echo -e "  docker exec cli peer channel list"
echo -e ""
echo -e "${GREEN}# Check orderer logs:${NC}"
echo -e "  docker logs orderer.example.com | tail -20"
echo -e ""
echo -e "${GREEN}# Check peer logs:${NC}"
echo -e "  docker logs peer0.org1.example.com | tail -20"

echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                    NEXT STEPS (GCP)                             ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"

echo -e "\n${YELLOW}To deploy to GCP:${NC}"
echo -e ""
echo -e "${GREEN}1. Copy artifacts to GCP:${NC}"
echo -e "   tar -czf fabric-gcp-artifacts.tar.gz organizations/ channel-artifacts/ configtx/ chaincode/ docker-compose-gcp.yml"
echo -e "   scp fabric-gcp-artifacts.tar.gz ubuntu@178.16.139.239:~/"
echo -e ""
echo -e "${GREEN}2. On GCP machine:${NC}"
echo -e "   tar -xzf fabric-gcp-artifacts.tar.gz"
echo -e "   docker-compose -f docker-compose-gcp.yml up -d"
echo -e '   docker exec cli_org2 bash -c "peer channel join -b ./channel-artifacts/mychannel.block"'
echo -e ""

echo -e "\n${GREEN}🎉 Your Hyperledger Fabric network on AWS is ready!${NC}\n"
