# Quick Start Guide

Fast reference for setting up your Fabric network across two machines.

## Prerequisites Checklist

- [ ] Docker & Docker Compose installed on both machines
- [ ] Fabric binaries installed (cryptogen, configtxgen, peer)
- [ ] Network connectivity between machines
- [ ] Know both machines' IP addresses

## Setup Commands (Machine 1)

```bash
# 1. Update IP addresses in docker-compose
sed -i 's/MACHINE_2_IP/YOUR_MACHINE_2_IP/g' docker-compose-org1.yaml

# 2. Generate crypto materials
./scripts/generate-crypto.sh

# 3. Generate genesis block and channel config
./scripts/generate-genesis.sh mychannel

# 4. Package files for Machine 2
tar -czf network-config.tar.gz \
    organizations/ \
    system-genesis-block/ \
    channel-artifacts/ \
    configtx/ \
    chaincode/ \
    scripts/ \
    docker-compose-org2.yaml

# 5. Transfer to Machine 2
scp network-config.tar.gz user@MACHINE_2_IP:/path/to/fabric-network/

# 6. Start Org1 network
docker-compose -f docker-compose-org1.yaml up -d

# 7. Create channel and join Org1 peers
./scripts/create-channel.sh mychannel

# 8. Deploy chaincode (Org1 side)
./scripts/deploy-chaincode.sh mychannel asset-transfer-basic /opt/gopath/src/github.com/chaincode 1.0 1
```

## Setup Commands (Machine 2)

```bash
# 1. Extract transferred files
cd /path/to/fabric-network/
tar -xzf network-config.tar.gz

# 2. Update IP addresses in docker-compose
sed -i 's/MACHINE_1_IP/YOUR_MACHINE_1_IP/g' docker-compose-org2.yaml

# 3. Start Org2 network
docker-compose -f docker-compose-org2.yaml up -d

# 4. Join Org2 peers to channel
./scripts/join-channel.sh mychannel

# 5. Install chaincode on Org2 peers
# Get the package file from Machine 1
scp user@MACHINE_1_IP:/path/to/fabric-network/asset-transfer-basic.tar.gz .

docker exec cli peer lifecycle chaincode install asset-transfer-basic.tar.gz
docker exec -e CORE_PEER_ADDRESS=peer1.org2.example.com:10051 \
    cli peer lifecycle chaincode install asset-transfer-basic.tar.gz

# 6. Get package ID
docker exec cli peer lifecycle chaincode queryinstalled

# 7. Approve for Org2 (replace PACKAGE_ID)
docker exec cli peer lifecycle chaincode approveformyorg \
    -o orderer.example.com:7050 --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    --channelID mychannel \
    --name asset-transfer-basic \
    --version 1.0 \
    --package-id PACKAGE_ID \
    --sequence 1

# 8. Commit chaincode (can be done from either machine)
docker exec cli peer lifecycle chaincode commit \
    -o orderer.example.com:7050 --tls \
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

## Test Chaincode

```bash
# Initialize ledger
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
docker exec cli peer chaincode query \
    -C mychannel -n asset-transfer-basic \
    -c '{"Args":["GetAllAssets"]}'
```

## Useful Commands

```bash
# Check all containers
docker ps -a

# Check logs
docker logs -f orderer.example.com
docker logs -f peer0.org1.example.com
docker logs -f peer0.org2.example.com

# Stop network
docker-compose -f docker-compose-org1.yaml down  # Machine 1
docker-compose -f docker-compose-org2.yaml down  # Machine 2

# Clean up everything (CAUTION: Deletes all data)
docker-compose down -v
docker volume prune -f
rm -rf organizations/ system-genesis-block/ channel-artifacts/*.block

# Check peer channel list
docker exec cli peer channel list

# Check chaincode installed
docker exec cli peer lifecycle chaincode queryinstalled

# Check committed chaincodes
docker exec cli peer lifecycle chaincode querycommitted -C mychannel
```

## Port Reference

### Machine 1
- 7050: Orderer
- 7051: Peer0.Org1
- 8051: Peer1.Org1
- 7054: CA0
- 5984, 6984: CouchDB

### Machine 2
- 9051: Peer0.Org2
- 10051: Peer1.Org2
- 7054: CA1
- 7984, 8984: CouchDB

## Troubleshooting

### Connection Issues
```bash
# Test connectivity
ping MACHINE_IP

# Check if ports are open
nc -zv MACHINE_IP 7050
nc -zv MACHINE_IP 7051
```

### Certificate Issues
Regenerate crypto materials:
```bash
./scripts/generate-crypto.sh
./scripts/generate-genesis.sh mychannel
```

### Container Issues
```bash
# Restart a specific container
docker restart peer0.org1.example.com

# Remove and recreate
docker-compose -f docker-compose-org1.yaml down
docker-compose -f docker-compose-org1.yaml up -d
```

## Next Steps

1. Configure backend (`ph_water_backend/`) to connect to Fabric
2. Update frontend (`ph_water_frontend/`) API endpoints
3. Deploy your application

For detailed information, see `SETUP-GUIDE.md`
