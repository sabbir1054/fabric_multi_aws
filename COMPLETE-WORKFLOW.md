# Complete Deployment Workflow

This guide shows the complete end-to-end workflow from fresh machines to running network.

## Overview

```
Machine 1 (13.239.132.194)          Machine 2 (178.16.139.239)
├── Install Prerequisites           ├── Install Prerequisites
├── Run setup-machine1.sh           ├── Receive package
└── Transfer files ─────────────────┼── Run setup-machine2.sh
                                    └── Network Ready! ✓
```

---

## Timeline

| Step | Machine | Command | Time |
|------|---------|---------|------|
| 1 | Both | `./install-prerequisites.sh` | 5-15 min |
| 2 | Both | Logout/Login | 1 min |
| 3 | Machine 1 | `./setup-machine1.sh` | 2-3 min |
| 4 | Machine 1 | Transfer package to Machine 2 | 1-2 min |
| 5 | Machine 2 | `./setup-machine2.sh` | 1-2 min |
| **Total** | | | **10-25 min** |

---

## Detailed Workflow

### Phase 1: Prerequisites Installation (One-time)

#### Machine 1 (13.239.132.194)

```bash
# 1. Check current status
./check-prerequisites.sh --machine1

# 2. Install if needed
./install-prerequisites.sh --machine1

# 3. Logout and login
exit
# SSH back in

# 4. Verify installation
./check-prerequisites.sh --machine1
docker ps  # Should work without sudo
```

#### Machine 2 (178.16.139.239)

```bash
# 1. Check current status
./check-prerequisites.sh --machine2

# 2. Install if needed
./install-prerequisites.sh --machine2

# 3. Logout and login
exit
# SSH back in

# 4. Verify installation
./check-prerequisites.sh --machine2
docker ps  # Should work without sudo
```

---

### Phase 2: Network Deployment

#### Machine 1 (13.239.132.194)

```bash
# Run the complete setup
./setup-machine1.sh

# What it does:
# ✓ Generates crypto materials
# ✓ Creates genesis block
# ✓ Starts Orderer + Org1 containers
# ✓ Creates channel 'mychannel'
# ✓ Joins Org1 peers
# ✓ Installs chaincode on Org1
# ✓ Creates machine2-package.tar.gz

# Check status
docker ps

# You should see:
# - orderer.example.com
# - peer0.org1.example.com
# - peer1.org1.example.com
# - ca0.example.com
# - couchdb0, couchdb1
# - cli
```

#### Transfer Package

```bash
# On Machine 1
scp machine2-package.tar.gz user@178.16.139.239:/path/to/fabric-network/

# Or if you have the package name
ls -lh machine2-package.tar.gz  # Verify it exists
```

#### Machine 2 (178.16.139.239)

```bash
# 1. Extract package
tar -xzf machine2-package.tar.gz

# 2. Run setup
./setup-machine2.sh

# What it does:
# ✓ Starts Org2 containers
# ✓ Joins Org2 peers to channel
# ✓ Installs chaincode on Org2
# ✓ Approves chaincode for Org2
# ✓ Commits chaincode to channel
# ✓ Network ready!

# Check status
docker ps

# You should see:
# - peer0.org2.example.com
# - peer1.org2.example.com
# - ca1.example.com
# - couchdb2, couchdb3
# - cli
```

---

### Phase 3: Verification

#### Test on Either Machine

```bash
# 1. Initialize the ledger
docker exec cli peer chaincode invoke \
    -o orderer.example.com:7050 --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    -C mychannel -n asset-transfer-basic \
    --peerAddresses peer0.org1.example.com:7051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
    --peerAddresses peer0.org2.example.com:9051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
    -c '{"function":"InitLedger","Args":[]}'

# 2. Query the ledger
docker exec cli peer chaincode query \
    -C mychannel \
    -n asset-transfer-basic \
    -c '{"Args":["GetAllAssets"]}'

# You should see a list of assets!
```

#### Verify Network

```bash
# Check all peers joined channel
docker exec cli peer channel list

# Check chaincode installed
docker exec cli peer lifecycle chaincode queryinstalled

# Check chaincode committed
docker exec cli peer lifecycle chaincode querycommitted -C mychannel

# View logs
docker logs -f peer0.org1.example.com  # Machine 1
docker logs -f peer0.org2.example.com  # Machine 2
docker logs -f orderer.example.com     # Machine 1
```

---

## What Gets Deployed

### Network Architecture

```
┌─────────────────────────────────────────┐
│   Machine 1: 13.239.132.194 (Org1)     │
├─────────────────────────────────────────┤
│  Orderer                                │
│  ├── Port: 7050 (gRPC)                  │
│  ├── Port: 7053 (Admin)                 │
│  └── Port: 9443 (Operations)            │
│                                         │
│  CA0 (Certificate Authority)            │
│  └── Port: 7054                         │
│                                         │
│  Peer0.Org1                             │
│  ├── Port: 7051 (gRPC)                  │
│  ├── Port: 9444 (Operations)            │
│  └── CouchDB0: 5984                     │
│                                         │
│  Peer1.Org1                             │
│  ├── Port: 8051 (gRPC)                  │
│  ├── Port: 9445 (Operations)            │
│  └── CouchDB1: 6984                     │
└─────────────────────────────────────────┘
                    │
                    │ Network
                    │
┌─────────────────────────────────────────┐
│   Machine 2: 178.16.139.239 (Org2)     │
├─────────────────────────────────────────┤
│  CA1 (Certificate Authority)            │
│  └── Port: 7054                         │
│                                         │
│  Peer0.Org2                             │
│  ├── Port: 9051 (gRPC)                  │
│  ├── Port: 9446 (Operations)            │
│  └── CouchDB2: 7984                     │
│                                         │
│  Peer1.Org2                             │
│  ├── Port: 10051 (gRPC)                 │
│  ├── Port: 9447 (Operations)            │
│  └── CouchDB3: 8984                     │
└─────────────────────────────────────────┘
```

### Channel Configuration

- **Channel Name**: mychannel
- **Consortium**: Consortium1
- **Organizations**: Org1MSP, Org2MSP
- **Orderer Type**: EtcdRaft (HA consensus)
- **TLS**: Enabled

### Chaincode

- **Name**: asset-transfer-basic (or your custom chaincode)
- **Version**: 1.0
- **Language**: Node.js/TypeScript
- **Endorsement Policy**: Majority endorsement
- **Installed on**: All 4 peers
- **Committed to**: mychannel

---

## Troubleshooting Quick Reference

### Container Issues

```bash
# Restart a container
docker restart peer0.org1.example.com

# View logs
docker logs -f peer0.org1.example.com

# Check container status
docker ps -a
```

### Network Issues

```bash
# Test connectivity
ping 178.16.139.239  # From Machine 1
ping 13.239.132.194  # From Machine 2

# Test port connectivity
nc -zv 13.239.132.194 7050  # Test orderer from Machine 2
nc -zv 178.16.139.239 9051  # Test peer from Machine 1
```

### Start Over

```bash
# Machine 1
docker-compose -f docker-compose-org1.yaml down -v
rm -rf organizations/ system-genesis-block/ channel-artifacts/*.block
./setup-machine1.sh

# Machine 2
docker-compose -f docker-compose-org2.yaml down -v
# Get new package from Machine 1
./setup-machine2.sh
```

---

## Next Steps After Deployment

### 1. Configure Backend

Update your `ph_water_backend/` connection configuration:

```javascript
// Example connection profile
{
  "name": "fabric-network",
  "version": "1.0.0",
  "client": {
    "organization": "Org1",
    "connection": {
      "timeout": {
        "peer": { "endorser": "300" },
        "orderer": "300"
      }
    }
  },
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
      "peers": ["peer0.org1.example.com"],
      "certificateAuthorities": ["ca0.example.com"]
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

### 2. Start Frontend

```bash
cd ph_water_frontend/
npm install
npm start
```

### 3. Monitor Network

```bash
# View all containers
docker ps

# Monitor logs
docker logs -f peer0.org1.example.com
docker logs -f orderer.example.com

# Check chaincode
docker exec cli peer chaincode query -C mychannel -n asset-transfer-basic -c '{"Args":["GetAllAssets"]}'
```

---

## Summary

✅ **Prerequisites**: Automated installation scripts
✅ **Deployment**: One command per machine
✅ **Verification**: Built-in tests
✅ **Documentation**: Complete guides
✅ **Your Code**: Preserved (chaincode, backend, frontend)

**Total Time**: 10-25 minutes from fresh machines to running network!

---

## Documentation Index

- 📘 `START-HERE.md` - Begin here (quick start)
- 📘 `PREREQUISITES.md` - Detailed prerequisites guide
- 📄 `PREREQUISITES-SUMMARY.txt` - Quick prerequisites reference
- 📘 `ONE-COMMAND-SETUP.md` - Simple deployment guide
- 📘 `QUICK-START.md` - Quick reference commands
- 📘 `SETUP-GUIDE.md` - Comprehensive setup documentation
- 📘 `COMPLETE-WORKFLOW.md` - This document

## Scripts Index

- 🔧 `check-prerequisites.sh` - Verify prerequisites
- 🔧 `install-prerequisites.sh` - Install prerequisites
- 🚀 `setup-machine1.sh` - Deploy Machine 1 (one command)
- 🚀 `setup-machine2.sh` - Deploy Machine 2 (one command)
