# 🔴 ORDERER NOT WORKING? RUN THIS!

## Your Error:
```
✗ Orderer container not found
lookup orderer.example.com: no such host
```

## 🚀 THE FIX (Copy & Paste This):

```bash
cd ~/fabric_multi_aws  # or wherever your files are

./fix-orderer-now.sh
```

**That's it!** This one command will:
- ✅ Find out why orderer is not working
- ✅ Show you the actual error
- ✅ Fix it automatically
- ✅ Start orderer
- ✅ Verify it works

---

## What If It Still Doesn't Work?

The script will tell you **EXACTLY** what's wrong. Common issues:

### 1. Genesis Block is a Directory
**You'll see:** `Genesis block is a DIRECTORY`
**What script does:** Deletes it and recreates as a file

### 2. Orderer is Crashing (Panic)
**You'll see:** `ORDERER IS PANICKING`
**Check:** The script shows the panic message
**Common cause:** Wrong genesis block path

### 3. TLS Certificates Missing
**You'll see:** `TLS certificates missing`
**Fix:** You need to generate crypto materials first

### 4. Container Won't Start
**You'll see:** `ORDERER FAILED TO START`
**Check:** The script shows docker-compose errors

---

## After Orderer Works:

When you see:
```
✓✓✓ ORDERER IS WORKING! ✓✓✓
```

Then run:
```bash
./create-channel-aws.sh
./diagnose.sh
```

---

## Still Stuck?

Run these commands and share the output:

```bash
# 1. Check what containers are running
docker ps -a

# 2. Check orderer logs
docker logs orderer.example.com 2>&1 | tail -50

# 3. Check if genesis.block is a file or directory
ls -ld ./system-genesis-block/genesis.block

# 4. Check TLS certs exist
ls -la ./organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/
```

---

## Quick Commands:

```bash
# See full orderer logs
docker logs orderer.example.com

# Restart orderer
docker-compose -f docker-compose-aws.yml restart orderer.example.com

# Check orderer status
docker ps | grep orderer

# Nuclear option (clean everything and start over)
./cleanup-aws.sh
./setup-aws.sh
```

---

**REMEMBER:** Just run `./fix-orderer-now.sh` and it will tell you what's wrong!
