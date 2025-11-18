#!/bin/bash

# Quick script to verify IP update was successful

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Verifying IP Address Update...${NC}\n"

# Check for old IP
OLD_IP_COUNT=$(grep -r "3.27.144.169" . --include="*.yml" --include="*.sh" --include="*.md" 2>/dev/null | wc -l)

if [ "$OLD_IP_COUNT" -eq 0 ]; then
    echo -e "${GREEN}✓ Old IP (3.27.144.169) completely removed${NC}"
else
    echo -e "${RED}✗ Old IP still found in $OLD_IP_COUNT locations:${NC}"
    grep -r "3.27.144.169" . --include="*.yml" --include="*.sh" --include="*.md" 2>/dev/null
fi

# Check for new IP
NEW_IP_COUNT=$(grep -r "13.239.132.194" . --include="*.yml" --include="*.sh" --include="*.md" 2>/dev/null | wc -l)

if [ "$NEW_IP_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✓ New IP (13.239.132.194) found in $NEW_IP_COUNT locations${NC}"
else
    echo -e "${RED}✗ New IP not found!${NC}"
fi

# Check docker-compose-gcp.yml specifically
echo -e "\n${YELLOW}Checking docker-compose-gcp.yml:${NC}"
if grep -q "13.239.132.194" docker-compose-gcp.yml; then
    echo -e "${GREEN}✓ GCP docker-compose has correct AWS IP${NC}"
    grep "13.239.132.194" docker-compose-gcp.yml
else
    echo -e "${RED}✗ GCP docker-compose missing new IP${NC}"
fi

echo -e "\n${YELLOW}Network Configuration:${NC}"
echo -e "AWS IP: ${GREEN}13.239.132.194${NC}"
echo -e "GCP IP: ${GREEN}178.16.139.239${NC}"

echo -e "\n${GREEN}Verification complete!${NC}"
