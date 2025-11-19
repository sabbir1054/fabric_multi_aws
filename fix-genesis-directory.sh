#!/bin/bash

# ========================================
# FIX: genesis.block is a directory
# This script removes the directory and ensures it's created as a file
# ========================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  Fixing genesis.block directory issue${NC}"
echo -e "${YELLOW}========================================${NC}"

# Check if genesis.block exists and is a directory
if [ -d "./system-genesis-block/genesis.block" ]; then
    echo -e "\n${YELLOW}Found: genesis.block is a DIRECTORY (should be a file)${NC}"

    # Use sudo to remove it forcefully
    echo -e "${YELLOW}Removing directory with sudo...${NC}"
    sudo rm -rf ./system-genesis-block/genesis.block

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Successfully removed genesis.block directory${NC}"
    else
        echo -e "${RED}✗ Failed to remove. Trying without sudo...${NC}"
        rm -rf ./system-genesis-block/genesis.block
    fi
elif [ -f "./system-genesis-block/genesis.block" ]; then
    echo -e "${GREEN}✓ genesis.block is already a file (correct!)${NC}"
    echo -e "${YELLOW}Removing it anyway to start fresh...${NC}"
    rm -f ./system-genesis-block/genesis.block
else
    echo -e "${YELLOW}genesis.block doesn't exist yet (this is fine)${NC}"
fi

# Clean the entire directory and recreate
echo -e "\n${YELLOW}Cleaning system-genesis-block directory...${NC}"
sudo rm -rf ./system-genesis-block
mkdir -p ./system-genesis-block
sudo chmod 777 ./system-genesis-block

echo -e "${GREEN}✓ Directory cleaned and ready${NC}"

# Verify
echo -e "\n${YELLOW}Verification:${NC}"
ls -la ./system-genesis-block/
echo -e "${GREEN}✓ Directory is empty and ready for fresh genesis block${NC}"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Fix Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\n${YELLOW}Now you can continue with the fresh start.${NC}"
