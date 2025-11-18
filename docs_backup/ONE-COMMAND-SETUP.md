# One-Command Setup Guide

The simplest way to deploy your Hyperledger Fabric network across two machines.

## Overview

Just run one script on each machine - that's it!

```
Machine 1: ./setup-machine1.sh
Machine 2: ./setup-machine2.sh
```

## Complete Setup Process

### Step 1: On Machine 1 (13.239.132.194)

```bash
cd /path/to/fabric-network
./setup-machine1.sh
```

**What it does:**
- ✓ Cleans up old containers
- ✓ Generates all crypto materials
- ✓ Generates genesis block and channel config
- ✓ Starts Orderer + Org1 network
- ✓ Creates channel and joins Org1 peers
- ✓ Packages and installs chaincode on Org1
- ✓ Creates `machine2-package.tar.gz` for Machine 2

**Duration:** ~2-3 minutes

---

### Step 2: Transfer Package to Machine 2

```bash
# On Machine 1, transfer the package
scp machine2-package.tar.gz user@178.16.139.239:/path/to/fabric-network/
```

---

### Step 3: On Machine 2 (178.16.139.239)

```bash
cd /path/to/fabric-network
tar -xzf machine2-package.tar.gz
./setup-machine2.sh
```

**What it does:**
- ✓ Cleans up old containers
- ✓ Starts Org2 network
- ✓ Joins Org2 peers to channel
- ✓ Installs chaincode on Org2 peers
- ✓ Approves chaincode for Org2
- ✓ Commits chaincode to channel
- ✓ Network ready!

**Duration:** ~1-2 minutes

---

## That's It! 🎉

Your network is now fully deployed and operational.

## Test the Network

On either machine:

```bash
# Initialize the ledger
docker exec cli peer chaincode invoke \
    -o orderer.example.com:7050 --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    -C mychannel -n asset-transfer-basic \
    --peerAddresses peer0.org1.example.com:7051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
    --peerAddresses peer0.org2.example.com:9051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
    -c '{"function":"InitLedger","Args":[]}'

# Query data
docker exec cli peer chaincode query -C mychannel -n asset-transfer-basic -c '{"Args":["GetAllAssets"]}'
```

## Custom Options

### Custom Channel Name

```bash
# Machine 1
./setup-machine1.sh my-custom-channel

# Machine 2
./setup-machine2.sh my-custom-channel
```

### Custom Chaincode Name

```bash
# Machine 1
./setup-machine1.sh mychannel my-chaincode

# Machine 2
./setup-machine2.sh mychannel my-chaincode
```

## What Gets Created

### Machine 1
- Orderer (port 7050)
- CA0 (port 7054)
- 2x Org1 Peers (ports 7051, 8051)
- 2x CouchDB instances
- CLI container

### Machine 2
- CA1 (port 7054)
- 2x Org2 Peers (ports 9051, 10051)
- 2x CouchDB instances
- CLI container

## Check Status

```bash
# View running containers
docker ps

# View logs
docker logs -f peer0.org1.example.com  # Machine 1
docker logs -f peer0.org2.example.com  # Machine 2
docker logs -f orderer.example.com     # Machine 1

# Check channel joined
docker exec cli peer channel list

# Check chaincode installed
docker exec cli peer lifecycle chaincode queryinstalled

# Check chaincode committed
docker exec cli peer lifecycle chaincode querycommitted -C mychannel
```

## Troubleshooting

### Script fails on Machine 1
```bash
# Check prerequisites
docker --version
docker-compose --version
cryptogen version
configtxgen version

# Check logs
docker logs orderer.example.com
docker logs peer0.org1.example.com
```

### Machine 2 can't connect to Machine 1
```bash
# Test connectivity
ping 13.239.132.194
nc -zv 13.239.132.194 7050  # Orderer port
nc -zv 13.239.132.194 7051  # Peer port

# Check firewall rules
sudo ufw status
```

### Start Over
```bash
# Machine 1
docker-compose -f docker-compose-org1.yaml down -v
rm -rf organizations/ system-genesis-block/ channel-artifacts/*.block
./setup-machine1.sh

# Machine 2
docker-compose -f docker-compose-org2.yaml down -v
./setup-machine2.sh
```

## Next Steps

1. **Configure Backend**: Update `ph_water_backend/` connection profiles
2. **Start Frontend**: Launch `ph_water_frontend/`
3. **Test Integration**: Verify end-to-end flow

## Architecture

```
┌─────────────────────────────┐         ┌─────────────────────────────┐
│   Machine 1 (Org1 + Orderer)│         │   Machine 2 (Org2)          │
│   13.239.132.194            │◄───────►│   178.16.139.239            │
├─────────────────────────────┤         ├─────────────────────────────┤
│  - Orderer:7050             │         │  - Peer0.Org2:9051          │
│  - Peer0.Org1:7051          │         │  - Peer1.Org2:10051         │
│  - Peer1.Org1:8051          │         │  - CA1:7054                 │
│  - CA0:7054                 │         │  - CouchDB2, CouchDB3       │
│  - CouchDB0, CouchDB1       │         │                             │
└─────────────────────────────┘         └─────────────────────────────┘
```

## Files Generated

- `machine2-package.tar.gz` - Complete package for Machine 2
- `package-id.txt` - Chaincode package ID (for reference)
- `channel-artifacts/mychannel.block` - Channel genesis block

---

**Need help?** See `SETUP-GUIDE.md` for detailed documentation.
