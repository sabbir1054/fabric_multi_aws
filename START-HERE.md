# 🚀 START HERE - Quick Deployment

## Step 1: Install Prerequisites (If Not Already Installed)

### Check if you have everything:
```bash
./check-prerequisites.sh --machine1  # On Machine 1
./check-prerequisites.sh --machine2  # On Machine 2
```

### If anything is missing, install automatically:
```bash
./install-prerequisites.sh --machine1  # On Machine 1
./install-prerequisites.sh --machine2  # On Machine 2

# Then logout and login again
```

**Time Required:** 5-15 minutes (one-time setup)

---

## Step 2: Deploy Your Network (Just 2 Commands!)

### Machine 1 (13.239.132.194)
```bash
./setup-machine1.sh
```

### Machine 2 (178.16.139.239)
```bash
# After transferring files from Machine 1:
tar -xzf machine2-package.tar.gz
./setup-machine2.sh
```

**Time Required:** 3-5 minutes total

---

## Prerequisites Summary

**Both Machines Need:**
- ✅ Docker (v20.10+)
- ✅ Docker Compose (v1.29+)
- ✅ Network connectivity between machines

**Machine 1 Also Needs:**
- ✅ Fabric binaries (cryptogen, configtxgen, peer)

**See:** `PREREQUISITES-SUMMARY.txt` or `PREREQUISITES.md` for details

---

## Full Instructions

See **ONE-COMMAND-SETUP.md** for the complete guide.

---

## Your Project Structure

```
✓ chaincode/            - Your custom TypeScript chaincode
✓ ph_water_backend/     - Your backend application
✓ ph_water_frontend/    - Your frontend application
✓ docker-compose-org1.yaml - Machine 1 config (IPs updated ✓)
✓ docker-compose-org2.yaml - Machine 2 config (IPs updated ✓)
✓ setup-machine1.sh     - ONE command for Machine 1
✓ setup-machine2.sh     - ONE command for Machine 2
```

---

## Questions?

- **Detailed docs**: `SETUP-GUIDE.md`
- **Quick reference**: `QUICK-START.md`
- **Simple setup**: `ONE-COMMAND-SETUP.md` ← You are here
