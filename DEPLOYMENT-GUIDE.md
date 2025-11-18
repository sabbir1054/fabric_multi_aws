# Hyperledger Fabric Multi-Machine Deployment Guide

**The Complete Guide - Everything You Need in One Place**

---

## 🚀 Quick Start (If You Just Want to Deploy)

### Machine 1 (13.239.132.194)
```bash
./setup-machine1-auto.sh
```

### Machine 2 (178.16.139.239)
```bash
tar -xzf machine2-package.tar.gz
./setup-machine2-auto.sh
```

**Done!** Network deployed in ~5 minutes.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Network Architecture](#network-architecture)
3. [Installation Steps](#installation-steps)
4. [Deployment Scripts](#deployment-scripts)
5. [Testing the Network](#testing-the-network)
6. [Troubleshooting](#troubleshooting)
7. [Next Steps](#next-steps)

---

## Prerequisites

### Required Software

**Both Machines:**
- Docker (v20.10+)
- Docker Compose (v1.29+)
- Basic tools: curl, tar, ssh

**Machine 1 Only:**
- Fabric binaries (cryptogen, configtxgen, peer)
- **Note:** Auto-installed by setup scripts if missing!

### System Requirements
- **CPU:** 2+ cores
- **RAM:** 4GB minimum (8GB recommended)
- **Disk:** 50GB+ free space
- **OS:** Ubuntu 18.04+, CentOS 7+, Debian 10+, Amazon Linux 2

### Network Requirements
- Both machines can ping each other
- Firewall allows these ports:
  - **Machine 1:** 7050, 7051, 8051, 7054
  - **Machine 2:** 9051, 10051, 7054

### Check Prerequisites

```bash
# On Machine 1
./check-prerequisites.sh --machine1

# On Machine 2
./check-prerequisites.sh --machine2
```

### Install Missing Prerequisites

```bash
# On Machine 1
./install-prerequisites.sh --machine1

# On Machine 2
./install-prerequisites.sh --machine2

# Then logout and login again
```

---

## Network Architecture

```
Machine 1: 13.239.132.194          Machine 2: 178.16.139.239
┌─────────────────────────┐        ┌─────────────────────────┐
│  Orderer:7050           │◄──────►│  Peer0.Org2:9051        │
│  Peer0.Org1:7051        │        │  Peer1.Org2:10051       │
│  Peer1.Org1:8051        │        │  CA1:7054               │
│  CA0:7054               │        │  CouchDB2, CouchDB3     │
│  CouchDB0, CouchDB1     │        │                         │
└─────────────────────────┘        └─────────────────────────┘

Channel: mychannel
Chaincode: asset-transfer-basic (TypeScript)
Consensus: EtcdRaft
TLS: Enabled
```

---

## Installation Steps

### Step 1: Install Prerequisites (One-time, ~10-15 minutes)

**On Machine 1:**
```bash
./install-prerequisites.sh --machine1
# Logout and login
```

**On Machine 2:**
```bash
./install-prerequisites.sh --machine2
# Logout and login
```

### Step 2: Deploy Machine 1 (~3 minutes)

```bash
./setup-machine1-auto.sh
```

**What it does:**
- ✅ Auto-installs Fabric binaries if missing (no prompts!)
- ✅ Generates all crypto materials
- ✅ Creates genesis block and channel config
- ✅ Starts Orderer + Org1 network
- ✅ Creates and joins channel
- ✅ Deploys chaincode to Org1
- ✅ Creates `machine2-package.tar.gz`

### Step 3: Transfer to Machine 2 (~1 minute)

```bash
# On Machine 1
scp machine2-package.tar.gz user@178.16.139.239:/path/to/fabric-network/
```

### Step 4: Deploy Machine 2 (~2 minutes)

```bash
# On Machine 2
tar -xzf machine2-package.tar.gz
./setup-machine2-auto.sh
```

**What it does:**
- ✅ Starts Org2 network
- ✅ Joins Org2 peers to channel
- ✅ Installs chaincode on Org2
- ✅ Approves chaincode for Org2
- ✅ Commits chaincode to channel
- ✅ **Network ready!**

---

## Deployment Scripts

### Auto Scripts (Recommended - No Prompts)

**Machine 1:**
```bash
./setup-machine1-auto.sh [channel_name] [chaincode_name]
# Default: ./setup-machine1-auto.sh mychannel asset-transfer-basic
```

**Machine 2:**
```bash
./setup-machine2-auto.sh [channel_name] [chaincode_name]
# Default: ./setup-machine2-auto.sh mychannel asset-transfer-basic
```

### Interactive Scripts (Prompts Before Installing)

**Machine 1:**
```bash
./setup-machine1.sh
# Asks "Install Fabric binaries? (y/n)" if missing
```

**Machine 2:**
```bash
./setup-machine2.sh
```

### Helper Scripts

Located in `scripts/` directory:
- `generate-crypto.sh` - Generate crypto materials
- `generate-genesis.sh` - Generate genesis block
- `create-channel.sh` - Create channel (Org1)
- `join-channel.sh` - Join channel (Org2)
- `deploy-chaincode.sh` - Deploy chaincode

### Utility Scripts

- `check-prerequisites.sh` - Verify all requirements
- `install-prerequisites.sh` - Auto-install prerequisites

---

## Testing the Network

### Initialize Chaincode (Run on Either Machine)

```bash
docker exec cli peer chaincode invoke \
    -o orderer.example.com:7050 --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    -C mychannel -n asset-transfer-basic \
    --peerAddresses peer0.org1.example.com:7051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
    --peerAddresses peer0.org2.example.com:9051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
    -c '{"function":"InitLedger","Args":[]}'
```

### Query Data

```bash
docker exec cli peer chaincode query \
    -C mychannel \
    -n asset-transfer-basic \
    -c '{"Args":["GetAllAssets"]}'
```

### Verify Network Status

```bash
# Check running containers
docker ps

# Check channel
docker exec cli peer channel list

# Check installed chaincode
docker exec cli peer lifecycle chaincode queryinstalled

# Check committed chaincode
docker exec cli peer lifecycle chaincode querycommitted -C mychannel

# View logs
docker logs -f peer0.org1.example.com  # Machine 1
docker logs -f peer0.org2.example.com  # Machine 2
docker logs -f orderer.example.com     # Machine 1
```

---

## Troubleshooting

### Common Issues

#### 1. "cryptogen not found"
**Solution:** The auto scripts will install it automatically! Just run:
```bash
./setup-machine1-auto.sh
```

Or manually install:
```bash
./install-prerequisites.sh --machine1
```

#### 2. "cannot load client cert" or "no such file or directory" for TLS certs
**Error:**
```
cannot load client cert for consenter orderer.example.com:7050:
open .../tls/server.crt: no such file or directory
```

**Cause:** Trying to create genesis block before crypto materials exist.

**Solution:**
```bash
# Clean up
rm -rf organizations/ system-genesis-block/

# Generate crypto materials FIRST
cryptogen generate --config=./crypto-config.yaml

# Verify
ls -la organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/

# Then run the full setup
./setup-machine1-auto.sh
```

**Note:** The updated scripts now check for this automatically and prevent the error!

See [QUICK-FIX.md](QUICK-FIX.md) for detailed solution.

#### 3. "Docker permission denied"
**Solution:**
```bash
sudo usermod -aG docker $USER
# Logout and login again
```

#### 4. Cannot connect between machines
**Solution:**
```bash
# Test connectivity
ping 178.16.139.239  # From Machine 1
ping 13.239.132.194  # From Machine 2

# Test specific ports
nc -zv 13.239.132.194 7050  # Test orderer from Machine 2
nc -zv 178.16.139.239 9051  # Test peer from Machine 1

# Check firewall
sudo ufw status  # Ubuntu/Debian
sudo firewall-cmd --list-all  # CentOS/RHEL
```

#### 5. Container fails to start
**Solution:**
```bash
# Check logs
docker logs <container_name>

# Restart container
docker restart <container_name>

# Restart entire network
docker-compose -f docker-compose-org1.yaml down
docker-compose -f docker-compose-org1.yaml up -d
```

#### 6. Chaincode installation fails
**Solution:**
```bash
# Make sure chaincode directory exists
ls -la chaincode/

# Check chaincode is packaged
docker exec cli peer lifecycle chaincode queryinstalled

# Rebuild if needed
cd chaincode && npm install && npm run build
```

### Start Over (Clean Slate)

**Machine 1:**
```bash
docker-compose -f docker-compose-org1.yaml down -v
rm -rf organizations/ system-genesis-block/ channel-artifacts/*.block
./setup-machine1-auto.sh
```

**Machine 2:**
```bash
docker-compose -f docker-compose-org2.yaml down -v
# Get new package from Machine 1
tar -xzf machine2-package.tar.gz
./setup-machine2-auto.sh
```

### Network Connectivity Issues

**Check if machines can communicate:**
```bash
# From Machine 1
ping -c 3 178.16.139.239

# From Machine 2
ping -c 3 13.239.132.194
```

**Configure firewall (Ubuntu/Debian):**
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

**Configure firewall (CentOS/RHEL):**
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

---

## Next Steps

### 1. Configure Your Backend

Update `ph_water_backend/` connection configuration to use the network.

**Example connection profile structure:**
```javascript
{
  "channels": {
    "mychannel": {
      "orderers": ["orderer.example.com"],
      "peers": {
        "peer0.org1.example.com": {},
        "peer0.org2.example.com": {}
      }
    }
  },
  "organizations": {
    "Org1": {
      "mspid": "Org1MSP",
      "peers": ["peer0.org1.example.com"]
    }
  },
  "orderers": {
    "orderer.example.com": {
      "url": "grpcs://13.239.132.194:7050"
    }
  },
  "peers": {
    "peer0.org1.example.com": {
      "url": "grpcs://13.239.132.194:7051"
    },
    "peer0.org2.example.com": {
      "url": "grpcs://178.16.139.239:9051"
    }
  }
}
```

### 2. Start Your Frontend

```bash
cd ph_water_frontend/
npm install
npm start
```

### 3. Monitor Your Network

```bash
# View all containers
docker ps

# Monitor logs in real-time
docker logs -f peer0.org1.example.com
docker logs -f orderer.example.com

# Check resource usage
docker stats
```

---

## Port Reference

### Machine 1 (13.239.132.194)
| Service | Port | Description |
|---------|------|-------------|
| Orderer | 7050 | gRPC endpoint |
| Orderer Admin | 7053 | Admin endpoint |
| Peer0.Org1 | 7051 | gRPC endpoint |
| Peer1.Org1 | 8051 | gRPC endpoint |
| CA0 | 7054 | Certificate Authority |
| CouchDB0 | 5984 | State database |
| CouchDB1 | 6984 | State database |

### Machine 2 (178.16.139.239)
| Service | Port | Description |
|---------|------|-------------|
| Peer0.Org2 | 9051 | gRPC endpoint |
| Peer1.Org2 | 10051 | gRPC endpoint |
| CA1 | 7054 | Certificate Authority |
| CouchDB2 | 7984 | State database |
| CouchDB3 | 8984 | State database |

---

## Useful Commands

### Docker Management
```bash
# View running containers
docker ps

# View all containers (including stopped)
docker ps -a

# Stop all containers
docker stop $(docker ps -aq)

# Remove all containers
docker rm $(docker ps -aq)

# Remove all volumes
docker volume prune -f

# View resource usage
docker stats

# View networks
docker network ls
```

### Peer Commands
```bash
# List channels
docker exec cli peer channel list

# Get channel info
docker exec cli peer channel getinfo -c mychannel

# List installed chaincode
docker exec cli peer lifecycle chaincode queryinstalled

# List committed chaincode
docker exec cli peer lifecycle chaincode querycommitted -C mychannel
```

### Chaincode Commands
```bash
# Query chaincode
docker exec cli peer chaincode query -C mychannel -n asset-transfer-basic -c '{"Args":["GetAllAssets"]}'

# Invoke chaincode
docker exec cli peer chaincode invoke \
    -o orderer.example.com:7050 --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    -C mychannel -n asset-transfer-basic \
    --peerAddresses peer0.org1.example.com:7051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
    --peerAddresses peer0.org2.example.com:9051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
    -c '{"function":"CreateAsset","Args":["asset1","blue","5","Tom","100"]}'
```

---

## Summary

✅ **Automated Scripts** - Just run one command per machine
✅ **Auto-Install** - Missing prerequisites installed automatically
✅ **Complete Documentation** - Everything in one place
✅ **Production Ready** - Modern Fabric 2.4 with EtcdRaft consensus
✅ **Your Code Preserved** - chaincode, backend, frontend ready to use

**Total Deployment Time:** ~5-10 minutes after prerequisites installed

---

## Quick Reference Card

```
┌──────────────────────────────────────────────────────────────┐
│                    QUICK REFERENCE                           │
├──────────────────────────────────────────────────────────────┤
│ Machine 1 IP: 13.239.132.194                                 │
│ Machine 2 IP: 178.16.139.239                                 │
│                                                              │
│ SETUP:                                                       │
│   Machine 1: ./setup-machine1-auto.sh                        │
│   Machine 2: ./setup-machine2-auto.sh                        │
│                                                              │
│ TEST:                                                        │
│   docker exec cli peer chaincode query \                     │
│     -C mychannel -n asset-transfer-basic \                   │
│     -c '{"Args":["GetAllAssets"]}'                           │
│                                                              │
│ LOGS:                                                        │
│   docker logs -f peer0.org1.example.com                      │
│   docker logs -f orderer.example.com                         │
│                                                              │
│ CLEANUP:                                                     │
│   docker-compose -f docker-compose-org1.yaml down -v         │
│   docker-compose -f docker-compose-org2.yaml down -v         │
└──────────────────────────────────────────────────────────────┘
```

---

**Need help?** All scripts include detailed error messages and troubleshooting steps.

**Ready to deploy?** Run `./setup-machine1-auto.sh` on Machine 1 to get started!
