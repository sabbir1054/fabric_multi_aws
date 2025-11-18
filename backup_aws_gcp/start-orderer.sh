#!/bin/bash

# Simple script to start orderer and check if it's working

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  Starting Orderer${NC}"
echo -e "${YELLOW}========================================${NC}"

# Check if orderer container exists but is stopped
if docker ps -a | grep -q orderer.example.com; then
    echo -e "\n${YELLOW}[1/4] Orderer container exists, checking status...${NC}"
    STATUS=$(docker inspect -f '{{.State.Status}}' orderer.example.com 2>/dev/null)
    echo "Status: $STATUS"

    if [ "$STATUS" = "exited" ]; then
        echo -e "${YELLOW}Orderer exited. Checking logs for errors...${NC}"
        docker logs orderer.example.com 2>&1 | tail -20

        echo -e "\n${YELLOW}Removing stopped orderer...${NC}"
        docker rm orderer.example.com
    fi
else
    echo -e "\n${YELLOW}[1/4] No orderer container found${NC}"
fi

# Check if genesis.block is a file (not directory)
echo -e "\n${YELLOW}[2/4] Checking genesis block...${NC}"
if [ -f "./system-genesis-block/genesis.block" ]; then
    echo -e "${GREEN}✓ Genesis block is a FILE${NC}"
    ls -lh ./system-genesis-block/genesis.block
elif [ -d "./system-genesis-block/genesis.block" ]; then
    echo -e "${RED}✗ Genesis block is a DIRECTORY! Fixing...${NC}"
    rm -rf ./system-genesis-block/genesis.block

    # Generate new genesis block
    docker exec cli bash -c "
    cd /opt/gopath/src/github.com/hyperledger/fabric/peer
    configtxgen -profile TwoOrgsOrdererGenesis \
      -channelID system-channel \
      -outputBlock genesis.block \
      -configPath /etc/hyperledger/fabric
    "

    docker cp cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/genesis.block /tmp/gb.tmp
    mv /tmp/gb.tmp ./system-genesis-block/genesis.block
    echo -e "${GREEN}✓ Genesis block recreated as FILE${NC}"
else
    echo -e "${RED}✗ Genesis block missing!${NC}"
    exit 1
fi

# Start orderer
echo -e "\n${YELLOW}[3/4] Starting orderer...${NC}"
docker-compose -f docker-compose-aws.yml up -d orderer.example.com
sleep 5

# Check if orderer is running
echo -e "\n${YELLOW}[4/4] Verifying orderer...${NC}"
if docker ps | grep -q orderer.example.com; then
    echo -e "${GREEN}✓ Orderer is RUNNING!${NC}"
    docker ps | grep orderer.example.com

    echo -e "\n${YELLOW}Checking orderer logs...${NC}"
    sleep 2
    docker logs orderer.example.com 2>&1 | tail -15

    if docker logs orderer.example.com 2>&1 | grep -q "Beginning to serve"; then
        echo -e "\n${GREEN}========================================${NC}"
        echo -e "${GREEN}  ✓ ORDERER IS WORKING!${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo -e "\n${YELLOW}Next step: Run ./create-channel-aws.sh${NC}"
    else
        echo -e "\n${RED}Orderer started but may have issues. Check logs:${NC}"
        echo -e "${YELLOW}docker logs orderer.example.com${NC}"
    fi
else
    echo -e "${RED}✗ Orderer failed to start${NC}"
    echo -e "\n${YELLOW}Checking why it failed...${NC}"
    docker logs orderer.example.com 2>&1
fi
