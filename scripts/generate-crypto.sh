#!/bin/bash
#
# Generate crypto materials using cryptogen
# Run this script on Machine 1
#

set -e

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Generating crypto materials...${NC}"

# Remove existing crypto materials
if [ -d "organizations" ]; then
    echo "Removing existing organizations directory..."
    rm -rf organizations
fi

# Generate crypto materials using cryptogen
cryptogen generate --config=./crypto-config.yaml

echo -e "${GREEN}Crypto materials generated successfully!${NC}"
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "1. Generate genesis block and channel configuration (run ./scripts/generate-genesis.sh)"
echo "2. Copy the entire 'organizations' directory to Machine 2"
echo ""
