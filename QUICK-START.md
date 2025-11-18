# Quick Start Guide - Multi-Cloud Fabric Network

## TL;DR - Fast Deployment Steps

### AWS Side (13.239.132.194)

```bash
# 1. Upload and setup
cd ~/fabric-network
chmod +x *.sh

# 2. Run setup
./setup-aws.sh

# 3. Create channel
./create-channel-aws.sh

# 4. Copy to GCP
./copy-to-gcp.sh
```

### GCP Side (178.16.139.239)

```bash
# 1. Make scripts executable
cd ~/fabric-network
chmod +x *.sh

# 2. Run setup
./setup-gcp.sh

# 3. Join channel
./join-channel-gcp.sh
```

---

## What Gets Created

### AWS Components:
- ✅ Orderer (port 7050)
- ✅ Peer0.Org1 (port 7051)
- ✅ CLI container
- ✅ Genesis block
- ✅ Channel artifacts
- ✅ mychannel created

### GCP Components:
- ✅ Peer0.Org2 (port 7051)
- ✅ CLI container (cli_org2)
- ✅ Joined to mychannel

---

## Verify Everything Works

### Check on AWS:
```bash
docker ps                                    # See running containers
docker exec cli peer channel list            # Should show: mychannel
docker exec cli peer channel getinfo -c mychannel
```

### Check on GCP:
```bash
docker ps                                    # See running containers
docker exec cli_org2 peer channel list       # Should show: mychannel
docker exec cli_org2 peer channel getinfo -c mychannel
```

### Both should show same block height!

---

## If Something Breaks

### AWS:
```bash
# Restart everything
docker-compose -f docker-compose-aws.yml down
docker-compose -f docker-compose-aws.yml up -d

# Check logs
docker logs orderer.example.com
docker logs peer0.org1.example.com
```

### GCP:
```bash
# Restart everything
docker-compose -f docker-compose-gcp.yml down
docker-compose -f docker-compose-gcp.yml up -d

# Check logs
docker logs peer0.org2.example.com
```

---

## Scripts Breakdown

| Script | Location | Purpose |
|--------|----------|---------|
| `setup-aws.sh` | AWS | Initial AWS setup + generate artifacts |
| `create-channel-aws.sh` | AWS | Create channel + join Org1 |
| `copy-to-gcp.sh` | AWS | SCP files to GCP |
| `setup-gcp.sh` | GCP | Start GCP containers |
| `join-channel-gcp.sh` | GCP | Join Org2 to channel |

---

## File Structure After Setup

```
AWS (13.239.132.194):
fabric-network/
├── docker-compose-aws.yml
├── setup-aws.sh
├── create-channel-aws.sh
├── copy-to-gcp.sh
├── organizations/          (crypto materials)
├── channel-artifacts/      (mychannel.block, *.tx files)
├── configtx/
├── chaincode/
└── system-genesis-block/   (genesis.block)

GCP (178.16.139.239):
fabric-network/
├── docker-compose-gcp.yml
├── setup-gcp.sh
├── join-channel-gcp.sh
├── organizations/          (copied from AWS)
├── channel-artifacts/      (copied from AWS)
├── configtx/               (copied from AWS)
└── chaincode/              (copied from AWS)
```

---

## Network Diagram

```
┌─────────────────────────────────────┐
│           AWS (13.239.132.194)        │
│  ┌────────────────────────────────┐ │
│  │  Orderer.example.com:7050      │ │
│  └────────────────────────────────┘ │
│  ┌────────────────────────────────┐ │
│  │  Peer0.Org1:7051               │ │
│  └────────────────────────────────┘ │
│  ┌────────────────────────────────┐ │
│  │  CLI                           │ │
│  └────────────────────────────────┘ │
└──────────────┬──────────────────────┘
               │
               │ Internet
               │
┌──────────────┴──────────────────────┐
│         GCP (178.16.139.239)        │
│  ┌────────────────────────────────┐ │
│  │  Peer0.Org2:7051               │ │
│  └────────────────────────────────┘ │
│  ┌────────────────────────────────┐ │
│  │  CLI_Org2                      │ │
│  └────────────────────────────────┘ │
└─────────────────────────────────────┘
```

---

## Next Steps After Deployment

1. ✅ Deploy chaincode to both peers
2. ✅ Run Caliper performance tests
3. ✅ Setup Hyperledger Explorer
4. ✅ Configure monitoring (Prometheus/Grafana)

For detailed instructions, see **DEPLOYMENT-GUIDE.md**
