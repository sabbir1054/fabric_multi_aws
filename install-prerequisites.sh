#!/bin/bash
#
# Automated Prerequisites Installation Script
# Detects OS and installs required software
#
# Usage: ./install-prerequisites.sh [--machine1|--machine2]
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
MACHINE_TYPE=${1:-"--machine1"}  # Default to machine1 (installs Fabric binaries)
FABRIC_VERSION="2.4.0"
FABRIC_CA_VERSION="1.5.2"

echo -e "${BLUE}"
echo "================================================================================"
echo "  Hyperledger Fabric - Prerequisites Installation"
echo "================================================================================"
echo -e "${NC}"

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    elif [ -f /etc/redhat-release ]; then
        OS="rhel"
    else
        OS=$(uname -s)
    fi

    echo -e "${GREEN}Detected OS: $OS${NC}"
}

# Check if running as root
check_root() {
    if [ "$EUID" -eq 0 ]; then
        echo -e "${RED}Please do not run this script as root${NC}"
        echo "Run as a regular user with sudo privileges"
        exit 1
    fi
}

# Install Docker on Ubuntu/Debian
install_docker_ubuntu() {
    echo -e "${GREEN}Installing Docker on Ubuntu/Debian...${NC}"

    # Update package index
    sudo apt-get update

    # Install prerequisites
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # Add Docker GPG key
    curl -fsSL https://download.docker.com/linux/$OS/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # Set up repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$OS \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io

    # Add user to docker group
    sudo usermod -aG docker $USER

    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker

    echo -e "${GREEN}✓ Docker installed successfully${NC}"
}

# Install Docker on CentOS/RHEL
install_docker_centos() {
    echo -e "${GREEN}Installing Docker on CentOS/RHEL...${NC}"

    # Remove old versions
    sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine 2>/dev/null || true

    # Install required packages
    sudo yum install -y yum-utils device-mapper-persistent-data lvm2

    # Set up repository
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

    # Install Docker
    sudo yum install -y docker-ce docker-ce-cli containerd.io

    # Add user to docker group
    sudo usermod -aG docker $USER

    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker

    echo -e "${GREEN}✓ Docker installed successfully${NC}"
}

# Install Docker Compose
install_docker_compose() {
    echo -e "${GREEN}Installing Docker Compose...${NC}"

    # Download Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

    # Make executable
    sudo chmod +x /usr/local/bin/docker-compose

    # Create symlink
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose 2>/dev/null || true

    echo -e "${GREEN}✓ Docker Compose installed successfully${NC}"
}

# Install Fabric binaries
install_fabric_binaries() {
    echo -e "${GREEN}Installing Hyperledger Fabric binaries...${NC}"

    # Create directory
    mkdir -p $HOME/fabric-binaries
    cd $HOME/fabric-binaries

    # Download and install
    curl -sSL https://bit.ly/2ysbOFE | bash -s -- $FABRIC_VERSION $FABRIC_CA_VERSION

    # Add to PATH
    export PATH=$PATH:$HOME/fabric-binaries/bin

    # Add to bashrc
    if ! grep -q "fabric-binaries/bin" ~/.bashrc; then
        echo 'export PATH=$PATH:$HOME/fabric-binaries/bin' >> ~/.bashrc
    fi

    # Copy binaries to project directory
    if [ -d "$OLDPWD/bin" ]; then
        echo "Binaries already exist in project"
    else
        cp -r bin $OLDPWD/ 2>/dev/null || true
    fi

    cd $OLDPWD

    echo -e "${GREEN}✓ Fabric binaries installed successfully${NC}"
    echo -e "${YELLOW}Note: You may need to logout and login again for PATH changes to take effect${NC}"
}

# Install system utilities
install_utilities_ubuntu() {
    echo -e "${GREEN}Installing system utilities...${NC}"
    sudo apt-get install -y git curl wget tar gzip net-tools
    echo -e "${GREEN}✓ System utilities installed${NC}"
}

install_utilities_centos() {
    echo -e "${GREEN}Installing system utilities...${NC}"
    sudo yum install -y git curl wget tar gzip net-tools
    echo -e "${GREEN}✓ System utilities installed${NC}"
}

# Main installation
main() {
    check_root
    detect_os

    echo ""
    echo "Installation type: $MACHINE_TYPE"
    echo ""

    # Check if Docker is already installed
    if command -v docker &> /dev/null; then
        echo -e "${YELLOW}Docker is already installed ($(docker --version))${NC}"
    else
        case $OS in
            ubuntu|debian)
                install_docker_ubuntu
                ;;
            centos|rhel|amzn)
                install_docker_centos
                ;;
            *)
                echo -e "${RED}Unsupported OS: $OS${NC}"
                echo "Please install Docker manually"
                exit 1
                ;;
        esac
    fi

    # Check if Docker Compose is installed
    if command -v docker-compose &> /dev/null; then
        echo -e "${YELLOW}Docker Compose is already installed ($(docker-compose --version))${NC}"
    else
        install_docker_compose
    fi

    # Install system utilities
    case $OS in
        ubuntu|debian)
            install_utilities_ubuntu
            ;;
        centos|rhel|amzn)
            install_utilities_centos
            ;;
    esac

    # Install Fabric binaries (only for Machine 1)
    if [ "$MACHINE_TYPE" = "--machine1" ]; then
        if command -v cryptogen &> /dev/null; then
            echo -e "${YELLOW}Fabric binaries already installed ($(cryptogen version 2>&1 | head -1))${NC}"
        else
            install_fabric_binaries
        fi
    else
        echo -e "${YELLOW}Skipping Fabric binaries (not needed for Machine 2)${NC}"
    fi

    # Final verification
    echo ""
    echo -e "${BLUE}================================================================================${NC}"
    echo -e "${BLUE}  Installation Complete!${NC}"
    echo -e "${BLUE}================================================================================${NC}"
    echo ""

    echo -e "${GREEN}Installed Software:${NC}"
    echo "  Docker: $(docker --version 2>/dev/null || echo 'Not found')"
    echo "  Docker Compose: $(docker-compose --version 2>/dev/null || echo 'Not found')"

    if [ "$MACHINE_TYPE" = "--machine1" ]; then
        echo "  Cryptogen: $(cryptogen version 2>&1 | head -1 || echo 'Not found - logout and login')"
        echo "  Configtxgen: $(configtxgen version 2>&1 | head -1 || echo 'Not found - logout and login')"
    fi

    echo ""
    echo -e "${YELLOW}IMPORTANT:${NC}"
    echo "1. Logout and login again for group changes to take effect"
    echo "2. After re-login, verify with: docker ps"
    echo ""

    if [ "$MACHINE_TYPE" = "--machine1" ]; then
        echo -e "${GREEN}Next steps for Machine 1:${NC}"
        echo "  ./setup-machine1.sh"
    else
        echo -e "${GREEN}Next steps for Machine 2:${NC}"
        echo "  Wait for package from Machine 1, then run:"
        echo "  tar -xzf machine2-package.tar.gz"
        echo "  ./setup-machine2.sh"
    fi
    echo ""
}

# Run main
main
