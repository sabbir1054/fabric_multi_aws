# ROOT CAUSE ANALYSIS - Orderer "is a directory" Panic

## 🔴 THE REAL PROBLEM (from problem.md line 114)

```
panic: unable to bootstrap orderer.
Error reading genesis block file:
read /var/hyperledger/orderer/orderer.genesis.block: is a directory
```

## 🎯 Root Cause Explanation

### What Happened:

1. **The orderer DOES start** and loads all configuration successfully (lines 11-111 in problem.md)
2. **Then it immediately PANICS** because it tries to read the genesis block file
3. **The genesis block is a DIRECTORY, not a FILE**

### Why This Happened:

#### Docker Volume Mount in docker-compose-aws.yml:
```yaml
volumes:
  - ./system-genesis-block/genesis.block:/var/hyperledger/orderer/orderer.genesis.block
```

This mount expects:
- **Host side:** `./system-genesis-block/genesis.block` should be a **FILE**
- **Container side:** `/var/hyperledger/orderer/orderer.genesis.block` should be a **FILE**

#### The Corruption Sequence:

1. **First run:** `docker cp` creates genesis.block as a directory
   ```bash
   docker cp cli:.../genesis.block ./system-genesis-block/genesis.block
   ```
   If `genesis.block` doesn't exist, Docker creates it as a **DIRECTORY** and copies the file inside it:
   ```
   ./system-genesis-block/genesis.block/genesis.block  ← WRONG!
   ```

2. **Docker Compose mounts a directory:** When docker-compose tries to mount this:
   - It sees `genesis.block` is a directory
   - It mounts the directory to the container path
   - Inside container: `/var/hyperledger/orderer/orderer.genesis.block` becomes a **DIRECTORY**

3. **Orderer panics:** The orderer tries to read the file:
   ```go
   // Fabric code expects a file
   file, err := os.Open("/var/hyperledger/orderer/orderer.genesis.block")
   // But gets: "is a directory" error
   → PANIC!
   ```

## 🔍 Evidence from problem.md

### Line 114: The Panic
```
panic: unable to bootstrap orderer. Error reading genesis block file:
read /var/hyperledger/orderer/orderer.genesis.block: is a directory
```

### Lines 11-113: Orderer Started Successfully
The orderer loaded all config:
- ✓ TLS enabled
- ✓ Bootstrap method: file
- ✓ Bootstrap file: /var/hyperledger/orderer/orderer.genesis.block
- ✓ MSP configured
- ✓ All settings loaded

Then crashed trying to read the genesis block.

### Line 129: Orderer Not Available
```
dial tcp: lookup orderer.example.com: no such host
```
Why? Because orderer container **exited** after the panic. It's not running anymore.

## ✅ The Complete Fix

### Fix 1: Clean Everything First
```bash
# Remove EVERYTHING in system-genesis-block
rm -rf ./system-genesis-block/*
mkdir -p ./system-genesis-block
```

This ensures no leftover directories exist.

### Fix 2: Generate Fresh Genesis Block
```bash
docker exec cli bash -c "
cd /opt/gopath/src/github.com/hyperledger/fabric/peer
configtxgen -profile TwoOrgsOrdererGenesis \
    -channelID system-channel \
    -outputBlock genesis.block \
    -configPath /etc/hyperledger/fabric
"
```

Generate inside the CLI container.

### Fix 3: Copy as FILE (not to directory path)
```bash
# Copy to temp location FIRST
docker cp cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/genesis.block /tmp/genesis.block.tmp

# Then move to final location
mv /tmp/genesis.block.tmp ./system-genesis-block/genesis.block
```

This ensures we get a **FILE**, not a directory.

### Fix 4: Verify It's a File
```bash
if [ -f "./system-genesis-block/genesis.block" ] && [ ! -d "./system-genesis-block/genesis.block" ]; then
    echo "✓ It's a file!"
    file ./system-genesis-block/genesis.block
    # Should output: data
else
    echo "✗ It's a directory or doesn't exist!"
    exit 1
fi
```

### Fix 5: Restart Orderer
```bash
docker-compose -f docker-compose-aws.yml restart orderer.example.com
```

## 🚀 How to Apply the Fix

### Option 1: Use the Fix Script (RECOMMENDED)
```bash
./fix-genesis-block.sh
```

This script:
1. Checks if genesis.block is a directory
2. Stops the orderer
3. Removes the problematic genesis.block
4. Generates a fresh one as a FILE
5. Restarts the orderer
6. Verifies it's working

### Option 2: Manual Cleanup
```bash
# 1. Stop containers
docker-compose -f docker-compose-aws.yml down

# 2. Clean genesis block
rm -rf ./system-genesis-block/*
mkdir -p ./system-genesis-block

# 3. Start containers
docker-compose -f docker-compose-aws.yml up -d

# 4. Run setup (now fixed)
./setup-aws.sh
```

### Option 3: Complete Reset
```bash
./cleanup-aws.sh
./setup-aws.sh
```

## 🔬 Verification

### Check if genesis.block is a FILE:
```bash
ls -lah ./system-genesis-block/genesis.block

# Good output:
-rw-r--r-- 1 user user 10K Nov 17 10:00 genesis.block

# Bad output (DIRECTORY):
drwxr-xr-x 2 user user 4.0K Nov 17 10:00 genesis.block/
```

### Check file type:
```bash
file ./system-genesis-block/genesis.block

# Should show:
./system-genesis-block/genesis.block: data
```

### Check orderer logs:
```bash
docker logs orderer.example.com 2>&1 | tail -20

# Should see:
"Beginning to serve requests"

# Should NOT see:
"panic: unable to bootstrap"
"is a directory"
```

### Check orderer is running:
```bash
docker ps | grep orderer

# Should show:
orderer.example.com   Up 2 minutes   0.0.0.0:7050->7050/tcp
```

## 📊 Before vs After

### BEFORE (Broken):
```
./system-genesis-block/
└── genesis.block/              ← DIRECTORY!
    └── genesis.block           ← File inside directory
```

**Result:** Orderer panics because it tries to read a directory.

### AFTER (Fixed):
```
./system-genesis-block/
└── genesis.block               ← FILE!
```

**Result:** Orderer reads the file successfully and starts.

## 🎓 Why Docker cp Behaves This Way

Docker cp follows these rules:

1. **If destination exists as DIRECTORY:**
   ```bash
   docker cp source dest/
   # Copies INTO the directory
   # Creates: dest/source
   ```

2. **If destination doesn't exist:**
   ```bash
   docker cp source dest
   # If source is a file: creates dest as FILE
   # If source is a dir: creates dest as DIRECTORY
   ```

3. **Our mistake:**
   ```bash
   docker cp cli:.../genesis.block ./system-genesis-block/genesis.block
   # On second run, if genesis.block exists as directory:
   # Creates: ./system-genesis-block/genesis.block/genesis.block
   ```

## ✅ The Permanent Solution

The updated `setup-aws.sh` now:

1. **Always cleans first:**
   ```bash
   rm -rf ./system-genesis-block/*
   ```

2. **Copies to temp first:**
   ```bash
   docker cp ... /tmp/genesis.block.tmp
   mv /tmp/genesis.block.tmp ./system-genesis-block/genesis.block
   ```

3. **Verifies it's a file:**
   ```bash
   [ -f genesis.block ] && [ ! -d genesis.block ]
   ```

4. **Restarts orderer:**
   ```bash
   docker-compose restart orderer.example.com
   ```

This ensures the genesis.block is ALWAYS a file, never a directory.

## 🚨 Common Mistakes to Avoid

### DON'T do this:
```bash
# ✗ Wrong - can create nested directories
docker cp cli:.../genesis.block ./system-genesis-block/genesis.block

# ✗ Wrong - doesn't verify it's a file
docker cp cli:.../genesis.block ./system-genesis-block/
```

### DO this instead:
```bash
# ✓ Correct - copy to temp first
docker cp cli:.../genesis.block /tmp/temp.block
mv /tmp/temp.block ./system-genesis-block/genesis.block

# ✓ Correct - verify it's a file
[ -f ./system-genesis-block/genesis.block ]
```

## 📝 Summary

**Root Cause:** Genesis block became a directory instead of a file due to improper `docker cp` usage.

**Impact:** Orderer starts but immediately panics when trying to read the "file" that is actually a directory.

**Fix:** Clean the directory, generate fresh genesis block, copy as a file (not to a path), verify it's a file, restart orderer.

**Prevention:** Updated setup-aws.sh always cleans first and copies to temp location before moving to final path.

**Run this now:**
```bash
./fix-genesis-block.sh
```

Then verify:
```bash
docker ps | grep orderer     # Should be running
docker logs orderer.example.com | grep "Beginning to serve"  # Should see this
```

Done! 🎉
