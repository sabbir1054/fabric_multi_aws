#!/bin/bash

# IMMEDIATE FIX FOR ORDERER ISSUE
# This script diagnoses and fixes why orderer won't run

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}========================================${NC}"
echo -e "${RED}  ORDERER FIX - DEEP DIAGNOSIS${NC}"
echo -e "${RED}========================================${NC}"

# Step 1: Check if orderer container exists (even if stopped)
echo -e "\n${YELLOW}[1/8] Checking for orderer container...${NC}"
if docker ps -a | grep -q orderer.example.com; then
    STATUS=$(docker inspect -f '{{.State.Status}}' orderer.example.com 2>/dev/null)
    echo -e "Orderer container found with status: ${YELLOW}$STATUS${NC}"

    if [ "$STATUS" = "exited" ] || [ "$STATUS" = "created" ]; then
        echo -e "${RED}Orderer is NOT running. Checking why it exited...${NC}"
        echo -e "\n${YELLOW}=== ORDERER LOGS (Last 30 lines) ===${NC}"
        docker logs orderer.example.com 2>&1 | tail -30
        echo -e "${YELLOW}=== END LOGS ===${NC}\n"

        # Check for common errors
        if docker logs orderer.example.com 2>&1 | grep -q "panic"; then
            echo -e "${RED}FOUND PANIC! Orderer is crashing.${NC}"
            PANIC_MSG=$(docker logs orderer.example.com 2>&1 | grep -A5 "panic")
            echo -e "${RED}$PANIC_MSG${NC}"
        fi

        if docker logs orderer.example.com 2>&1 | grep -q "is a directory"; then
            echo -e "${RED}FOUND: Genesis block is a DIRECTORY issue${NC}"
        fi

        echo -e "\n${YELLOW}Removing failed orderer container...${NC}"
        docker rm -f orderer.example.com
    elif [ "$STATUS" = "running" ]; then
        echo -e "${GREEN}Orderer is already running!${NC}"
        docker ps | grep orderer
        exit 0
    fi
else
    echo -e "${YELLOW}No orderer container found. Will create new one.${NC}"
fi

# Step 2: Check genesis block
echo -e "\n${YELLOW}[2/8] Checking genesis block...${NC}"
if [ -d "./system-genesis-block/genesis.block" ]; then
    echo -e "${RED}✗ Genesis block is a DIRECTORY! This is the problem!${NC}"
    echo -e "${YELLOW}Fixing: Removing directory...${NC}"
    rm -rf ./system-genesis-block/genesis.block
    NEED_GENESIS=true
elif [ -f "./system-genesis-block/genesis.block" ]; then
    echo -e "${GREEN}✓ Genesis block is a file${NC}"
    ls -lh ./system-genesis-block/genesis.block
    NEED_GENESIS=false
else
    echo -e "${YELLOW}⚠ Genesis block doesn't exist${NC}"
    NEED_GENESIS=true
fi

# Step 3: Generate genesis block if needed
if [ "$NEED_GENESIS" = true ]; then
    echo -e "\n${YELLOW}[3/8] Generating genesis block...${NC}"

    # Make sure CLI is running
    if ! docker ps | grep -q cli; then
        echo -e "${YELLOW}Starting CLI container...${NC}"
        docker-compose -f docker-compose-aws.yml up -d cli
        sleep 3
    fi

    # Clean the directory
    rm -rf ./system-genesis-block/*
    mkdir -p ./system-genesis-block

    # Generate genesis block
    echo -e "${YELLOW}Running configtxgen...${NC}"
    docker exec cli bash -c "
    cd /opt/gopath/src/github.com/hyperledger/fabric/peer
    configtxgen -profile TwoOrgsOrdererGenesis \
      -channelID system-channel \
      -outputBlock genesis.block \
      -configPath /etc/hyperledger/fabric
    " 2>&1

    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to generate genesis block!${NC}"
        exit 1
    fi

    # Copy it properly
    echo -e "${YELLOW}Copying genesis block to host...${NC}"
    docker cp cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/genesis.block /tmp/genesis_temp.block
    mv /tmp/genesis_temp.block ./system-genesis-block/genesis.block

    # Verify it's a file
    if [ -f "./system-genesis-block/genesis.block" ]; then
        echo -e "${GREEN}✓ Genesis block created successfully as a FILE${NC}"
        ls -lh ./system-genesis-block/genesis.block
        file ./system-genesis-block/genesis.block
    else
        echo -e "${RED}Failed to create genesis block as file!${NC}"
        exit 1
    fi
else
    echo -e "\n${YELLOW}[3/8] Skipping genesis generation (already exists)${NC}"
fi

# Step 4: Check TLS certificates
echo -e "\n${YELLOW}[4/8] Checking TLS certificates...${NC}"
if [ -d "./organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls" ]; then
    echo -e "${GREEN}✓ Orderer TLS directory exists${NC}"

    if [ -f "./organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt" ] && \
       [ -f "./organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key" ] && \
       [ -f "./organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt" ]; then
        echo -e "${GREEN}✓ All TLS certificates found${NC}"
    else
        echo -e "${RED}✗ TLS certificates missing!${NC}"
        ls -la ./organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/
        exit 1
    fi
else
    echo -e "${RED}✗ TLS directory doesn't exist!${NC}"
    exit 1
fi

# Step 5: Check MSP
echo -e "\n${YELLOW}[5/8] Checking MSP...${NC}"
if [ -d "./organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp" ]; then
    echo -e "${GREEN}✓ Orderer MSP directory exists${NC}"
else
    echo -e "${RED}✗ MSP directory doesn't exist!${NC}"
    exit 1
fi

# Step 6: Check docker-compose configuration
echo -e "\n${YELLOW}[6/8] Checking docker-compose-aws.yml...${NC}"
if [ -f "docker-compose-aws.yml" ]; then
    echo -e "${GREEN}✓ docker-compose-aws.yml exists${NC}"
else
    echo -e "${RED}✗ docker-compose-aws.yml missing!${NC}"
    exit 1
fi

# Step 7: Start orderer
echo -e "\n${YELLOW}[7/8] Starting orderer...${NC}"
docker-compose -f docker-compose-aws.yml up -d orderer.example.com

echo -e "${YELLOW}Waiting 8 seconds for orderer to initialize...${NC}"
sleep 8

# Step 8: Verify orderer is running
echo -e "\n${YELLOW}[8/8] Verifying orderer...${NC}"
if docker ps | grep -q orderer.example.com; then
    echo -e "${GREEN}✓ Orderer container is RUNNING!${NC}"
    docker ps | grep orderer.example.com

    echo -e "\n${YELLOW}=== CHECKING ORDERER LOGS ===${NC}"
    docker logs orderer.example.com 2>&1 | tail -20

    # Check if serving
    if docker logs orderer.example.com 2>&1 | grep -q "Beginning to serve"; then
        echo -e "\n${GREEN}========================================${NC}"
        echo -e "${GREEN}  ✓✓✓ ORDERER IS WORKING! ✓✓✓${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo -e "\n${GREEN}Next steps:${NC}"
        echo -e "1. Run: ${BLUE}./create-channel-aws.sh${NC}"
        echo -e "2. Run: ${BLUE}./diagnose.sh${NC}"
    else
        # Check for panic
        if docker logs orderer.example.com 2>&1 | grep -q "panic"; then
            echo -e "\n${RED}========================================${NC}"
            echo -e "${RED}  ✗ ORDERER IS PANICKING!${NC}"
            echo -e "${RED}========================================${NC}"
            docker logs orderer.example.com 2>&1 | grep -A10 "panic"

            echo -e "\n${RED}Orderer crashed. Common causes:${NC}"
            echo -e "1. Genesis block is a directory (we fixed this)"
            echo -e "2. TLS certificates are wrong"
            echo -e "3. Configuration error in docker-compose"
            echo -e "\n${YELLOW}Run this to see full logs:${NC}"
            echo -e "${BLUE}docker logs orderer.example.com${NC}"
        else
            echo -e "\n${YELLOW}Orderer started but not serving yet. Wait a bit and check:${NC}"
            echo -e "${BLUE}docker logs -f orderer.example.com${NC}"
        fi
    fi
else
    echo -e "\n${RED}========================================${NC}"
    echo -e "${RED}  ✗ ORDERER FAILED TO START${NC}"
    echo -e "${RED}========================================${NC}"

    echo -e "\n${YELLOW}Checking if container exists but exited...${NC}"
    if docker ps -a | grep -q orderer.example.com; then
        echo -e "${RED}Orderer exited immediately. Check logs:${NC}"
        docker logs orderer.example.com 2>&1
    else
        echo -e "${RED}Orderer container was never created!${NC}"
        echo -e "${YELLOW}Check docker-compose:${NC}"
        docker-compose -f docker-compose-aws.yml config
    fi
fi
