# AWS IP Address Update Summary

## ✅ Update Completed

**Old AWS IP:** `3.27.144.169`
**New AWS IP:** `13.239.132.194`
**GCP IP:** `178.16.139.239` (unchanged)

---

## 📝 Files Updated

### 1. **docker-compose-gcp.yml** ✅
Updated `extra_hosts` in both services:
- `peer0.org2.example.com` service (lines 45-46)
- `cli_org2` service (lines 77-78)

**Changes:**
```yaml
# Before
- "orderer.example.com:3.27.144.169"
- "peer0.org1.example.com:3.27.144.169"

# After
- "orderer.example.com:13.239.132.194"
- "peer0.org1.example.com:13.239.132.194"
```

### 2. **diagnose.sh** ✅
Updated connectivity test section

### 3. **DEPLOYMENT-GUIDE.md** ✅
Updated all references to AWS IP in documentation

### 4. **QUICK-START.md** ✅
Updated AWS IP references

### 5. **FIX-NOW.md** ✅
Updated AWS IP references

---

## 🔍 Verification

All occurrences of old IP (`3.27.144.169`) have been replaced with new IP (`13.239.132.194`).

```bash
# Verify old IP is gone
grep -r "3.27.144.169" . --include="*.yml" --include="*.sh" --include="*.md"
# Result: (no output - all replaced)

# Verify new IP is present
grep -r "13.239.132.194" . --include="*.yml" --include="*.sh" --include="*.md" | wc -l
# Result: 10+ occurrences
```

---

## 🚀 What This Means for GCP

When you run the GCP setup, the Org2 peer will now connect to:
- **Orderer at:** `13.239.132.194:7050`
- **Peer0.Org1 at:** `13.239.132.194:7051`

Make sure:
1. AWS machine is accessible at `13.239.132.194`
2. Ports 7050 and 7051 are open on AWS
3. Security groups allow traffic from GCP IP (178.16.139.239)

---

## 📋 Next Steps

### On AWS (13.239.132.194):
```bash
# 1. Fix genesis block issue (if not already done)
./fix-genesis-block.sh

# 2. Create channel
./create-channel-aws.sh

# 3. Verify everything works
./diagnose.sh
```

### On GCP (178.16.139.239):
```bash
# 1. Copy artifacts from AWS
# (Run on AWS machine)
./copy-to-gcp.sh

# 2. Setup GCP
./setup-gcp.sh

# 3. Join channel
./join-channel-gcp.sh
```

---

## 🔧 Test Connectivity

### From GCP to AWS:
```bash
# On GCP machine, test if you can reach new AWS IP
ping 13.239.132.194
telnet 13.239.132.194 7050  # Orderer
telnet 13.239.132.194 7051  # Peer
```

### From AWS to GCP:
```bash
# On AWS machine
ping 178.16.139.239
telnet 178.16.139.239 7051  # Org2 Peer
```

---

## ✅ Configuration Summary

### AWS Machine (13.239.132.194)
- **Runs:** Orderer + Peer0.Org1 + CLI
- **Listens on:** 0.0.0.0:7050, 0.0.0.0:7051
- **Accessible to:** GCP at 178.16.139.239

### GCP Machine (178.16.139.239)
- **Runs:** Peer0.Org2 + CLI
- **Connects to:** AWS at 13.239.132.194
- **Listens on:** 0.0.0.0:7051

---

**All configurations updated successfully!** ✅

The network is now ready to be deployed with the new AWS IP address.
