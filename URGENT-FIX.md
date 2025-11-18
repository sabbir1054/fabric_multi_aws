# 🚨 URGENT FIX - Run This RIGHT NOW on AWS

## The Problem (Deep Analysis from problem.md)

Your orderer logs show (line 114):
```
panic: unable to bootstrap orderer.
Error reading genesis block file:
read /var/hyperledger/orderer/orderer.genesis.block: is a directory
```

**Translation:** The orderer tries to read a FILE but finds a DIRECTORY instead → CRASH!

## Why This Happened

When you ran `docker cp` to copy genesis.block, it created it as a **directory** instead of a **file**.

Check on your AWS machine:
```bash
ls -ld ~/fabric_multi_aws/system-genesis-block/genesis.block
```

If you see:
```
drwxr-xr-x ... genesis.block/     ← BAD! It's a directory!
```

That's the problem!

## 🔧 THE FIX - Run These Commands NOW

### On AWS Machine (~/fabric_multi_aws or wherever your files are):

```bash
# Step 1: Run the fix script
./fix-genesis-block.sh
```

**OR if that doesn't exist, run these commands manually:**

```bash
# Stop the broken orderer
docker stop orderer.example.com
docker rm orderer.example.com

# Remove the DIRECTORY that's causing the problem
rm -rf ./system-genesis-block/*

# Make sure CLI is running
docker-compose -f docker-compose-aws.yml up -d cli

# Generate genesis block FRESH
docker exec cli bash -c "
cd /opt/gopath/src/github.com/hyperledger/fabric/peer
configtxgen -profile TwoOrgsOrdererGenesis \
  -channelID system-channel \
  -outputBlock genesis.block \
  -configPath /etc/hyperledger/fabric
"

# Copy it as a FILE (not to a directory path)
docker cp cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/genesis.block /tmp/genesis.block.tmp
mv /tmp/genesis.block.tmp ./system-genesis-block/genesis.block

# Verify it's a FILE (not a directory!)
if [ -f ./system-genesis-block/genesis.block ]; then
    echo "✓ SUCCESS! Genesis block is a file!"
    ls -lh ./system-genesis-block/genesis.block
    file ./system-genesis-block/genesis.block
else
    echo "✗ FAILED! Still not a file!"
    ls -la ./system-genesis-block/
    exit 1
fi

# Start orderer with the correct genesis block
docker-compose -f docker-compose-aws.yml up -d orderer.example.com

# Wait for orderer to start
sleep 5

# Check if orderer is running
docker ps | grep orderer
```

## ✅ Verification

### 1. Check orderer is RUNNING (not exited):
```bash
docker ps | grep orderer
```

**Should see:**
```
orderer.example.com   Up 30 seconds   0.0.0.0:7050->7050/tcp
```

**Should NOT see:**
```
(nothing) ← means orderer crashed
```

### 2. Check orderer logs for success:
```bash
docker logs orderer.example.com 2>&1 | tail -30
```

**Should see:**
```
Starting orderer with TLS enabled
Beginning to serve requests
```

**Should NOT see:**
```
panic: unable to bootstrap
is a directory
```

### 3. Verify genesis.block is a FILE:
```bash
ls -lh ./system-genesis-block/genesis.block
file ./system-genesis-block/genesis.block
```

**Should see:**
```
-rw-r--r-- 1 ubuntu ubuntu 10K ... genesis.block
./system-genesis-block/genesis.block: data
```

**Should NOT see:**
```
drwxr-xr-x ... genesis.block/   ← This means it's still a directory!
```

## 🎯 After the Fix Works

Once orderer is running:

```bash
# Run setup to generate channel artifacts
./setup-aws.sh

# Create the channel
./create-channel-aws.sh

# Verify everything
./diagnose.sh
```

## 🔍 Understanding the Fix

### Before (BROKEN):
```
Host: ./system-genesis-block/genesis.block/          ← DIRECTORY
                                  └── genesis.block  ← File inside
Container: /var/hyperledger/orderer/orderer.genesis.block → DIRECTORY
Orderer: Tries to read file → Gets directory → PANIC!
```

### After (FIXED):
```
Host: ./system-genesis-block/genesis.block           ← FILE
Container: /var/hyperledger/orderer/orderer.genesis.block → FILE
Orderer: Reads file → Success! → Starts normally
```

## ❓ If It Still Doesn't Work

### Check 1: Is genesis.block still a directory?
```bash
ls -ld ./system-genesis-block/genesis.block

# If it shows 'd' at the start, it's STILL a directory:
drwxr-xr-x ... genesis.block/   ← BAD!

# Should show '-' at the start for a file:
-rw-r--r-- ... genesis.block     ← GOOD!
```

**Fix:**
```bash
rm -rf ./system-genesis-block/genesis.block
# Then run the docker cp commands again
```

### Check 2: Does genesis.block exist at all?
```bash
ls -la ./system-genesis-block/
```

**Should see:**
```
total 24
drwxr-xr-x  2 ubuntu ubuntu  4096 Nov 17 10:00 .
drwxr-xr-x 10 ubuntu ubuntu  4096 Nov 17 10:00 ..
-rw-r--r--  1 ubuntu ubuntu 10240 Nov 17 10:00 genesis.block
```

### Check 3: Can orderer read the file?
```bash
docker exec orderer.example.com ls -lh /var/hyperledger/orderer/orderer.genesis.block
```

**Should see:**
```
-rw-r--r-- 1 root root 10K ... /var/hyperledger/orderer/orderer.genesis.block
```

**If you see "No such file" or "Is a directory":**
```bash
# The volume mount is broken, restart orderer
docker-compose -f docker-compose-aws.yml restart orderer.example.com
```

## 📋 Complete Cleanup (If Nothing Else Works)

```bash
# Nuclear option - clean EVERYTHING
docker-compose -f docker-compose-aws.yml down -v
docker rm -f orderer.example.com peer0.org1.example.com cli
docker volume prune -f

# Remove ALL genesis blocks
rm -rf ./system-genesis-block/*
mkdir -p ./system-genesis-block

# Start fresh
docker-compose -f docker-compose-aws.yml up -d

# Wait for containers
sleep 5

# Generate genesis block the RIGHT way
docker exec cli bash -c "
cd /opt/gopath/src/github.com/hyperledger/fabric/peer
configtxgen -profile TwoOrgsOrdererGenesis \
  -channelID system-channel \
  -outputBlock genesis.block \
  -configPath /etc/hyperledger/fabric
"

# Copy properly
docker cp cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/genesis.block /tmp/gb.tmp
mv /tmp/gb.tmp ./system-genesis-block/genesis.block

# Restart orderer
docker-compose -f docker-compose-aws.yml restart orderer.example.com

# Check logs
docker logs orderer.example.com
```

## 🎉 Success Criteria

You'll know it's fixed when:

✅ `docker ps | grep orderer` shows orderer is **Up**
✅ `docker logs orderer.example.com` shows "Beginning to serve requests"
✅ No "panic" or "is a directory" in logs
✅ `ls -lh ./system-genesis-block/genesis.block` shows a **file** (starts with `-`)
✅ `file ./system-genesis-block/genesis.block` shows "data"
✅ Orderer stays running (doesn't crash after a few seconds)

## 🚀 Next Steps After Fix

```bash
# 1. Generate channel artifacts
docker exec cli configtxgen -profile TwoOrgsChannel \
  -channelID mychannel \
  -outputCreateChannelTx ./channel-artifacts/channel.tx \
  -configPath /etc/hyperledger/fabric

# 2. Create channel
./create-channel-aws.sh

# 3. Verify
docker exec cli peer channel list

# Should show: mychannel
```

---

## 📞 Quick Reference

```bash
# Check if genesis.block is file or directory
ls -ld ./system-genesis-block/genesis.block

# Remove directory version
rm -rf ./system-genesis-block/genesis.block

# Check orderer status
docker ps | grep orderer

# Check orderer logs
docker logs orderer.example.com --tail 50

# Restart orderer
docker-compose -f docker-compose-aws.yml restart orderer.example.com

# Run the automated fix
./fix-genesis-block.sh
```

---

**IMPORTANT:** The root cause is `genesis.block` being a DIRECTORY. Everything else fails because of this. Fix this ONE thing and everything else will work!

Run `./fix-genesis-block.sh` NOW and the orderer will start! 🚀
