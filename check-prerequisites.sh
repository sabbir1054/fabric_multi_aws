#!/bin/bash
#
# Check Prerequisites Script
# Verifies all required software is installed
#
# Usage: ./check-prerequisites.sh [--machine1|--machine2]
#

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

MACHINE_TYPE=${1:-"--machine1"}
ERRORS=0
WARNINGS=0

echo -e "${BLUE}"
echo "================================================================================"
echo "  Prerequisites Check"
echo "================================================================================"
echo -e "${NC}"
echo "Checking for: $MACHINE_TYPE"
echo ""

# Function to check command
check_command() {
    local cmd=$1
    local name=$2
    local required=$3
    local min_version=$4

    if command -v $cmd &> /dev/null; then
        local version=$($cmd --version 2>&1 | head -1)
        echo -e "${GREEN}✓${NC} $name: $version"
        return 0
    else
        if [ "$required" = "required" ]; then
            echo -e "${RED}✗${NC} $name: NOT FOUND (REQUIRED)"
            ((ERRORS++))
        else
            echo -e "${YELLOW}!${NC} $name: NOT FOUND (optional)"
            ((WARNINGS++))
        fi
        return 1
    fi
}

# Check basic utilities
echo -e "${BLUE}System Utilities:${NC}"
check_command "curl" "curl" "required"
check_command "tar" "tar" "required"
check_command "gzip" "gzip" "required"
check_command "sed" "sed" "required"
check_command "git" "git" "optional"
check_command "nc" "netcat" "optional"
check_command "ssh" "ssh" "required"
check_command "scp" "scp" "required"
echo ""

# Check Docker
echo -e "${BLUE}Docker:${NC}"
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version 2>&1)
    echo -e "${GREEN}✓${NC} Docker: $DOCKER_VERSION"

    # Test Docker without sudo
    if docker ps &> /dev/null; then
        echo -e "${GREEN}✓${NC} Docker permissions: OK (can run without sudo)"
    else
        echo -e "${RED}✗${NC} Docker permissions: FAILED (cannot run without sudo)"
        echo -e "${YELLOW}  Fix: sudo usermod -aG docker \$USER && logout${NC}"
        ((ERRORS++))
    fi

    # Check Docker is running
    if docker info &> /dev/null; then
        echo -e "${GREEN}✓${NC} Docker daemon: Running"
    else
        echo -e "${RED}✗${NC} Docker daemon: Not running"
        echo -e "${YELLOW}  Fix: sudo systemctl start docker${NC}"
        ((ERRORS++))
    fi
else
    echo -e "${RED}✗${NC} Docker: NOT FOUND"
    ((ERRORS++))
fi
echo ""

# Check Docker Compose
echo -e "${BLUE}Docker Compose:${NC}"
if command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(docker-compose --version 2>&1)
    echo -e "${GREEN}✓${NC} Docker Compose: $COMPOSE_VERSION"
else
    echo -e "${RED}✗${NC} Docker Compose: NOT FOUND"
    ((ERRORS++))
fi
echo ""

# Check Fabric binaries (only for Machine 1)
if [ "$MACHINE_TYPE" = "--machine1" ]; then
    echo -e "${BLUE}Hyperledger Fabric Binaries (Machine 1 only):${NC}"

    check_command "cryptogen" "cryptogen" "required"
    check_command "configtxgen" "configtxgen" "required"
    check_command "peer" "peer" "required"
    check_command "orderer" "orderer" "optional"
    check_command "fabric-ca-client" "fabric-ca-client" "optional"

    # Check if binaries are in PATH
    if ! command -v cryptogen &> /dev/null; then
        echo ""
        echo -e "${YELLOW}Fabric binaries not found in PATH${NC}"
        echo -e "${YELLOW}Install with: ./install-prerequisites.sh --machine1${NC}"
    fi
    echo ""
fi

# Check network connectivity
echo -e "${BLUE}Network Connectivity:${NC}"

MACHINE1_IP="13.239.132.194"
MACHINE2_IP="178.16.139.239"

if [ "$MACHINE_TYPE" = "--machine1" ]; then
    TARGET_IP=$MACHINE2_IP
    TARGET_NAME="Machine 2"
else
    TARGET_IP=$MACHINE1_IP
    TARGET_NAME="Machine 1"
fi

echo -n "Testing connection to $TARGET_NAME ($TARGET_IP)... "
if ping -c 1 -W 2 $TARGET_IP &> /dev/null; then
    echo -e "${GREEN}✓ Reachable${NC}"
else
    echo -e "${RED}✗ Not reachable${NC}"
    echo -e "${YELLOW}  Warning: Cannot ping $TARGET_NAME${NC}"
    ((WARNINGS++))
fi
echo ""

# Check required ports
echo -e "${BLUE}Port Availability:${NC}"

if [ "$MACHINE_TYPE" = "--machine1" ]; then
    PORTS="7050 7051 8051 7054"
    echo "Checking if ports are available (should NOT be in use):"
else
    PORTS="9051 10051 7054"
    echo "Checking if ports are available (should NOT be in use):"
fi

for port in $PORTS; do
    if command -v netstat &> /dev/null; then
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            echo -e "${YELLOW}!${NC} Port $port: IN USE (may conflict)"
            ((WARNINGS++))
        else
            echo -e "${GREEN}✓${NC} Port $port: Available"
        fi
    elif command -v ss &> /dev/null; then
        if ss -tuln 2>/dev/null | grep -q ":$port "; then
            echo -e "${YELLOW}!${NC} Port $port: IN USE (may conflict)"
            ((WARNINGS++))
        else
            echo -e "${GREEN}✓${NC} Port $port: Available"
        fi
    else
        echo -e "${YELLOW}!${NC} Cannot check port $port (netstat/ss not found)"
    fi
done
echo ""

# Check disk space
echo -e "${BLUE}System Resources:${NC}"
AVAILABLE_SPACE=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$AVAILABLE_SPACE" -gt 20 ]; then
    echo -e "${GREEN}✓${NC} Disk space: ${AVAILABLE_SPACE}GB available"
else
    echo -e "${YELLOW}!${NC} Disk space: ${AVAILABLE_SPACE}GB available (20GB+ recommended)"
    ((WARNINGS++))
fi

# Check memory
TOTAL_MEM=$(free -g | awk '/^Mem:/{print $2}')
if [ "$TOTAL_MEM" -ge 4 ]; then
    echo -e "${GREEN}✓${NC} Memory: ${TOTAL_MEM}GB total"
else
    echo -e "${YELLOW}!${NC} Memory: ${TOTAL_MEM}GB total (4GB+ recommended)"
    ((WARNINGS++))
fi
echo ""

# Check required files
echo -e "${BLUE}Project Files:${NC}"
if [ -f "docker-compose-org1.yaml" ] || [ -f "docker-compose-org2.yaml" ]; then
    echo -e "${GREEN}✓${NC} Docker compose files found"
else
    echo -e "${RED}✗${NC} Docker compose files not found"
    ((ERRORS++))
fi

if [ -f "crypto-config.yaml" ]; then
    echo -e "${GREEN}✓${NC} crypto-config.yaml found"
else
    echo -e "${YELLOW}!${NC} crypto-config.yaml not found"
    ((WARNINGS++))
fi

if [ -d "chaincode" ]; then
    echo -e "${GREEN}✓${NC} chaincode directory found"
else
    echo -e "${YELLOW}!${NC} chaincode directory not found"
    ((WARNINGS++))
fi
echo ""

# Summary
echo -e "${BLUE}================================================================================${NC}"
echo -e "${BLUE}  Summary${NC}"
echo -e "${BLUE}================================================================================${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All prerequisites met!${NC}"
    echo ""
    echo -e "${GREEN}Ready to deploy:${NC}"
    if [ "$MACHINE_TYPE" = "--machine1" ]; then
        echo "  ./setup-machine1.sh"
    else
        echo "  ./setup-machine2.sh"
    fi
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}Prerequisites met with $WARNINGS warning(s)${NC}"
    echo ""
    echo -e "${YELLOW}You can proceed, but some features may not work optimally${NC}"
    echo ""
    if [ "$MACHINE_TYPE" = "--machine1" ]; then
        echo "  ./setup-machine1.sh"
    else
        echo "  ./setup-machine2.sh"
    fi
else
    echo -e "${RED}✗ $ERRORS error(s) and $WARNINGS warning(s) found${NC}"
    echo ""
    echo -e "${RED}Please fix the errors before proceeding${NC}"
    echo ""
    echo -e "${YELLOW}To install missing prerequisites:${NC}"
    echo "  ./install-prerequisites.sh $MACHINE_TYPE"
    exit 1
fi

echo ""
