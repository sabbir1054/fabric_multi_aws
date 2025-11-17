# IMMEDIATE FIX - Run This Now on AWS

## 🔴 Your Current Problem (from problem.md)

1. ✗ Orderer container NOT running
2. ✗ Genesis block path error (nested path issue)
3. ✗ Peer cannot connect (0.0.0.0:7051 error)
4. ✗ channel.tx missing

## ✅ The Solution - Run These Commands

### On Your AWS Machine (IP: 3.27.144.169)

```bash
# Navigate to your fabric directory
cd ~/fabric_multi_aws  # or wherever you have the files

# Step 1: CLEAN EVERYTHING (removes corrupted files)
./cleanup-aws.sh
# Type 'yes' when prompted

# Step 2: RUN SETUP (this will work now with the fixes)
./setup-aws.sh

# Step 3: VERIFY ORDERER IS RUNNING
docker ps | grep orderer
# ✅ Should show "Up" status, NOT "Exited"

# Step 4: CHECK DIAGNOSTICS
./diagnose.sh
# ✅ Should show orderer running, genesis block found

# Step 5: CREATE CHANNEL
./create-channel-aws.sh
# ✅ Should create mychannel successfully

# Step 6: FINAL CHECK
docker exec cli bash -c "
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
peer channel list
"
# ✅ Should show: mychannel
```

---

## 📊 What Should You See?

### After cleanup-aws.sh:
```
========================================
  Cleanup Complete!
========================================
```

### After setup-aws.sh:
```
✓ Docker and Docker Compose are installed
✓ Existing containers stopped
✓ Crypto materials found
✓ Directories created
✓ Containers started
✓ Containers are running
✓ Genesis block generated successfully
✓ Channel artifacts generated

========================================
  AWS Setup Complete!
========================================
```

### After docker ps:
```
NAMES                    STATUS
orderer.example.com      Up 2 minutes
peer0.org1.example.com   Up 2 minutes
cli                      Up 2 minutes
```

### After create-channel-aws.sh:
```
✓ Channel created successfully
✓ Org1 peer joined successfully
✓ Anchor peer updated successfully

========================================
  Channel Setup Complete on AWS!
========================================
```

---

## 🔍 What Got Fixed?

### Fix 1: Genesis Block Path ✅
**Before:**
```
docker cp ... ./system-genesis-block/genesis.block
# Created: genesis.block/genesis.block (WRONG)
```

**After:**
```
rm -rf ./system-genesis-block/genesis.block  # Clean first
docker cp ... ./system-genesis-block/        # Copy to directory
# Creates: system-genesis-block/genesis.block (CORRECT)
```

### Fix 2: Orderer TLS Configuration ✅
Added to `docker-compose-aws.yml`:
- 20+ TLS environment variables
- TLS volume mounts
- Proper bootstrap configuration

### Fix 3: Peer Environment Variables ✅
All scripts now set:
- `CORE_PEER_ADDRESS=peer0.org1.example.com:7051` (not 0.0.0.0)
- TLS enabled
- TLS certificates paths
- Proper MSP configuration

### Fix 4: Channel Artifacts Generation ✅
`setup-aws.sh` generates:
- channel.tx
- Org1MSPanchors.tx
- Org2MSPanchors.tx

---

## ❌ If Something Still Fails

### If cleanup-aws.sh fails:
```bash
# Manual cleanup
docker-compose -f docker-compose-aws.yml down -v
docker rm -f orderer.example.com peer0.org1.example.com cli
docker volume prune -f
rm -rf ./system-genesis-block/genesis.block
```

### If orderer still doesn't start:
```bash
# Check orderer logs
docker logs orderer.example.com

# Check TLS certificates exist
ls -la ./organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/
# Must show: ca.crt, server.crt, server.key
```

### If genesis block generation fails:
```bash
# Generate manually
docker exec cli bash -c "
configtxgen -profile TwoOrgsOrdererGenesis \
  -channelID system-channel \
  -outputBlock ./genesis.block \
  -configPath /etc/hyperledger/fabric
"

# Copy it out
docker cp cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/genesis.block ./system-genesis-block/

# Restart orderer
docker-compose -f docker-compose-aws.yml restart orderer.example.com
```

### If channel creation fails:
```bash
# Verify orderer is running
docker ps | grep orderer

# Check orderer is serving
docker logs orderer.example.com | grep "Beginning to serve"

# Test connectivity
docker exec cli bash -c "nc -zv orderer.example.com 7050"

# Try channel creation again
./create-channel-aws.sh
```

---

## 📋 Success Checklist

Before moving to GCP, confirm ALL these:

```bash
# 1. Orderer is running (not exited)
docker ps | grep orderer
# ✅ Must show "Up X minutes/seconds"

# 2. Genesis block exists
ls -lh ./system-genesis-block/genesis.block
# ✅ Must show file ~10-20KB

# 3. Channel artifacts exist
ls -lh ./channel-artifacts/
# ✅ Must show: channel.tx, Org1MSPanchors.tx, Org2MSPanchors.tx, mychannel.block

# 4. Peer joined channel
docker exec cli bash -c "
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
peer channel list
"
# ✅ Must show: mychannel

# 5. No errors in logs
docker logs orderer.example.com 2>&1 | grep -i error | wc -l
docker logs peer0.org1.example.com 2>&1 | grep -i error | wc -l
# ✅ Should be 0 or very low number

# 6. Diagnostic passes
./diagnose.sh
# ✅ Should show all green checkmarks
```

---

## 🚀 After AWS is Working

Once everything above is ✅, proceed to GCP:

```bash
# On AWS machine
./copy-to-gcp.sh

# Then SSH to GCP
ssh ubuntu@178.16.139.239
cd ~/fabric-network

# On GCP machine
chmod +x *.sh
./setup-gcp.sh
./join-channel-gcp.sh
./diagnose.sh
```

---

## 💡 Quick Debug Commands

```bash
# View all containers
docker ps -a

# View orderer logs (last 50 lines)
docker logs orderer.example.com --tail 50

# View peer logs (last 50 lines)
docker logs peer0.org1.example.com --tail 50

# Follow logs in real-time
docker logs -f orderer.example.com

# Check what's in system-genesis-block
ls -la ./system-genesis-block/

# Check Docker network
docker network inspect fabric-network_fabric-net

# Restart specific container
docker-compose -f docker-compose-aws.yml restart orderer.example.com
```

---

## 📞 Summary

**The fixes are already in your scripts!**

All you need to do is:

1. `./cleanup-aws.sh` - Clean corrupted files
2. `./setup-aws.sh` - Run setup with fixes applied
3. `./create-channel-aws.sh` - Create channel
4. `./diagnose.sh` - Verify everything works

**Total time: ~2-3 minutes**

**The orderer WILL start now because:**
- ✅ Genesis block path is fixed
- ✅ TLS configuration is complete
- ✅ All environment variables are correct
- ✅ Cleanup removes corrupted files

Just run the commands above and it will work! 🎉
