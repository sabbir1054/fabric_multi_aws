# 🚀 How to Run Caliper Benchmarking System

**Last Updated:** 2025-11-09
**Status:** ✅ Ready to Use
**Configuration:** Fixed and Tested

---

## 📋 Table of Contents

1. [Quick Start (1 Minute)](#quick-start)
2. [Prerequisites Check](#prerequisites-check)
3. [Step-by-Step Guide](#step-by-step-guide)
4. [Understanding the Results](#understanding-the-results)
5. [Customizing Benchmarks](#customizing-benchmarks)
6. [Troubleshooting](#troubleshooting)

---

## 🎯 Quick Start

**If everything is already running, just do this:**

```bash
cd /home/sabbir/PROJECTS/working_with_explorer/water_sensor_ranking_in_privet_block_chain/caliper-workspace

./run-benchmark-sdk.sh
```

**Wait ~20 seconds, then:**

```bash
xdg-open report.html
```

**Done!** 🎉

---

## ✅ Prerequisites Check

Before running Caliper, verify these prerequisites:

### 1. Check Fabric Network is Running

```bash
docker ps | grep peer
```

**Expected output:**
```
peer0.org1.example.com    Up XX minutes
peer0.org2.example.com    Up XX minutes
orderer.example.com       Up XX minutes
```

**If not running:**
```bash
cd /home/sabbir/PROJECTS/working_with_explorer/water_sensor_ranking_in_privet_block_chain/fabric-samples/test-network
./network.sh up createChannel -c mychannel -ca
```

---

### 2. Check Chaincode is Deployed

```bash
cd /home/sabbir/PROJECTS/working_with_explorer/water_sensor_ranking_in_privet_block_chain/fabric-samples/test-network

export PATH=${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=$PWD/../config/
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051

peer lifecycle chaincode querycommitted --channelID mychannel
```

**Expected output:**
```
Committed chaincode definitions on channel 'mychannel':
Name: SensorContract, Version: 1.0, Sequence: 1, ...
```

**If not deployed:**
```bash
./network.sh deployCC -ccn SensorContract \
  -ccp ../asset-transfer-basic/chaincode-typescript \
  -ccl typescript
```

---

### 3. Verify SDK Connector is Installed

```bash
cd /home/sabbir/PROJECTS/working_with_explorer/water_sensor_ranking_in_privet_block_chain/caliper-workspace

npm list @hyperledger/caliper-fabric
```

**Expected output:**
```
@hyperledger/caliper-fabric@X.X.X
```

**If not installed:**
```bash
npx caliper bind --caliper-bind-sut fabric:2.2
```

*(This takes 2-3 minutes)*

---

## 📖 Step-by-Step Guide

### Method 1: Automated Script (Recommended)

#### Step 1: Navigate to Workspace

```bash
cd /home/sabbir/PROJECTS/working_with_explorer/water_sensor_ranking_in_privet_block_chain/caliper-workspace
```

#### Step 2: Run the Benchmark

```bash
./run-benchmark-sdk.sh
```

**What this does:**
- ✅ Checks Fabric network status
- ✅ Verifies chaincode deployment
- ✅ Confirms SDK connector installation
- ✅ Runs the benchmark
- ✅ Shows you where the report is saved

#### Step 3: View the Report

```bash
xdg-open report.html
```

**Alternative viewers:**
```bash
# Firefox
firefox report.html

# Chrome
google-chrome report.html

# Get full path
realpath report.html
```

---

### Method 2: Manual Command

If you prefer running the command manually:

```bash
cd /home/sabbir/PROJECTS/working_with_explorer/water_sensor_ranking_in_privet_block_chain/caliper-workspace

npx caliper launch manager \
  --caliper-workspace . \
  --caliper-benchconfig benchmarks/config.yaml \
  --caliper-networkconfig networks/fabric-network-sdk.yaml
```

---

## 📊 Understanding the Results

### Console Output

While the benchmark runs, you'll see:

```
2025.11.09-XX:XX:XX info [caliper] [caliper-engine] Starting benchmark flow
2025.11.09-XX:XX:XX info [caliper] [round-orchestrator] Started round 1 (addBatchSensorReadings-round1)
2025.11.09-XX:XX:XX info [caliper] [caliper-worker] Worker #0 starting workload loop
2025.11.09-XX:XX:XX info [caliper] [caliper-worker] Worker #1 starting workload loop
```

**What's happening:**
- **Round 1:** Sending 100 transactions at 50 TPS
- **Round 2:** Sending another 100 transactions at 50 TPS
- **Workers:** 2 workers running in parallel
- **Duration:** ~15-20 seconds total

---

### Success Indicators

**✅ You'll know it worked when you see:**

```
info [caliper] [round-orchestrator] Round 1 (addBatchSensorReadings-round1) finished successfully
info [caliper] [round-orchestrator] Round 2 (addBatchSensorReadings-round2) finished successfully
info [caliper] [report-builder] Report saved to: report.html
```

**And a summary table:**

```
┌─────────────────────┬─────────────────────────┐
│ Name                │ addBatchSensorReadings  │
│ Succ / Fail         │ 100 / 0                 │
│ Send Rate (TPS)     │ 50.2                    │
│ Max Latency (s)     │ 1.23                    │
│ Min Latency (s)     │ 0.15                    │
│ Avg Latency (s)     │ 0.45                    │
│ Throughput (TPS)    │ 48.5                    │
└─────────────────────┴─────────────────────────┘
```

---

### HTML Report

Open `report.html` in your browser to see:

#### 1. **Test Configuration**
- Benchmark name
- Number of rounds
- Transaction rates
- Worker configuration

#### 2. **Performance Summary**
| Metric | Description | Good Value |
|--------|-------------|------------|
| **Succ / Fail** | Successful vs Failed transactions | 100 / 0 |
| **Throughput (TPS)** | Transactions processed per second | 45-50 TPS |
| **Avg Latency** | Average transaction time | <1 second |
| **p99 Latency** | 99th percentile latency | <2 seconds |

#### 3. **Charts and Graphs**
- Transaction timeline
- Latency distribution
- Resource utilization (CPU, Memory, Network, Disk)
- Docker container stats

#### 4. **Detailed Metrics**
- Percentile latencies (p50, p75, p90, p95, p99)
- Min/Max latencies
- Success rates per round

---

## 🎨 Customizing Benchmarks

### Change Transaction Rate (TPS)

**Edit:** `benchmarks/config.yaml`

```yaml
rateControl:
  type: fixed-rate
  opts:
    tps: 100  # Change from 50 to 100 TPS
```

---

### Change Number of Transactions

**Edit:** `benchmarks/config.yaml`

```yaml
rounds:
  - label: addBatchSensorReadings-round1
    txNumber: 200  # Change from 100 to 200
```

---

### Change Batch Size

**Edit:** `benchmarks/config.yaml`

```yaml
workload:
  module: benchmarks/workload/addSensorReadings.js
  arguments:
    batchSize: 10  # Change from 5 to 10 sensors per transaction
```

---

### Add More Rounds

**Edit:** `benchmarks/config.yaml`

```yaml
rounds:
  - label: round1-baseline
    description: Baseline test at 50 TPS
    txNumber: 100
    rateControl:
      type: fixed-rate
      opts:
        tps: 50
    workload:
      module: benchmarks/workload/addSensorReadings.js
      arguments:
        batchSize: 5

  - label: round2-moderate
    description: Moderate load at 75 TPS
    txNumber: 100
    rateControl:
      type: fixed-rate
      opts:
        tps: 75
    workload:
      module: benchmarks/workload/addSensorReadings.js
      arguments:
        batchSize: 5

  - label: round3-heavy
    description: Heavy load at 100 TPS
    txNumber: 200
    rateControl:
      type: fixed-rate
      opts:
        tps: 100
    workload:
      module: benchmarks/workload/addSensorReadings.js
      arguments:
        batchSize: 10
```

**After making changes, run the benchmark again:**
```bash
./run-benchmark-sdk.sh
```

---

## 🔧 Troubleshooting

### Issue 1: "Cannot find module 'fabric-network'"

**Cause:** SDK connector not installed

**Solution:**
```bash
cd /home/sabbir/PROJECTS/working_with_explorer/water_sensor_ranking_in_privet_block_chain/caliper-workspace
npx caliper bind --caliper-bind-sut fabric:2.2
```

---

### Issue 2: "Connection refused" or "ECONNREFUSED"

**Cause:** Fabric network not running

**Solution:**
```bash
# Check status
docker ps | grep peer

# If not running, start network
cd /home/sabbir/PROJECTS/working_with_explorer/water_sensor_ranking_in_privet_block_chain/fabric-samples/test-network
./network.sh down
./network.sh up createChannel -c mychannel -ca
./network.sh deployCC -ccn SensorContract \
  -ccp ../asset-transfer-basic/chaincode-typescript \
  -ccl typescript
```

---

### Issue 3: High Failure Rate in Results

**Symptoms:**
```
Succ / Fail: 75 / 25  ❌ 25% failure rate
```

**Possible Causes:**
1. TPS too high for your system
2. Chaincode has errors
3. Network congestion

**Solutions:**

**A. Reduce TPS:**
```yaml
# In benchmarks/config.yaml
tps: 25  # Start lower, increase gradually
```

**B. Check chaincode logs:**
```bash
docker logs peer0.org1.example.com 2>&1 | tail -50
```

**C. Test chaincode manually:**
```bash
cd /home/sabbir/PROJECTS/working_with_explorer/water_sensor_ranking_in_privet_block_chain/fabric-samples/test-network

export PATH=${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=$PWD/../config/
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051

peer chaincode invoke -C mychannel -n SensorContract \
  -c '{"function":"addBatchSensorReadings","Args":["[{\"SensorID\":\"test\",\"Temp\":\"25\",\"Salinity\":\"35\",\"PH\":\"7\",\"NH4\":\"0.1\",\"DO\":\"8\",\"CA\":\"150\"}]","'$(date +%s)'"]}'
```

---

### Issue 4: No report.html Generated

**Cause:** Benchmark failed or was interrupted

**Solution:**

**1. Check for errors in console output**

**2. Run with debug mode:**
```bash
export DEBUG=caliper*
./run-benchmark-sdk.sh
```

**3. Check if report files exist:**
```bash
ls -la report.*
```

**4. Verify successful transactions:**
Look for this in the console:
```
Succ / Fail: 100 / 0  ← Should be 100 successful
```

---

### Issue 5: "Network configuration version not supported"

**Cause:** Wrong configuration version

**Solution:**
This has already been fixed! The `networks/fabric-network-sdk.yaml` now has:
```yaml
version: "2.0.0"  ✅
```

If you still see this error, verify:
```bash
head -5 networks/fabric-network-sdk.yaml
```

Should show:
```yaml
---
name: Water Sensor Fabric Network SDK
version: "2.0.0"
```

---

## 📈 Performance Analysis

### Interpreting Results

#### Good Performance ✅
```
Throughput: 48-50 TPS       (Close to target of 50 TPS)
Avg Latency: 0.3-0.5s       (Fast response)
p99 Latency: <2s            (99% complete quickly)
Success Rate: >95%          (High reliability)
```

#### Performance Issues ⚠️
```
Throughput: <40 TPS         (Below target)
Avg Latency: >2s            (Slow response)
p99 Latency: >5s            (Long tail latency)
Success Rate: <90%          (High failure rate)
```

### What to Optimize

**If throughput is low:**
- Increase peer resources (CPU/Memory)
- Optimize chaincode logic
- Reduce transaction complexity
- Increase block size or reduce block timeout

**If latency is high:**
- Optimize chaincode queries
- Reduce endorsement requirements
- Optimize database operations
- Check network bandwidth

**If failure rate is high:**
- Check chaincode errors in logs
- Verify endorsement policy
- Check resource limits
- Reduce TPS to sustainable level

---

## 💡 Best Practices

### 1. Start Small, Scale Up

```bash
# Test 1: Baseline (low TPS)
tps: 10, txNumber: 50

# Test 2: Moderate
tps: 25, txNumber: 100

# Test 3: Target
tps: 50, txNumber: 200

# Test 4: Stress
tps: 100, txNumber: 500
```

---

### 2. Save Your Reports

```bash
# Create reports directory
mkdir -p reports

# Run benchmark and save with timestamp
./run-benchmark-sdk.sh
mv report.html reports/benchmark-$(date +%Y%m%d-%H%M%S).html
```

---

### 3. Document Your Tests

Create a spreadsheet tracking:
- Date/Time
- Configuration (TPS, txNumber, batchSize)
- Results (Throughput, Latency, Success Rate)
- System state (CPU, Memory, Network)
- Notes (observations, issues, changes)

---

### 4. Monitor System Resources

**In another terminal, watch Docker stats:**
```bash
docker stats
```

**Look for:**
- High CPU usage (>80% sustained)
- Memory limits being hit
- Network saturation

---

## 🎓 Understanding the Benchmark

### What Gets Benchmarked

**Function:** `addBatchSensorReadings(jsonData, timestamp)`

**Each transaction:**
1. Generates 5 sensor readings (configurable)
2. Converts to JSON
3. Submits to chaincode
4. Chaincode processes data
5. Data written to ledger
6. Transaction committed

**Two rounds:**
- Round 1: 100 transactions
- Round 2: 100 transactions
- Total: 200 transactions = 1,000 sensor readings (5 per tx)

---

### Metrics Explained

#### Throughput (TPS)
**Transactions Per Second** - How many transactions the system processes per second

**Example:** 48.5 TPS = 48.5 transactions completed every second

---

#### Latency
**Time from submission to completion**

- **Min:** Fastest transaction
- **Avg:** Average across all transactions
- **p50 (Median):** 50% of transactions completed in this time or less
- **p90:** 90% of transactions completed in this time or less
- **p95:** 95% of transactions completed in this time or less
- **p99:** 99% of transactions completed in this time or less
- **Max:** Slowest transaction

---

#### Send Rate
**Transactions sent per second** by Caliper (target rate)

Should match your configured TPS (50 in default config)

---

## 🔄 Running Multiple Tests

### Compare Different Configurations

```bash
# Test 1: Baseline
vim benchmarks/config.yaml  # Set tps: 50
./run-benchmark-sdk.sh
mv report.html reports/test1-50tps.html

# Test 2: Higher TPS
vim benchmarks/config.yaml  # Set tps: 100
./run-benchmark-sdk.sh
mv report.html reports/test2-100tps.html

# Test 3: Larger batches
vim benchmarks/config.yaml  # Set batchSize: 10
./run-benchmark-sdk.sh
mv report.html reports/test3-batch10.html

# Compare results
firefox reports/test1-50tps.html reports/test2-100tps.html reports/test3-batch10.html
```

---

## 📞 Getting Help

### Documentation Files

1. **HOW_TO_RUN_CALIPER.md** (this file) - How to run
2. **COMPLETE_SOLUTION.md** - Technical solution details
3. **SOLUTION_README.md** - Quick reference
4. **LOG_ANALYSIS.md** - Previous error analysis
5. **QUICK_START.md** - Usage guide

### Check Logs

```bash
# Caliper logs
ls -lt *.log

# Docker logs
docker logs peer0.org1.example.com 2>&1 | tail -100
docker logs orderer.example.com 2>&1 | tail -100
```

### Manual Chaincode Test

```bash
cd /home/sabbir/PROJECTS/working_with_explorer/water_sensor_ranking_in_privet_block_chain/fabric-samples/test-network

export PATH=${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=$PWD/../config/
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051

peer chaincode invoke -C mychannel -n SensorContract \
  -c '{"function":"addBatchSensorReadings","Args":["[{\"SensorID\":\"test\",\"Temp\":\"25\",\"Salinity\":\"35\",\"PH\":\"7\",\"NH4\":\"0.1\",\"DO\":\"8\",\"CA\":\"150\"}]","'$(date +%s)'"]}'
```

---

## ✅ Success Checklist

Before running:
- [ ] Fabric network is running (`docker ps`)
- [ ] SensorContract is deployed (`peer lifecycle chaincode querycommitted`)
- [ ] SDK connector is installed (`npm list @hyperledger/caliper-fabric`)
- [ ] In caliper-workspace directory

After running:
- [ ] No errors in console output
- [ ] "Round 1 finished successfully" message
- [ ] "Round 2 finished successfully" message
- [ ] `report.html` file exists
- [ ] Can open report.html in browser
- [ ] Report shows high success rate (>95%)

---

## 🎉 You're Ready!

Run your first benchmark:

```bash
cd /home/sabbir/PROJECTS/working_with_explorer/water_sensor_ranking_in_privet_block_chain/caliper-workspace
./run-benchmark-sdk.sh
```

View the results:

```bash
xdg-open report.html
```

**Good luck!** 🚀

---

**Created:** 2025-11-09
**Status:** ✅ Ready to Use
**Configuration:** Fixed and Tested
**Fabric Version:** 2.5
**Caliper Version:** 0.6.0
**SDK Version:** 2.2
