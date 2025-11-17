ভালো — নিচে step-by-step, প্র্যাকটিক্যাল নির্দেশনা দিলাম যাতে তুমি **Multi-Cloud (AWS + GCP) WITHOUT DevSecOps** সেটআপটি সহজভাবে চালাতে পারো। আমি ধরেছি তুমি Docker-Compose ভিত্তিক, lightweight অথচ reproducible পদ্ধতি চাও — তাই সেই আনকরম্প্লেক্স পদ্ধতিই দেখাচ্ছি। প্রতিটি ধাপে কনফিগ/কমান্ড উদাহরণ দিয়েছি যাতে কপি-পেস্ট করে চালাতে পারো।

> সংক্ষেপে কী করব:
> 
> 
> *AWS VM* এ Org1 + Orderer চালাবে, *GCP VM* এ Org2 চালাবে। Crypto / channel artifacts AWS-এ বানাবে, পরে প্রয়োজনীয় ফাইলগুলো GCP-এ কপি করে Org2 peer join করাবে। কনটেইনারগুলো একে-অপরকে public hostnames/IP দিয়ে দেখে — docker-compose এর extra_hosts ব্যবহার করে।
> 

---

## 0) প্রয়োজনীয়তা (প্রতি VM — AWS & GCP)

- Ubuntu 20.04/22.04 VM (প্রতিটিতে)
- Root বা sudo access
- Docker & docker-compose installed
- git, curl, unzip, jq
- Fabric binaries (peer, orderer, configtxgen, cryptogen) — বা Fabric samples repo
- Ports খোলা: 7050, 7051, 7053, 7054, 5984 (CouchDB if used) — কিন্তু production না, thesis only: restrict to your IP

---

## 1) পরিবেশ প্রস্তুতি (AWS এবং GCP উভয়েই)

### A. Docker ও Tools ইনস্টল (প্রতি VM)

```bash
sudo apt update && sudo apt install -y git curl docker.io docker-compose unzip
sudo usermod -aG docker $USER
# log out & log in again or:
newgrp docker

```

### B. Hyperledger Fabric samples ও binaries নাও (AWS-এ কাজ সহজ হবে)

AWS VM এ (এটিই central place আমরা artifacts বানাবো):

```bash
mkdir -p ~/fabric-test && cd ~/fabric-test
git clone https://github.com/hyperledger/fabric-samples.git
cd fabric-samples
# get specific fabric binaries & docker images script (adjust version if needed)
curl -sSL https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/bootstrap.sh | bash -s -- 2.5.0

```

> যদি কোনও script না কাজ করে, Fabric official releases থেকে binaries নিয়ে আনবে — কিন্তু repo clone করলেই examples থাকবে।
> 

---

## 2) নেটওয়ার্ক পরিকল্পনা ও host mapping (public IP ব্যবহার)

ধরা:

- **AWS public IP:** `AWS_IP`
- **GCP public IP:** `GCP_IP`

আমরা container-level 호স্টনেম resolve করাতে `extra_hosts` ব্যবহার করব। docker-compose ফাইল দুই-টাই (AWS-side এবং GCP-side) তৈরি থাকবে; কিন্তু hostnames একই রাখব: `orderer.example.com`, `peer0.org1.example.com`, `peer0.org2.example.com` ইত্যাদি। AWS-এ তৈরী করা genesis/channel artifacts GCP-এ কপি করব।

---

## 3) Crypto ও Channel Artifacts বানানো (AWS-এ)

AWS VM-এ (fabric-samples ডিরেক্টরি), উদাহরণ `test-network` ব্যবহার করে কাস্টম তৈরি করো বা নিজস্ব docker-compose তৈরী করো। এখানে cryptogen + configtxgen ব্যবহার করব (সোজা ও দ্রুত):

প্রথমে `crypto-config.yaml` এবং `configtx.yaml` তৈরি করো (basic two orgs)। (fabric docs এ sample config আছে।)

```bash
# example location
cd ~/fabric-test
# create directories
mkdir -p network-config
# put your crypto-config.yaml and configtx.yaml inside network-config

```

crypto তৈরি:

```bash
export PATH=/home/ubuntu/fabric-samples/bin:$PATH
cryptogen generate --config=network-config/crypto-config.yaml --output=crypto-config

```

genesis.block ও channel.tx তৈরি:

```bash
configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock ./system-genesis-block/genesis.block
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID mychannel
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -asOrg Org1MSP
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx -asOrg Org2MSP

```

(ইহা configtx.yaml অনুযায়ী হবে; file names ও profile তোমার কনফিগ অনুযায়ী পরিবর্তন হবে)

---

## 4) docker-compose ফাইল (AWS-side ও GCP-side) তৈরি

**AWS docker-compose (aws-docker-compose.yml)** — এখানে orderer + peer0.org1 + cli কনটেইনার থাকবে। extra_hosts এ GCP peer hostname map করো।

সংকেত (snippet):

```yaml
version: '2'

services:
  orderer.example.com:
    image: hyperledger/fabric-orderer:2.5
    environment:
      - ORDERER_GENERAL_LISTENADDRESS=0.0.0.0
    ports:
      - 7050:7050
    volumes:
      - ./system-genesis-block:/var/hyperledger/orderer/orderer.genesis.block
      - ./crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/:/var/hyperledger/orderer/msp

  peer0.org1.example.com:
    image: hyperledger/fabric-peer:2.5
    environment:
      - CORE_PEER_ID=peer0.org1.example.com
      - CORE_PEER_ADDRESS=peer0.org1.example.com:7051
      - CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer0.org1.example.com:7051
      - CORE_PEER_GOSSIP_BOOTSTRAP=orderer.example.com:7050
    ports:
      - 7051:7051
    extra_hosts:
      - "orderer.example.com:AWS_IP"
      - "peer0.org2.example.com:GCP_IP"
    volumes:
      - ./crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/:/var/hyperledger/peer/msp

  cli:
    image: hyperledger/fabric-tools:2.5
    tty: true
    stdin_open: true
    extra_hosts:
      - "orderer.example.com:AWS_IP"
      - "peer0.org2.example.com:GCP_IP"
    volumes:
      - ./channel-artifacts:/opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts
      - ./crypto-config:/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/

```

**GCP docker-compose (gcp-docker-compose.yml)** — এখানে peer0.org2 এবং cli (ops) থাকবে; extra_hosts map করে AWS IP:

```yaml
version: '2'
services:
  peer0.org2.example.com:
    image: hyperledger/fabric-peer:2.5
    environment:
      - CORE_PEER_ID=peer0.org2.example.com
      - CORE_PEER_ADDRESS=peer0.org2.example.com:7051
      - CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer0.org2.example.com:7051
      - CORE_PEER_GOSSIP_BOOTSTRAP=orderer.example.com:7050
    ports:
      - 7051:7051
    extra_hosts:
      - "orderer.example.com:AWS_IP"
      - "peer0.org1.example.com:AWS_IP"
    volumes:
      - ./crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/:/var/hyperledger/peer/msp

  cli:
    image: hyperledger/fabric-tools:2.5
    tty: true
    stdin_open: true
    extra_hosts:
      - "orderer.example.com:AWS_IP"
      - "peer0.org1.example.com:AWS_IP"
    volumes:
      - ./channel-artifacts:/opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts
      - ./crypto-config:/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/

```

> নোট: এখানে AWS_IP ও GCP_IP তোমার প্রকৃত public IP দিয়ে REPLACE কর। extra_hosts ধরে নেয়া হচ্ছে hostnames public IP-এ রেজল্ভ হবে।
> 

---

## 5) Crypto ও channel artifacts সিঙ্ক করা (AWS → GCP)

AWS-এ যে `crypto-config/` ও `channel-artifacts/` তৈরি করেছো তা GCP-এ কপি করো। উদাহরণ SCP দিয়ে:

```bash
# From your local machine or AWS itself, push to GCP VM:
scp -r ./crypto-config ubuntu@GCP_IP:~/fabric-test/
scp -r ./channel-artifacts ubuntu@GCP_IP:~/fabric-test/
scp ~/fabric-test/aws-docker-compose.yml ubuntu@GCP_IP:~/fabric-test/gcp-docker-compose.yml

```

বা GCP থেকে pull করো (scp নেমতে):

```bash
# on GCP VM:
scp -r ubuntu@AWS_IP:~/fabric-test/crypto-config .
scp -r ubuntu@AWS_IP:~/fabric-test/channel-artifacts .

```

---

## 6) Start services — orderer + peer on AWS, peer on GCP

**AWS VM:**

```bash
cd ~/fabric-test
docker-compose -f aws-docker-compose.yml up -d
# check
docker ps

```

**GCP VM:**

```bash
cd ~/fabric-test
docker-compose -f gcp-docker-compose.yml up -d
docker ps

```

---

## 7) Channel creation & peers join (use CLI on AWS or one of the CLIs)

**A. Create channel (on AWS CLI container):**

1. Enter cli container (AWS):

```bash
docker exec -it <cli_container_name> bash

```

1. Create channel:

```bash
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
peer channel create -o orderer.example.com:7050 -c mychannel -f ./channel-artifacts/channel.tx

```

This will produce `mychannel.block`.

**B. Copy channel block to GCP (so GCP peer can join):**

```bash
# From AWS host: scp channel block to GCP
scp ./mychannel.block ubuntu@GCP_IP:~/fabric-test/channel-artifacts/

```

**C. Peer join on AWS (Org1) — using its CLI:**

```bash
peer channel join -b ./mychannel.block

```

**D. Peer join on GCP (Org2) — use CLI in GCP container:**

```bash
docker exec -it <gcp_cli_container> bash
# inside:
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
peer channel join -b ./channel-artifacts/mychannel.block

```

**E. Anchor peer updates:** apply anchor updates created earlier:

- On AWS (for Org1) and on GCP (for Org2) use `peer channel update -o orderer.example.com:7050 -c mychannel -f ./channel-artifacts/Org1MSPanchors.tx` and similarly for Org2 (run from respective org CLI with proper MSP env vars).

---

## 8) Chaincode install & instantiate (both peers)

Package chaincode on each org, install, approve, commit as normal Fabric lifecycle commands. Example streamlined:

On AWS (Org1 CLI):

```bash
peer lifecycle chaincode package mycc.tar.gz --path ./chaincode --lang node --label mycc_1
peer lifecycle chaincode install mycc.tar.gz
# get package ID, approve, commit steps...

```

On GCP (Org2 CLI) do same install, then from one org commit the chaincode, ensure commit succeeded.

(Full lifecycle commands are longer — follow Fabric docs for lifecycle install/approve/commit. Since both peers share channel, chaincode should be committed and ready.)

---

## 9) Verify connectivity & basic tests

- From GCP VM ping AWS orderer:

```bash
ping AWS_IP
telnet AWS_IP 7050   # check port open (install telnet)

```

- Check peer joined channels:

```bash
peer channel list
peer channel getinfo -c mychannel

```

- Tail logs:

```bash
docker logs -f peer0.org2.example.com
docker logs -f orderer.example.com

```

---

## 10) Run performance tests with Caliper (recommend running Caliper from AWS VM)

**Install Caliper (on AWS VM):**

```bash
npm install -g @hyperledger/caliper-cli
cd ~/fabric-test
# prepare caliper workspace (benchmark config, networkconfig.json referencing both peers)

```

**Network config note:** In Caliper network config, peers endpoints should use public IPs or hostnames that resolve (we used hostnames + extra_hosts). Example snippet of networkconfig.json endpoints:

```json
"peers": {
  "peer0.org1.example.com": { "url": "grpcs://peer0.org1.example.com:7051", ... },
  "peer0.org2.example.com": { "url": "grpcs://peer0.org2.example.com:7051", ... }
},
"orderers": {
  "orderer.example.com": { "url": "grpcs://orderer.example.com:7050", ... }
}

```

(If using TLS, include cert paths properly. For initial thesis simplified run you can disable TLS, but note security implications.)

**Run Caliper:**

```bash
npx caliper launch manager --caliper-workspace ./caliper --caliper-benchconfig benchmarks/benchmark.yaml --caliper-networkconfig networks/multicloud.json

```

Collect the generated report (JSON/HTML).

---

## 11) Metrics collection (simple)

Since you chose lightweight, use:

- `docker stats > results/docker_stats.log` (run during test)
- Caliper reports saved to results directory

If you want more: install Prometheus node_exporter + cAdvisor in each VM and scrape metrics.

---

## 12) Cleanup

After each test:

```bash
docker-compose -f aws-docker-compose.yml down
docker-compose -f gcp-docker-compose.yml down
# remove containers, images if needed

```