# Prerequisites Guide

Before running the setup scripts, ensure both machines have the required software installed.

## Required Software (Both Machines)

### 1. Docker Engine
- Version: 20.10 or higher
- Used to run all Fabric containers

### 2. Docker Compose
- Version: 1.29 or higher (v2.x recommended)
- Used to orchestrate multi-container deployments

### 3. Hyperledger Fabric Binaries (Machine 1 Only)
- cryptogen - Generate crypto materials
- configtxgen - Generate genesis block and channel config
- peer - Peer commands
- orderer - Orderer commands
- fabric-ca-client - Certificate authority client

Version: 2.4.0

### 4. Basic System Utilities (Usually pre-installed)
- curl or wget
- tar
- gzip
- sed
- ssh/scp (for file transfer)
- git (optional, but recommended)

---

## Operating System Requirements

### Supported OS
- Ubuntu 18.04+ / Debian 10+
- CentOS 7+ / RHEL 7+
- macOS 10.14+
- Amazon Linux 2
- Other Linux distributions (with Docker support)

### Minimum Hardware
- **CPU**: 2 cores
- **RAM**: 4GB (8GB recommended)
- **Disk**: 50GB free space
- **Network**: Stable connection between machines

---

## Quick Installation (Automated)

We've created an automated script to install everything:

```bash
./install-prerequisites.sh
```

---

## Manual Installation Instructions

### Ubuntu/Debian

#### 1. Install Docker
```bash
# Update package index
sudo apt-get update

# Install prerequisites
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up stable repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Add your user to docker group
sudo usermod -aG docker $USER

# Enable Docker to start on boot
sudo systemctl enable docker
sudo systemctl start docker

# Verify installation
docker --version
```

#### 2. Install Docker Compose
```bash
# Download Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make it executable
sudo chmod +x /usr/local/bin/docker-compose

# Create symlink (if needed)
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Verify installation
docker-compose --version
```

#### 3. Install Fabric Binaries (Machine 1 Only)
```bash
# Install prerequisites
sudo apt-get install -y git curl wget

# Download and install Fabric binaries
curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.4.0 1.5.2

# This creates a 'bin' directory with all binaries
# Add to PATH (add to ~/.bashrc for permanent)
export PATH=$PATH:$PWD/bin

# Verify installation
cryptogen version
configtxgen version
peer version
```

---

### CentOS/RHEL/Amazon Linux

#### 1. Install Docker
```bash
# Remove old versions
sudo yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine

# Install required packages
sudo yum install -y yum-utils device-mapper-persistent-data lvm2

# Set up repository
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker Engine
sudo yum install -y docker-ce docker-ce-cli containerd.io

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER

# Verify installation
docker --version
```

#### 2. Install Docker Compose
```bash
# Download Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make executable
sudo chmod +x /usr/local/bin/docker-compose

# Verify
docker-compose --version
```

#### 3. Install Fabric Binaries (Machine 1 Only)
```bash
# Install prerequisites
sudo yum install -y git curl wget

# Download Fabric binaries
curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.4.0 1.5.2

# Add to PATH
export PATH=$PATH:$PWD/bin

# Verify
cryptogen version
configtxgen version
```

---

### macOS

#### 1. Install Docker Desktop
```bash
# Download and install Docker Desktop for Mac from:
# https://www.docker.com/products/docker-desktop

# Or use Homebrew
brew install --cask docker

# Start Docker Desktop from Applications
# Verify
docker --version
docker-compose --version
```

#### 2. Install Fabric Binaries
```bash
# Install prerequisites
brew install curl wget

# Download Fabric binaries
curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.4.0 1.5.2

# Add to PATH
export PATH=$PATH:$PWD/bin

# Verify
cryptogen version
configtxgen version
```

---

## Post-Installation Steps

### 1. Logout and Login Again
```bash
# For docker group to take effect
exit
# SSH back in or open new terminal
```

### 2. Verify Docker Works Without Sudo
```bash
docker ps
# Should work without "permission denied" error
```

### 3. Test Docker
```bash
docker run hello-world
```

### 4. Pull Fabric Images (Optional - will be pulled automatically)
```bash
docker pull hyperledger/fabric-peer:2.4
docker pull hyperledger/fabric-orderer:2.4
docker pull hyperledger/fabric-ca:latest
docker pull hyperledger/fabric-tools:2.4
docker pull couchdb:3.1.1
```

---

## Network Configuration

### Firewall Ports (Both Machines)

**Machine 1 needs to allow inbound:**
- 7050 (Orderer)
- 7051 (Peer0.Org1)
- 8051 (Peer1.Org1)
- 7054 (CA)

**Machine 2 needs to allow inbound:**
- 9051 (Peer0.Org2)
- 10051 (Peer1.Org2)
- 7054 (CA)

#### Ubuntu/Debian Firewall (UFW)
```bash
# Machine 1
sudo ufw allow 7050/tcp
sudo ufw allow 7051/tcp
sudo ufw allow 8051/tcp
sudo ufw allow 7054/tcp

# Machine 2
sudo ufw allow 9051/tcp
sudo ufw allow 10051/tcp
sudo ufw allow 7054/tcp
```

#### CentOS/RHEL Firewall (firewalld)
```bash
# Machine 1
sudo firewall-cmd --permanent --add-port=7050/tcp
sudo firewall-cmd --permanent --add-port=7051/tcp
sudo firewall-cmd --permanent --add-port=8051/tcp
sudo firewall-cmd --permanent --add-port=7054/tcp
sudo firewall-cmd --reload

# Machine 2
sudo firewall-cmd --permanent --add-port=9051/tcp
sudo firewall-cmd --permanent --add-port=10051/tcp
sudo firewall-cmd --permanent --add-port=7054/tcp
sudo firewall-cmd --reload
```

#### AWS Security Groups
If using AWS EC2, configure security groups to allow the above ports.

---

## Verification Checklist

Run these commands to verify everything is installed:

### Both Machines
```bash
# Check Docker
docker --version
docker ps

# Check Docker Compose
docker-compose --version

# Check system utilities
tar --version
curl --version
```

### Machine 1 Only
```bash
# Check Fabric binaries
cryptogen version
configtxgen version
peer version

# Verify PATH
echo $PATH | grep bin
```

### Network Connectivity
```bash
# From Machine 1, ping Machine 2
ping -c 3 178.16.139.239

# From Machine 2, ping Machine 1
ping -c 3 13.239.132.194

# Test specific ports
nc -zv 178.16.139.239 9051  # From Machine 1
nc -zv 13.239.132.194 7050  # From Machine 2
```

---

## Troubleshooting

### Docker Permission Denied
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Logout and login again
exit
```

### Cannot Connect Between Machines
```bash
# Check firewall
sudo ufw status  # Ubuntu
sudo firewall-cmd --list-all  # CentOS

# Check if port is listening
sudo netstat -tlnp | grep 7050
```

### Fabric Binaries Not Found
```bash
# Add to PATH permanently
echo 'export PATH=$PATH:$HOME/fabric-samples/bin' >> ~/.bashrc
source ~/.bashrc
```

### Docker Compose Version Issues
```bash
# Install specific version
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

---

## Ready to Deploy?

Once all prerequisites are installed, you can proceed with deployment:

1. ✅ Read **START-HERE.md**
2. ✅ Run `./setup-machine1.sh` on Machine 1
3. ✅ Transfer files and run `./setup-machine2.sh` on Machine 2

---

## Quick Check Script

Run this to check all prerequisites:

```bash
./check-prerequisites.sh
```

This will verify all required software and provide installation instructions if anything is missing.
