# Quick Fix for "cannot load client cert" Error

## The Problem

You're getting this error:
```
cannot load client cert for consenter orderer.example.com:7050:
open .../organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt:
no such file or directory
```

**Cause:** The genesis block is being created BEFORE the crypto materials exist.

---

## Quick Solution

Run these commands in order:

```bash
# 1. Generate crypto materials FIRST
cryptogen generate --config=./crypto-config.yaml

# 2. Now create the genesis block
export FABRIC_CFG_PATH=${PWD}/configtx
mkdir -p system-genesis-block
configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock ./system-genesis-block/genesis.block

# 3. Verify it worked
ls -la system-genesis-block/genesis.block
```

---

## Better Solution: Use the Auto Script

Instead of running commands manually, use the automated script:

```bash
# Make sure you're in the fabric-network directory
cd /path/to/fabric-network

# Run the automated setup
./setup-machine1-auto.sh
```

This script handles everything in the correct order!

---

## If You Still Get Errors

### Check if crypto materials exist:
```bash
ls -la organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/
```

You should see:
- server.crt
- server.key
- ca.crt

### If the directory doesn't exist:
```bash
# Remove any partial crypto materials
rm -rf organizations/

# Generate fresh crypto materials
cryptogen generate --config=./crypto-config.yaml

# Verify
ls -la organizations/
```

---

## Understanding the Order

**Correct Order:**
1. ✅ Generate crypto materials (cryptogen)
2. ✅ Generate genesis block (configtxgen) ← This needs the certs!
3. ✅ Generate channel tx (configtxgen)
4. ✅ Start network (docker-compose)

**Your Error Order:**
1. ❌ Generate genesis block (configtxgen) ← No certs exist!
2. ERROR!

---

## Full Reset and Deploy

If you want to start completely fresh:

```bash
# Clean everything
docker-compose -f docker-compose-org1.yaml down -v 2>/dev/null || true
rm -rf organizations/ system-genesis-block/ channel-artifacts/*.block

# Run automated setup (handles everything correctly)
./setup-machine1-auto.sh
```

This will work correctly!
