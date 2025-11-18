# Troubleshooting Guide - Multi-Cloud Fabric Network

## Issues from problem.md - FIXED

### Issue 1: Genesis Block Path Error ✅ FIXED
**Error:**
```
open /home/ubuntu/fabric_multi_aws/system-genesis-block/genesis.block/genesis.block: permission denied
```

**Root Cause:**
- Docker cp was trying to copy to a nested path `genesis.block/genesis.block`
- This happened when genesis.block existed as a directory instead of a file

**Fix Applied:**
Updated `setup-aws.sh`:
- Added `rm -rf ./system-genesis-block/genesis.block` before generation
- Changed `docker cp ... ./system-genesis-block/genesis.block` to `docker cp ... ./system-genesis-block/`
- This copies the file INTO the directory, not AS a file path

---

### Issue 2: Orderer Container Not Running ✅ FIXED
**Error:**
```
✗ Orderer container not found
```

**Root Cause:**
- Orderer couldn't start because genesis block was missing or at wrong path
- TLS configuration issues (already fixed in previous update)

**Fix Applied:**
1. Fixed genesis block generation path
2. Ensured TLS certificates are properly mounted
3. Verified volume mount in docker-compose: `./system-genesis-block/genesis.block:/var/hyperledger/orderer/orderer.genesis.block`

---

### Issue 3: Peer Connection Error (0.0.0.0:7051) ✅ FIXED
**Error:**
```
dial tcp 0.0.0.0:7051: connect: connection refused
```

**Root Cause:**
- diagnose.sh was running `peer channel list` without setting proper environment variables
- Peer defaulted to connecting to 0.0.0.0 instead of peer hostname

**Fix Applied:**
Updated `diagnose.sh` to set proper environment variables before checking channels:
```bash
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
export CORE_PEER_MSPCONFIGPATH=...
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE=...
```

---

### Issue 4: channel.tx Missing
**Error:**
```
✗ channel.tx missing
```

**Root Cause:**
- Channel artifacts not generated in setup-aws.sh

**Status:**
- The setup-aws.sh script DOES generate channel.tx in Step 9
- If missing, it means script didn't complete successfully
- Check setup-aws.sh output for errors

---

## How to Fix Your Current Deployment

### Step 1: Clean Everything
```bash
# On AWS machine
./cleanup-aws.sh
```

This will:
- Stop all containers
- Remove volumes
- Clean up genesis block and channel artifacts
- Remove any corrupted files

### Step 2: Start Fresh
```bash
# Run setup
./setup-aws.sh
```

Watch for:
- ✓ Genesis block generated successfully
- ✓ Channel artifacts generated
- ✓ All containers running (orderer, peer, cli)

### Step 3: Verify Orderer is Running
```bash
docker ps | grep orderer
```

Should show:
```
orderer.example.com   Up X seconds   0.0.0.0:7050->7050/tcp...
```

If orderer is NOT running, check logs:
```bash
docker logs orderer.example.com
```

### Step 4: Check Diagnostics
```bash
./diagnose.sh
```

Should show:
- ✓ Orderer is running
- ✓ Peer is running
- ✓ CLI container is running
- ✓ Genesis block found
- ✓ Channel artifacts found

### Step 5: Create Channel
```bash
./create-channel-aws.sh
```

Should succeed with:
- ✓ Channel created successfully
- ✓ Org1 peer joined successfully
- ✓ Anchor peer updated successfully

### Step 6: Final Verification
```bash
# Check orderer logs
docker logs orderer.example.com | tail -20

# Check peer logs
docker logs peer0.org1.example.com | tail -20

# List channels
docker exec cli bash -c "
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
peer channel list
"
```

Should show: `mychannel`

---

## Common Issues and Solutions

### Orderer Keeps Exiting

**Symptoms:**
```bash
docker ps -a | grep orderer
# Shows: Exited (2)
```

**Solutions:**

1. **Check genesis block exists:**
```bash
ls -lh ./system-genesis-block/genesis.block
# Should show a file around 10-20KB
```

2. **Check TLS certificates:**
```bash
ls -la ./organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/
# Should show: ca.crt, server.crt, server.key
```

3. **Check orderer logs:**
```bash
docker logs orderer.example.com 2>&1 | grep -i error
```

4. **Restart orderer:**
```bash
docker-compose -f docker-compose-aws.yml restart orderer.example.com
docker logs -f orderer.example.com
```

---

### Permission Denied Errors

**Symptoms:**
```
permission denied
```

**Solutions:**

1. **Fix file ownership:**
```bash
sudo chown -R $USER:$USER ./system-genesis-block
sudo chown -R $USER:$USER ./channel-artifacts
```

2. **Remove and regenerate:**
```bash
rm -rf ./system-genesis-block/genesis.block
./setup-aws.sh
```

---

### Channel Creation Fails

**Symptoms:**
```
Error: failed to create deliver client for orderer
```

**Solutions:**

1. **Verify orderer is running:**
```bash
docker ps | grep orderer
# Must show "Up" status
```

2. **Check orderer logs:**
```bash
docker logs orderer.example.com | grep -i "Beginning to serve"
# Should see: "Beginning to serve requests"
```

3. **Test orderer connectivity from CLI:**
```bash
docker exec cli bash -c "
nc -zv orderer.example.com 7050
"
# Should connect successfully
```

4. **Verify TLS certificates are accessible:**
```bash
docker exec cli bash -c "
ls -la /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/
"
```

---

### Peer Cannot Connect to Orderer

**Symptoms:**
```
connection refused
context deadline exceeded
```

**Solutions:**

1. **Check if both are in same network:**
```bash
docker network inspect fabric-network_fabric-net
# Should show both orderer and peer
```

2. **Test connectivity:**
```bash
docker exec peer0.org1.example.com ping orderer.example.com -c 2
```

3. **Check peer logs:**
```bash
docker logs peer0.org1.example.com | grep -i orderer
```

---

### Genesis Block Not Found

**Symptoms:**
```
✗ Genesis block not found
```

**Solutions:**

1. **Check if directory exists:**
```bash
ls -la ./system-genesis-block/
```

2. **Regenerate:**
```bash
rm -rf ./system-genesis-block/genesis.block
docker exec cli bash -c "configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock ./genesis.block -configPath /etc/hyperledger/fabric"
docker cp cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/genesis.block ./system-genesis-block/
```

3. **Verify it was created:**
```bash
ls -lh ./system-genesis-block/genesis.block
file ./system-genesis-block/genesis.block
# Should show: data
```

---

## Emergency Recovery

If nothing works, do a complete reset:

```bash
# 1. Stop everything
docker-compose -f docker-compose-aws.yml down -v

# 2. Remove ALL Fabric containers
docker rm -f $(docker ps -a | grep hyperledger | awk '{print $1}')

# 3. Remove ALL Fabric volumes
docker volume prune -f

# 4. Clean generated files
rm -rf ./system-genesis-block/genesis.block
rm -rf ./channel-artifacts/*.block
rm -rf ./channel-artifacts/*.tx

# 5. Start fresh
./setup-aws.sh

# 6. Verify
./diagnose.sh

# 7. Create channel
./create-channel-aws.sh
```

---

## Useful Debugging Commands

### Check Container Status
```bash
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### View All Logs
```bash
# Orderer
docker logs orderer.example.com 2>&1 | less

# Peer
docker logs peer0.org1.example.com 2>&1 | less

# Follow logs in real-time
docker logs -f orderer.example.com
```

### Inspect Container
```bash
docker inspect orderer.example.com | jq '.[0].State'
docker inspect orderer.example.com | jq '.[0].Mounts'
```

### Network Inspection
```bash
docker network ls
docker network inspect fabric-network_fabric-net
```

### Volume Inspection
```bash
docker volume ls
docker volume inspect fabric-network_ordererdata
```

### Execute Commands in Container
```bash
# Check if configtxgen works
docker exec cli configtxgen --version

# Check file permissions
docker exec cli ls -la ./system-genesis-block/

# Test orderer connection
docker exec cli bash -c "nc -zv orderer.example.com 7050"
```

---

## Scripts Reference

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `cleanup-aws.sh` | Remove all containers and generated files | When starting completely fresh |
| `setup-aws.sh` | Initial setup, generate artifacts, start containers | First time or after cleanup |
| `create-channel-aws.sh` | Create channel and join Org1 peer | After setup-aws.sh succeeds |
| `diagnose.sh` | Check network health | Anytime to verify status |
| `check-orderer.sh` | View orderer status and logs | When orderer isn't running |
| `copy-to-gcp.sh` | Copy artifacts to GCP | After channel creation on AWS |

---

## Success Checklist

Before proceeding to GCP, verify ALL of these:

- [ ] `docker ps` shows orderer, peer, and cli running
- [ ] `docker logs orderer.example.com` shows "Beginning to serve requests"
- [ ] `./diagnose.sh` shows all green checkmarks
- [ ] `ls -lh ./system-genesis-block/genesis.block` shows file exists
- [ ] `ls -lh ./channel-artifacts/mychannel.block` shows file exists
- [ ] `docker exec cli peer channel list` shows `mychannel`
- [ ] No errors in `docker logs peer0.org1.example.com`
- [ ] Orderer port 7050 is accessible: `nc -zv localhost 7050`

---

## Still Having Issues?

If you've tried everything and it still doesn't work:

1. **Capture full logs:**
```bash
docker logs orderer.example.com > orderer.log 2>&1
docker logs peer0.org1.example.com > peer.log 2>&1
docker logs cli > cli.log 2>&1
./diagnose.sh > diagnostic.log 2>&1
```

2. **Check versions:**
```bash
docker --version
docker-compose --version
docker exec cli peer version
docker exec orderer.example.com orderer version
```

3. **Verify crypto materials:**
```bash
find ./organizations -name "*.pem" | wc -l
# Should show many certificate files

find ./organizations -name "ca.crt" | wc -l
# Should show several CA certificates
```

Good luck! 🚀
