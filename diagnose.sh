#!/bin/bash

# ========================================
# DIAGNOSTIC SCRIPT
# Checks the health of your Fabric network
# ========================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Fabric Network Diagnostic Tool${NC}"
echo -e "${BLUE}========================================${NC}"

# Determine if we're on AWS or GCP based on which compose file exists
if [ -f "docker-compose-aws.yml" ]; then
    LOCATION="AWS"
    COMPOSE_FILE="docker-compose-aws.yml"
    PEER_NAME="peer0.org1.example.com"
    CLI_NAME="cli"
elif [ -f "docker-compose-gcp.yml" ]; then
    LOCATION="GCP"
    COMPOSE_FILE="docker-compose-gcp.yml"
    PEER_NAME="peer0.org2.example.com"
    CLI_NAME="cli_org2"
else
    echo -e "${RED}Error: Cannot find docker-compose file${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Detected Location: ${LOCATION}${NC}\n"

# Check 1: Docker Installation
echo -e "${YELLOW}[1/10] Checking Docker installation...${NC}"
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓ Docker is installed${NC}"
    docker --version
else
    echo -e "${RED}✗ Docker is NOT installed${NC}"
    exit 1
fi

# Check 2: Docker Compose
echo -e "\n${YELLOW}[2/10] Checking Docker Compose...${NC}"
if command -v docker-compose &> /dev/null; then
    echo -e "${GREEN}✓ Docker Compose is installed${NC}"
    docker-compose --version
else
    echo -e "${RED}✗ Docker Compose is NOT installed${NC}"
    exit 1
fi

# Check 3: Running Containers
echo -e "\n${YELLOW}[3/10] Checking running containers...${NC}"
RUNNING_CONTAINERS=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep -v NAMES)
if [ -z "$RUNNING_CONTAINERS" ]; then
    echo -e "${RED}✗ No containers are running${NC}"
    echo -e "${YELLOW}Run ./setup-${LOCATION,,}.sh first${NC}"
else
    echo -e "${GREEN}✓ Containers found:${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
fi

# Check 4: Orderer Status (AWS only)
if [ "$LOCATION" == "AWS" ]; then
    echo -e "\n${YELLOW}[4/10] Checking orderer status...${NC}"
    if docker ps | grep -q orderer.example.com; then
        STATUS=$(docker inspect orderer.example.com --format='{{.State.Status}}')
        if [ "$STATUS" == "running" ]; then
            echo -e "${GREEN}✓ Orderer is running${NC}"
            # Check orderer logs for errors
            ERROR_COUNT=$(docker logs orderer.example.com 2>&1 | grep -i "error" | wc -l)
            if [ "$ERROR_COUNT" -gt 0 ]; then
                echo -e "${YELLOW}⚠ Found $ERROR_COUNT errors in orderer logs${NC}"
            fi
        else
            echo -e "${RED}✗ Orderer is not running (Status: $STATUS)${NC}"
        fi
    else
        echo -e "${RED}✗ Orderer container not found${NC}"
    fi
else
    echo -e "\n${YELLOW}[4/10] Skipping orderer check (GCP node)${NC}"
fi

# Check 5: Peer Status
echo -e "\n${YELLOW}[5/10] Checking peer status...${NC}"
if docker ps | grep -q "$PEER_NAME"; then
    STATUS=$(docker inspect "$PEER_NAME" --format='{{.State.Status}}')
    if [ "$STATUS" == "running" ]; then
        echo -e "${GREEN}✓ Peer $PEER_NAME is running${NC}"
        # Check peer logs for errors
        ERROR_COUNT=$(docker logs "$PEER_NAME" 2>&1 | grep -i "error" | wc -l)
        if [ "$ERROR_COUNT" -gt 0 ]; then
            echo -e "${YELLOW}⚠ Found $ERROR_COUNT errors in peer logs${NC}"
        fi
    else
        echo -e "${RED}✗ Peer is not running (Status: $STATUS)${NC}"
    fi
else
    echo -e "${RED}✗ Peer container not found${NC}"
fi

# Check 6: CLI Container
echo -e "\n${YELLOW}[6/10] Checking CLI container...${NC}"
if docker ps | grep -q "$CLI_NAME"; then
    echo -e "${GREEN}✓ CLI container is running${NC}"
else
    echo -e "${RED}✗ CLI container not found${NC}"
fi

# Check 7: Crypto Materials
echo -e "\n${YELLOW}[7/10] Checking crypto materials...${NC}"
if [ -d "./organizations/ordererOrganizations" ] || [ -d "./organizations/peerOrganizations" ]; then
    echo -e "${GREEN}✓ Crypto materials found${NC}"

    # Check TLS certificates
    if [ "$LOCATION" == "AWS" ]; then
        if [ -d "./organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls" ]; then
            echo -e "${GREEN}  ✓ Orderer TLS certificates found${NC}"
        else
            echo -e "${RED}  ✗ Orderer TLS certificates missing${NC}"
        fi

        if [ -d "./organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls" ]; then
            echo -e "${GREEN}  ✓ Org1 Peer TLS certificates found${NC}"
        else
            echo -e "${RED}  ✗ Org1 Peer TLS certificates missing${NC}"
        fi
    else
        if [ -d "./organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls" ]; then
            echo -e "${GREEN}  ✓ Org2 Peer TLS certificates found${NC}"
        else
            echo -e "${RED}  ✗ Org2 Peer TLS certificates missing${NC}"
        fi
    fi
else
    echo -e "${RED}✗ Crypto materials not found${NC}"
fi

# Check 8: Channel Artifacts
echo -e "\n${YELLOW}[8/10] Checking channel artifacts...${NC}"
if [ -d "./channel-artifacts" ]; then
    echo -e "${GREEN}✓ Channel artifacts directory exists${NC}"

    if [ -f "./channel-artifacts/channel.tx" ]; then
        echo -e "${GREEN}  ✓ channel.tx found${NC}"
    else
        echo -e "${RED}  ✗ channel.tx missing${NC}"
    fi

    if [ -f "./channel-artifacts/mychannel.block" ]; then
        echo -e "${GREEN}  ✓ mychannel.block found${NC}"
    else
        echo -e "${YELLOW}  ⚠ mychannel.block not found (channel not created yet)${NC}"
    fi
else
    echo -e "${RED}✗ Channel artifacts directory not found${NC}"
fi

# Check 9: Genesis Block (AWS only)
if [ "$LOCATION" == "AWS" ]; then
    echo -e "\n${YELLOW}[9/10] Checking genesis block...${NC}"
    if [ -f "./system-genesis-block/genesis.block" ]; then
        echo -e "${GREEN}✓ Genesis block found${NC}"
        ls -lh ./system-genesis-block/genesis.block
    else
        echo -e "${RED}✗ Genesis block not found${NC}"
    fi
else
    echo -e "\n${YELLOW}[9/10] Skipping genesis block check (GCP node)${NC}"
fi

# Check 10: Channel Join Status
echo -e "\n${YELLOW}[10/10] Checking if peer has joined channel...${NC}"
if docker ps | grep -q "$CLI_NAME"; then
    CHANNELS=$(docker exec "$CLI_NAME" peer channel list 2>&1)
    if echo "$CHANNELS" | grep -q "mychannel"; then
        echo -e "${GREEN}✓ Peer has joined mychannel${NC}"

        # Get channel info
        echo -e "\n${GREEN}Channel Info:${NC}"
        docker exec "$CLI_NAME" bash -c "
        export CORE_PEER_TLS_ENABLED=true
        peer channel getinfo -c mychannel 2>/dev/null
        "
    else
        echo -e "${YELLOW}⚠ Peer has not joined mychannel yet${NC}"
        echo -e "${YELLOW}Available channels:${NC}"
        echo "$CHANNELS"
    fi
else
    echo -e "${RED}✗ Cannot check channel status (CLI not running)${NC}"
fi

# Network Connectivity Test
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}  Network Connectivity${NC}"
echo -e "${BLUE}========================================${NC}"

if [ "$LOCATION" == "AWS" ]; then
    echo -e "\n${YELLOW}Testing connection to GCP peer (178.16.139.239)...${NC}"
    if ping -c 2 178.16.139.239 > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Can reach GCP peer IP${NC}"
    else
        echo -e "${RED}✗ Cannot reach GCP peer IP${NC}"
    fi
else
    echo -e "\n${YELLOW}Testing connection to AWS orderer (3.27.144.169)...${NC}"
    if ping -c 2 3.27.144.169 > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Can reach AWS orderer IP${NC}"
    else
        echo -e "${RED}✗ Cannot reach AWS orderer IP${NC}"
    fi
fi

# Summary
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}  Diagnostic Summary${NC}"
echo -e "${BLUE}========================================${NC}"

echo -e "\n${YELLOW}Next Steps:${NC}"
if [ "$LOCATION" == "AWS" ]; then
    echo -e "1. If orderer is not running: Check logs with ${GREEN}docker logs orderer.example.com${NC}"
    echo -e "2. If channel not created: Run ${GREEN}./create-channel-aws.sh${NC}"
    echo -e "3. View logs: ${GREEN}docker logs -f peer0.org1.example.com${NC}"
else
    echo -e "1. If peer is not running: Check logs with ${GREEN}docker logs peer0.org2.example.com${NC}"
    echo -e "2. If channel not joined: Run ${GREEN}./join-channel-gcp.sh${NC}"
    echo -e "3. View logs: ${GREEN}docker logs -f peer0.org2.example.com${NC}"
fi

echo -e "\n${YELLOW}Useful Commands:${NC}"
echo -e "View all containers: ${GREEN}docker ps -a${NC}"
echo -e "View networks: ${GREEN}docker network ls${NC}"
echo -e "View volumes: ${GREEN}docker volume ls${NC}"
echo -e "Restart network: ${GREEN}docker-compose -f $COMPOSE_FILE restart${NC}"

echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}  Diagnostic Complete${NC}"
echo -e "${BLUE}========================================${NC}\n"
