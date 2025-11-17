# Multi-Cloud Hyperledger Fabric Deployment Guide

## Overview

This guide will help you deploy a Hyperledger Fabric network across AWS and GCP.

**Architecture:**
- **AWS**: Orderer + Peer0.Org1 + CLI
- **GCP**: Peer0.Org2 + CLI

## Prerequisites

### Both AWS and GCP VMs:
- Ubuntu 20.04/22.04
- Docker & Docker Compose installed
- Open ports: 7050, 7051, 7053
- SSH access configured

### Required IPs (Update these in the files):
- **AWS Public IP**: `3.27.144.169` (Already configured)
- **GCP Public IP**: `178.16.139.239` (Already configured)

---

## File Distribution

### Files to Keep on AWS:
```
fabric-network/
├── docker-compose-aws.yml          # AWS Docker Compose
├── setup-aws.sh                    # AWS setup script
├── create-channel-aws.sh           # Channel creation script
├── copy-to-gcp.sh                  # Copy artifacts to GCP
├── organizations/                  # Crypto materials (generated)
├── channel-artifacts/              # Channel artifacts (generated)
├── configtx/                       # Configuration files
├── chaincode/                      # Smart contracts
└── system-genesis-block/           # Genesis block (generated)
```

### Files to Copy to GCP (automated by copy-to-gcp.sh):
```
fabric-network/
├── docker-compose-gcp.yml          # GCP Docker Compose
├── setup-gcp.sh                    # GCP setup script
├── join-channel-gcp.sh             # Join channel script
├── organizations/                  # Crypto materials (from AWS)
├── channel-artifacts/              # Channel artifacts (from AWS)
├── configtx/                       # Configuration files (from AWS)
└── chaincode/                      # Smart contracts (from AWS)
```

---

## Deployment Steps

### Phase 1: Setup AWS (Primary Node)

#### 1. Upload files to AWS
```bash
# On your local machine
scp -r ./fabric-network ubuntu@3.27.144.169:~/
```

#### 2. SSH to AWS and make scripts executable
```bash
ssh ubuntu@3.27.144.169
cd ~/fabric-network
chmod +x *.sh
```

#### 3. Run AWS setup script
```bash
./setup-aws.sh
```

This script will:
- ✓ Check Docker installation
- ✓ Stop existing containers
- ✓ Verify crypto materials
- ✓ Start orderer, peer0.org1, and CLI containers
- ✓ Generate genesis block
- ✓ Generate channel artifacts

**Expected output:**
```
========================================
  AWS Setup Complete!
========================================
```

#### 4. Create channel and join Org1 peer
```bash
./create-channel-aws.sh
```

This script will:
- ✓ Create mychannel
- ✓ Join Org1 peer to mychannel
- ✓ Update Org1 anchor peer

**Expected output:**
```
========================================
  Channel Setup Complete on AWS!
========================================
```

#### 5. Verify AWS setup
```bash
# Check containers
docker ps

# Verify peer joined channel
docker exec cli peer channel list

# Check channel info
docker exec cli peer channel getinfo -c mychannel
```

---

### Phase 2: Setup GCP (Secondary Node)

#### 6. Copy artifacts from AWS to GCP
```bash
# On AWS machine, edit copy-to-gcp.sh first to set correct GCP IP/credentials
nano copy-to-gcp.sh

# Then run the copy script
./copy-to-gcp.sh
```

This will copy:
- organizations/ (crypto materials)
- channel-artifacts/ (including mychannel.block)
- configtx/
- chaincode/
- docker-compose-gcp.yml
- Setup scripts

#### 7. SSH to GCP
```bash
ssh ubuntu@178.16.139.239
cd ~/fabric-network
chmod +x *.sh
```

#### 8. Run GCP setup script
```bash
./setup-gcp.sh
```

This script will:
- ✓ Check Docker installation
- ✓ Verify crypto materials exist
- ✓ Start peer0.org2 and CLI containers

**Expected output:**
```
========================================
  GCP Setup Complete!
========================================
```

#### 9. Join Org2 peer to channel
```bash
./join-channel-gcp.sh
```

This script will:
- ✓ Join Org2 peer to mychannel
- ✓ Update Org2 anchor peer

**Expected output:**
```
========================================
  Channel Join Complete on GCP!
========================================
```

#### 10. Verify GCP setup
```bash
# Check containers
docker ps

# Verify peer joined channel
docker exec cli_org2 peer channel list

# Check channel info
docker exec cli_org2 peer channel getinfo -c mychannel

# Check logs
docker logs peer0.org2.example.com | grep -i gossip
```

---

## Verification & Testing

### Test Network Connectivity

#### From AWS:
```bash
# Check if can reach GCP peer
ping 178.16.139.239
telnet 178.16.139.239 7051
```

#### From GCP:
```bash
# Check if can reach AWS orderer
ping 3.27.144.169
telnet 3.27.144.169 7050
telnet 3.27.144.169 7051
```

### Verify Both Peers See Each Other
```bash
# On AWS
docker exec cli peer channel getinfo -c mychannel

# On GCP
docker exec cli_org2 peer channel getinfo -c mychannel

# Both should show the same block height
```

---

## Troubleshooting

### Common Issues:

#### 1. "context deadline exceeded" error
**Cause**: Container cannot reach orderer/peer
**Solution**:
- Check firewall rules (ports 7050, 7051, 7053 open)
- Verify extra_hosts in docker-compose files have correct IPs
- Check if orderer is running: `docker ps`

#### 2. "error creating deliver client"
**Cause**: Orderer not accessible or wrong hostname mapping
**Solution**:
- Restart containers: `docker-compose -f docker-compose-aws.yml restart`
- Check orderer logs: `docker logs orderer.example.com`
- Verify orderer is in same network: `docker network inspect fabric-network_fabric-net`

#### 3. Peer cannot join channel
**Cause**: mychannel.block not found or outdated
**Solution**:
- Re-copy channel artifacts from AWS
- Ensure mychannel.block exists in channel-artifacts/
- Check peer logs: `docker logs peer0.org2.example.com`

#### 4. TLS handshake errors
**Cause**: TLS certificates missing or incorrect
**Solution**:
- Verify organizations/ directory has all TLS certs
- Check configtx.yaml has correct TLS cert paths
- Regenerate crypto materials if needed

### View Logs
```bash
# AWS
docker logs -f orderer.example.com
docker logs -f peer0.org1.example.com
docker logs -f cli

# GCP
docker logs -f peer0.org2.example.com
docker logs -f cli_org2
```

---

## Cleanup

### To stop and remove containers:

**On AWS:**
```bash
docker-compose -f docker-compose-aws.yml down
docker volume rm fabric-network_ordererdata  # Remove persistent data
```

**On GCP:**
```bash
docker-compose -f docker-compose-gcp.yml down
docker volume rm fabric-network_peer0org2data  # Remove persistent data
```

---

## Next Steps

After successful deployment:

1. **Install Chaincode** - Deploy smart contracts to both peers
2. **Run Caliper Benchmarks** - Performance testing
3. **Setup Monitoring** - Add Prometheus/Grafana for metrics
4. **Configure Explorer** - Blockchain visualization

---

## Quick Reference

### AWS Commands
```bash
./setup-aws.sh              # Initial setup
./create-channel-aws.sh     # Create channel
./copy-to-gcp.sh            # Copy to GCP
docker exec -it cli bash    # Enter CLI
```

### GCP Commands
```bash
./setup-gcp.sh              # Initial setup
./join-channel-gcp.sh       # Join channel
docker exec -it cli_org2 bash  # Enter CLI
```

### Environment Variables (Inside CLI)

**Org1 (AWS):**
```bash
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
```

**Org2 (GCP):**
```bash
export CORE_PEER_LOCALMSPID=Org2MSP
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=peer0.org2.example.com:7051
```

---

## Support

For issues or questions:
1. Check logs first: `docker logs <container_name>`
2. Verify network connectivity between AWS and GCP
3. Ensure all IPs are correctly configured in docker-compose files
4. Review Hyperledger Fabric documentation

---

**Good luck with your deployment!** 🚀
