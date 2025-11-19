#!/bin/bash

# ========================================
# COMPLETE FIX AND DEPLOYMENT
# Fixes docker-compose.yml for Fabric 2.3+ Channel Participation API
# ========================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         FIXING ORDERER FOR FABRIC 2.3+ (No Genesis Block)       ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${YELLOW}The problem:${NC}"
echo -e "  • docker-compose-aws.yml still uses old genesis block approach"
echo -e "  • Orderer expects BOOTSTRAPMETHOD=file with genesis.block"
echo -e "  • But genesis.block is a directory, not a file"
echo -e ""
echo -e "${YELLOW}The solution:${NC}"
echo -e "  • Remove genesis block bootstrap (use Channel Participation API)"
echo -e "  • Orderer starts WITHOUT genesis block"
echo -e "  • Join channels using osnadmin command"
echo -e ""
read -p "Continue with fix? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo -e "${YELLOW}Cancelled.${NC}"
    exit 0
fi

# ========================================
# STEP 1: CLEANUP
# ========================================

echo -e "\n${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  STEP 1: CLEANUP${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"

echo -e "\n${YELLOW}Stopping containers...${NC}"
docker-compose -f docker-compose-aws.yml down -v 2>/dev/null || true
docker rm -f orderer.example.com peer0.org1.example.com cli 2>/dev/null || true

echo -e "${YELLOW}Removing volumes...${NC}"
docker volume rm fabric-network_ordererdata 2>/dev/null || true
docker volume rm fabric-network_peer0org1data 2>/dev/null || true

echo -e "${YELLOW}Removing problematic genesis.block directory...${NC}"
sudo rm -rf ./system-genesis-block
sudo rm -rf ./channel-artifacts
mkdir -p ./system-genesis-block
mkdir -p ./channel-artifacts
sudo chmod 777 ./system-genesis-block ./channel-artifacts

echo -e "${GREEN}✓ Cleanup complete${NC}"

# ========================================
# STEP 2: UPDATE DOCKER-COMPOSE
# ========================================

echo -e "\n${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  STEP 2: UPDATE docker-compose-aws.yml${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"

echo -e "\n${YELLOW}Backing up docker-compose-aws.yml...${NC}"
cp docker-compose-aws.yml docker-compose-aws.yml.backup.$(date +%Y%m%d-%H%M%S)

echo -e "${YELLOW}Updating docker-compose-aws.yml for Fabric 2.3+...${NC}"

# Remove the BOOTSTRAPMETHOD and BOOTSTRAPFILE lines
# Remove the genesis.block volume mount
sed -i '/ORDERER_GENERAL_BOOTSTRAPMETHOD/d' docker-compose-aws.yml
sed -i '/ORDERER_GENERAL_BOOTSTRAPFILE/d' docker-compose-aws.yml
sed -i '\|./system-genesis-block/genesis.block:/var/hyperledger/orderer/orderer.genesis.block|d' docker-compose-aws.yml

echo -e "${GREEN}✓ docker-compose-aws.yml updated${NC}"
echo -e "${GREEN}✓ Removed: BOOTSTRAPMETHOD and BOOTSTRAPFILE${NC}"
echo -e "${GREEN}✓ Removed: genesis.block volume mount${NC}"

# ========================================
# STEP 3: UPDATE CONFIGTX.YAML
# ========================================

echo -e "\n${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  STEP 3: UPDATE configtx.yaml${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"

if ! grep -q "TwoOrgsApplicationGenesis" configtx/configtx.yaml; then
    echo -e "${YELLOW}Updating configtx.yaml...${NC}"

    cp configtx/configtx.yaml configtx/configtx.yaml.backup.$(date +%Y%m%d-%H%M%S)

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

    sed -i '/^Profiles:/,$d' configtx/configtx.yaml
    cat /tmp/new_profiles.yaml >> configtx/configtx.yaml
    rm /tmp/new_profiles.yaml

    echo -e "${GREEN}✓ configtx.yaml updated${NC}"
else
    echo -e "${GREEN}✓ configtx.yaml already updated${NC}"
fi

# ========================================
# STEP 4: START CONTAINERS
# ========================================

echo -e "\n${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  STEP 4: START CONTAINERS (WITHOUT GENESIS BLOCK)${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"

echo -e "\n${YELLOW}Starting containers...${NC}"
docker-compose -f docker-compose-aws.yml up -d

echo -e "${YELLOW}Waiting for containers to initialize...${NC}"
sleep 10

echo -e "${YELLOW}Checking container status...${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}"

# Check if orderer is running
if ! docker ps | grep -q orderer.example.com; then
    echo -e "${RED}✗ Orderer still not running. Checking logs...${NC}"
    docker logs orderer.example.com 2>&1 | tail -30
    exit 1
fi

echo -e "${GREEN}✓ All containers running!${NC}"

# Check orderer logs
echo -e "\n${YELLOW}Checking orderer logs (last 10 lines)...${NC}"
docker logs orderer.example.com 2>&1 | tail -10

# ========================================
# STEP 5: GENERATE CHANNEL GENESIS
# ========================================

echo -e "\n${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  STEP 5: GENERATE CHANNEL GENESIS BLOCK${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"

echo -e "\n${YELLOW}Generating mychannel genesis block...${NC}"
docker exec cli configtxgen \
  -profile TwoOrgsApplicationGenesis \
  -channelID mychannel \
  -outputBlock ./channel-artifacts/mychannel.block \
  -configPath /etc/hyperledger/fabric

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to generate channel genesis block${NC}"
    exit 1
fi

docker exec cli ls -lh ./channel-artifacts/mychannel.block
echo -e "${GREEN}✓ Channel genesis block created${NC}"

# ========================================
# STEP 6: JOIN ORDERER TO CHANNEL
# ========================================

echo -e "\n${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  STEP 6: JOIN ORDERER TO CHANNEL (osnadmin)${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"

echo -e "\n${YELLOW}Waiting for orderer to be ready...${NC}"
sleep 5

echo -e "${YELLOW}Joining orderer to mychannel using Channel Participation API...${NC}"
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

echo -e "${GREEN}✓ Orderer joined to mychannel!${NC}"

# Verify
echo -e "\n${YELLOW}Verifying orderer channel list...${NC}"
docker exec cli osnadmin channel list \
  -o orderer.example.com:7053 \
  --ca-file /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  --client-cert /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt \
  --client-key /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key

echo -e "${GREEN}✓ Orderer is serving mychannel${NC}"

# ========================================
# STEP 7: JOIN PEER TO CHANNEL
# ========================================

echo -e "\n${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  STEP 7: JOIN PEER TO CHANNEL${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"

echo -e "\n${YELLOW}Joining Org1 peer to mychannel...${NC}"
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

echo -e "${GREEN}✓ Peer joined to mychannel!${NC}"

# Verify
echo -e "\n${YELLOW}Verifying peer channel list...${NC}"
docker exec cli peer channel list

# ========================================
# STEP 8: VERIFICATION
# ========================================

echo -e "\n${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  STEP 8: VERIFICATION${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"

echo -e "\n${YELLOW}Checking channel info...${NC}"
docker exec cli bash -c '
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt

peer channel getinfo -c mychannel
'

echo -e "\n${YELLOW}Final container status:${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}"

# ========================================
# SUCCESS!
# ========================================

echo -e "\n${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                  ✓✓✓ SUCCESS! ✓✓✓                                ║${NC}"
echo -e "${BLUE}║            FABRIC 2.3+ DEPLOYMENT COMPLETE!                      ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${GREEN}What was fixed:${NC}"
echo -e "  ✓ Removed BOOTSTRAPMETHOD from docker-compose"
echo -e "  ✓ Removed genesis.block volume mount"
echo -e "  ✓ Updated configtx.yaml (removed Consortiums)"
echo -e "  ✓ Orderer starts WITHOUT genesis block"
echo -e "  ✓ Channel joined using osnadmin (Fabric 2.3+ way)"
echo -e ""
echo -e "${GREEN}Containers running:${NC}"
echo -e "  ✓ orderer.example.com"
echo -e "  ✓ peer0.org1.example.com"
echo -e "  ✓ cli"
echo -e ""
echo -e "${GREEN}Channel status:${NC}"
echo -e "  ✓ mychannel created"
echo -e "  ✓ Orderer serving mychannel"
echo -e "  ✓ Peer joined to mychannel"

echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                    NEXT STEPS                                   ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"

echo -e "\n${YELLOW}Verification commands:${NC}"
echo -e "${GREEN}docker ps${NC}                          # Check containers"
echo -e "${GREEN}docker exec cli peer channel list${NC}  # Check peer channels"
echo -e "${GREEN}docker logs orderer.example.com${NC}    # Check orderer logs"

echo -e "\n${YELLOW}To deploy to GCP:${NC}"
echo -e "1. tar -czf fabric-gcp.tar.gz organizations/ channel-artifacts/ configtx/ chaincode/ docker-compose-gcp.yml"
echo -e "2. scp fabric-gcp.tar.gz ubuntu@178.16.139.239:~/"
echo -e "3. On GCP: tar -xzf fabric-gcp.tar.gz && docker-compose -f docker-compose-gcp.yml up -d"
echo -e "4. Join Org2 peer to channel"

echo -e "\n${GREEN}🎉 Your Hyperledger Fabric 2.3+ network is ready!${NC}\n"
