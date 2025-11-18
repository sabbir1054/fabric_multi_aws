#!/bin/bash

# Quick fix for permission issues

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  FIXING PERMISSION ISSUES${NC}"
echo -e "${YELLOW}========================================${NC}"

echo -e "\n${YELLOW}[1/3] Removing old genesis block directory...${NC}"
sudo rm -rf ./system-genesis-block
mkdir -p ./system-genesis-block
sudo chmod 777 ./system-genesis-block
echo -e "${GREEN}✓ Genesis block directory recreated with proper permissions${NC}"

echo -e "\n${YELLOW}[2/3] Fixing channel artifacts directory...${NC}"
sudo rm -rf ./channel-artifacts
mkdir -p ./channel-artifacts
sudo chmod 777 ./channel-artifacts
echo -e "${GREEN}✓ Channel artifacts directory recreated with proper permissions${NC}"

echo -e "\n${YELLOW}[3/3] Cleaning temp files...${NC}"
sudo rm -f /tmp/genesis_fresh.block
sudo rm -f /tmp/genesis_new.block
sudo rm -f /tmp/genesis.block.tmp
echo -e "${GREEN}✓ Temp files cleaned${NC}"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  ✓ PERMISSIONS FIXED!${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${YELLOW}Now run:${NC}"
echo -e "  ${GREEN}./FRESH-START.sh${NC}"
