# Hyperledger Fabric Multi-Machine Network Setup Guide

This guide will help you set up a Hyperledger Fabric network across two separate machines with your custom chaincode, backend, and frontend.

## Network Architecture

- **Machine 1 (Org1 + Orderer)**: Contains Orderer, CA0, Peer0.Org1, Peer1.Org1
- **Machine 2 (Org2)**: Contains CA1, Peer0.Org2, Peer1.Org2

## Prerequisites

Both machines need:
- Docker and Docker Compose
- Hyperledger Fabric binaries (cryptogen, configtxgen, peer, etc.)
- Git (for cloning/transferring files)
- Network connectivity between machines
- Fabric v2.4 images

### Installing Fabric Binaries

```bash
curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.4.0 1.5.2
export PATH=$PATH:$PWD/bin
```

## Project Structure

```
fabric-network/
├── chaincode/              # Your custom chaincode (TypeScript)
├── ph_water_backend/       # Your backend application
├── ph_water_frontend/      # Your frontend application
├── organizations/          # Crypto materials (generated)
├── system-genesis-block/   # Genesis block (generated)
├── channel-artifacts/      # Channel configuration (generated)
├── configtx/               # Configuration files
│   └── configtx.yaml
├── scripts/                # Setup and deployment scripts
│   ├── generate-crypto.sh
│   ├── generate-genesis.sh
│   ├── create-channel.sh
│   ├── join-channel.sh
│   └── deploy-chaincode.sh
├── crypto-config.yaml      # Crypto material configuration
├── docker-compose-org1.yaml
└── docker-compose-org2.yaml
```

## Setup Instructions

### Step 1: Configure IP Addresses

Before starting, you need to update the docker-compose files with actual IP addresses.

**On Machine 1**, edit `docker-compose-org1.yaml`:
Replace all instances of `MACHINE_2_IP` with Machine 2's actual IP address.

```bash
# Example using sed (replace 192.168.1.102 with your Machine 2 IP)
sed -i 's/MACHINE_2_IP/192.168.1.102/g' docker-compose-org1.yaml
```

**On Machine 2**, edit `docker-compose-org2.yaml`:
Replace all instances of `MACHINE_1_IP` with Machine 1's actual IP address.

```bash
# Example using sed (replace 192.168.1.101 with your Machine 1 IP)
sed -i 's/MACHINE_1_IP/192.168.1.101/g' docker-compose-org2.yaml
```

### Step 2: Generate Crypto Materials (Machine 1)

Run this on Machine 1 to generate all certificates and keys:

```bash
./scripts/generate-crypto.sh
```

This will create the `organizations` directory with all crypto materials.

### Step 3: Generate Genesis Block and Channel Configuration (Machine 1)

```bash
./scripts/generate-genesis.sh mychannel
```

Replace `mychannel` with your desired channel name if needed.

This will create:
- `system-genesis-block/genesis.block`
- `channel-artifacts/mychannel.tx`
- `channel-artifacts/Org1MSPanchors.tx`
- `channel-artifacts/Org2MSPanchors.tx`

### Step 4: Copy Files to Machine 2

Transfer the following directories from Machine 1 to Machine 2:

```bash
# On Machine 1, tar the required directories
tar -czf network-config.tar.gz organizations/ system-genesis-block/ channel-artifacts/ configtx/

# Transfer to Machine 2
scp network-config.tar.gz user@machine2:/path/to/fabric-network/

# On Machine 2, extract
cd /path/to/fabric-network/
tar -xzf network-config.tar.gz
```

Also copy your project files:
- `chaincode/`
- `scripts/`
- `docker-compose-org2.yaml`

### Step 5: Start the Network

**On Machine 1:**
```bash
docker-compose -f docker-compose-org1.yaml up -d
```

**On Machine 2:**
```bash
docker-compose -f docker-compose-org2.yaml up -d
```

Verify all containers are running:
```bash
docker ps
```

### Step 6: Create Channel (Machine 1)

```bash
./scripts/create-channel.sh mychannel
```

This will:
- Create the channel
- Join Org1 peers to the channel
- Update Org1 anchor peer

### Step 7: Join Org2 to Channel (Machine 2)

The channel block should already be in `channel-artifacts/` from Step 4. If not, copy it:

```bash
# On Machine 1
scp channel-artifacts/mychannel.block user@machine2:/path/to/fabric-network/channel-artifacts/
```

Then on Machine 2:
```bash
./scripts/join-channel.sh mychannel
```

### Step 8: Deploy Chaincode

#### On Machine 1 (Org1):

```bash
./scripts/deploy-chaincode.sh mychannel asset-transfer-basic /opt/gopath/src/github.com/chaincode 1.0 1
```

This will package, install, and approve the chaincode for Org1.

#### On Machine 2 (Org2):

Create a similar script or manually install and approve:

```bash
# Install on peer0.org2
docker exec cli peer lifecycle chaincode install asset-transfer-basic.tar.gz

# Install on peer1.org2
docker exec -e CORE_PEER_ADDRESS=peer1.org2.example.com:10051 \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/tls/ca.crt \
    cli peer lifecycle chaincode install asset-transfer-basic.tar.gz

# Get package ID
docker exec cli peer lifecycle chaincode queryinstalled

# Approve for Org2 (use the package ID from above)
docker exec cli peer lifecycle chaincode approveformyorg \
    -o orderer.example.com:7050 \
    --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    --channelID mychannel \
    --name asset-transfer-basic \
    --version 1.0 \
    --package-id <PACKAGE_ID> \
    --sequence 1
```

#### Commit Chaincode (Either Machine):

```bash
docker exec cli peer lifecycle chaincode commit \
    -o orderer.example.com:7050 \
    --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    --channelID mychannel \
    --name asset-transfer-basic \
    --version 1.0 \
    --sequence 1 \
    --peerAddresses peer0.org1.example.com:7051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
    --peerAddresses peer0.org2.example.com:9051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
```

### Step 9: Test Chaincode

```bash
# Initialize (if required)
docker exec cli peer chaincode invoke \
    -o orderer.example.com:7050 \
    --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    -C mychannel \
    -n asset-transfer-basic \
    --peerAddresses peer0.org1.example.com:7051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
    --peerAddresses peer0.org2.example.com:9051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
    -c '{"function":"InitLedger","Args":[]}'

# Query
docker exec cli peer chaincode query -C mychannel -n asset-transfer-basic -c '{"Args":["GetAllAssets"]}'
```

## Backend and Frontend Setup

### Backend (ph_water_backend)

Your backend should connect to the Fabric network using the connection profiles. Update your backend configuration with:

- Connection profile pointing to the appropriate peer(s)
- Admin credentials from `organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/`
- Channel name: `mychannel`
- Chaincode name: `asset-transfer-basic`

### Frontend (ph_water_frontend)

Configure your frontend to connect to the backend API endpoint.

## Troubleshooting

### Check Container Logs

```bash
docker logs <container_name>
docker logs -f orderer.example.com
docker logs -f peer0.org1.example.com
```

### Restart Network

```bash
# Stop all containers
docker-compose -f docker-compose-org1.yaml down
docker-compose -f docker-compose-org2.yaml down

# Clean up (if needed)
docker volume prune
docker network prune

# Restart
docker-compose -f docker-compose-org1.yaml up -d
docker-compose -f docker-compose-org2.yaml up -d
```

### Network Connectivity Issues

Ensure both machines can ping each other:
```bash
ping <other_machine_ip>
```

Check firewall rules allow traffic on required ports:
- 7050, 7053 (Orderer)
- 7051, 7054 (Org1 Peer and CA)
- 9051, 7054 (Org2 Peer and CA)

## Port Reference

### Machine 1 (Org1 + Orderer)
- 7050: Orderer
- 7053: Orderer Admin
- 7051: Peer0.Org1
- 8051: Peer1.Org1
- 7054: CA Org1
- 5984, 6984: CouchDB for Org1 peers

### Machine 2 (Org2)
- 9051: Peer0.Org2
- 10051: Peer1.Org2
- 7054: CA Org2
- 7984, 8984: CouchDB for Org2 peers

## Additional Resources

- [Hyperledger Fabric Documentation](https://hyperledger-fabric.readthedocs.io/)
- [Fabric Samples](https://github.com/hyperledger/fabric-samples)

## Backup Files

All AWS/GCP specific files have been moved to `backup_aws_gcp/` directory for reference.
