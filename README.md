# Multi-Cloud Hyperledger Fabric Network

## 🚨 YOUR CURRENT ERROR (from problem.md)

**Problem:** Orderer is NOT running on AWS
**Error:** `lookup orderer.example.com: no such host`
**Line 31:** `✗ Orderer container not found`

## ❓ Do You Need to Configure GCP?

**NO! Not yet.** This is an AWS-only problem.

**The sequence is:**

1. ✅ Fix orderer on AWS (do this first!)
2. ✅ Create channel on AWS
3. ✅ Then copy artifacts to GCP
4. ✅ Then setup GCP

**You're stuck at step 1 - orderer is not running on AWS.**

---

## 🚀 FIX THE ERROR (Run on AWS)

### **⭐ ONE COMMAND FIX:**

```bash
./fix-orderer-now.sh
```

This will:

1. ✅ Check why orderer failed
2. ✅ Show orderer logs if crashed
3. ✅ Fix genesis block if it's a directory
4. ✅ Regenerate genesis block if needed
5. ✅ Check TLS certificates
6. ✅ Start orderer
7. ✅ Verify it's working
8. ✅ Tell you exactly what's wrong if it fails

### After orderer is running:

```bash
./create-channel-aws.sh   # Create channel
./diagnose.sh             # Verify everything
```

---

## 📁 Files in This Directory

### **Scripts (All .sh files are needed):**

- `start-orderer.sh` - Start/fix orderer ⭐ **RUN THIS FIRST**
- `setup-aws.sh` - Initial AWS setup
- `create-channel-aws.sh` - Create channel on AWS
- `cleanup-aws.sh` - Clean everything
- `diagnose.sh` - Check network health
- `fix-genesis-block.sh` - Fix genesis block issues
- `copy-to-gcp.sh` - Copy artifacts to GCP
- `setup-gcp.sh` - Setup GCP (run on GCP machine)
- `join-channel-gcp.sh` - Join Org2 to channel (run on GCP)
- `cleanup-gcp.sh` - Clean GCP

### **Documentation (Only 3 files):**

- `README.md` - This file ⭐ **START HERE**
- `DEPLOYMENT-GUIDE.md` - Full deployment guide
- `TROUBLESHOOTING.md` - When things go wrong
- `problem.md` - Your current error log

### **Configuration:**

- `docker-compose-aws.yml` - AWS containers
- `docker-compose-gcp.yml` - GCP containers

---

## 🎯 Deployment Steps (In Order)

### **Phase 1: AWS Setup (YOU ARE HERE)**

```bash
# On AWS machine (54.79.85.38)

# 1. Start orderer (fixes genesis block issue)
./start-orderer.sh

# 2. Verify orderer is running
docker ps | grep orderer
# Should show: orderer.example.com   Up X seconds

# 3. Create channel
./create-channel-aws.sh

# 4. Verify everything works
./diagnose.sh
# Should show all green checkmarks
```

### **Phase 2: GCP Setup (DO AFTER AWS WORKS)**

```bash
# On AWS machine - Copy artifacts to GCP
./copy-to-gcp.sh

# On GCP machine (178.16.139.239)
cd ~/fabric-network
chmod +x *.sh

# Setup GCP
./setup-gcp.sh

# Join channel
./join-channel-gcp.sh

# Verify
./diagnose.sh
```

---

## ❌ Common Errors

### Error: "Orderer container not found"

**Solution:** Run `./start-orderer.sh`

### Error: "genesis.block: is a directory"

**Solution:** Run `./fix-genesis-block.sh`

### Error: "lookup orderer.example.com: no such host"

**Cause:** Orderer is not running
**Solution:** Run `./start-orderer.sh`

### Error: Channel creation fails

**Cause:** Orderer not serving requests
**Check:** `docker logs orderer.example.com | grep "Beginning to serve"`
**Solution:** If not serving, restart: `docker-compose -f docker-compose-aws.yml restart orderer.example.com`

---

## 📊 Network Architecture

```
┌─────────────────────────────────────┐
│   AWS (54.79.85.38)              │
│   ┌───────────────────────────────┐ │
│   │  Orderer :7050                │ │  ← You need this working first!
│   │  Peer0.Org1 :7051             │ │
│   │  CLI                          │ │
│   └───────────────────────────────┘ │
└──────────────┬──────────────────────┘
               │
               │ Internet
               │
┌──────────────┴──────────────────────┐
│   GCP (178.16.139.239)              │
│   ┌───────────────────────────────┐ │
│   │  Peer0.Org2 :7051             │ │  ← Setup this later
│   │  CLI_Org2                     │ │
│   └───────────────────────────────┘ │
└─────────────────────────────────────┘
```

---

## ✅ Success Checklist (AWS)

Before proceeding to GCP, verify ALL these:

- [ ] `docker ps | grep orderer` shows orderer running
- [ ] `docker logs orderer.example.com` shows "Beginning to serve requests"
- [ ] `./diagnose.sh` shows orderer status ✓
- [ ] Genesis block exists and is a FILE: `ls -lh ./system-genesis-block/genesis.block`
- [ ] Channel created: `ls -lh ./channel-artifacts/mychannel.block`
- [ ] Peer joined channel: `docker exec cli peer channel list` shows `mychannel`
- [ ] No errors in logs: `docker logs peer0.org1.example.com`

---

## 🆘 Quick Debug

```bash
# Check all containers
docker ps -a

# Check orderer logs
docker logs orderer.example.com

# Check peer logs
docker logs peer0.org1.example.com

# Check if genesis.block is a file
ls -ld ./system-genesis-block/genesis.block
# Should start with '-' (file), not 'd' (directory)

# Restart everything
docker-compose -f docker-compose-aws.yml restart

# Nuclear option - start fresh
./cleanup-aws.sh
./setup-aws.sh
```

---

## 📞 Summary

**Your current issue:** Orderer not running on AWS
**Do you need GCP?** NO, not yet
**What to do:** Run `./start-orderer.sh` on AWS
**Then:** Run `./create-channel-aws.sh`
**Verify:** Run `./diagnose.sh`

**Only after AWS is 100% working, then setup GCP.**

---

## 🎯 Action Required RIGHT NOW

```bash
# On AWS machine, run this:
./start-orderer.sh
```

That's it. This will fix your orderer issue.
