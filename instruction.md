# 🔥 Next, you must generate artifacts (ONLY AWS)

## STEP A — Go inside AWS machine:

```
cd FABRIC-NETWORK
```

## STEP B — Start/END AWS docker (peer+orderer+cli):

```
docker-compose -f docker-compose-aws.yml up -d

docker-compose -f docker-compose-aws.yml down
```

## STEP C — Enter CLI:

```
docker exec -it cli bash
```

## STEP D — Generate genesis block:

```
configtxgen -profile TwoOrgsOrdererGenesis \
  -channelID system-channel \
  -outputBlock /etc/hyperledger/genesis/genesis.block

```

# 🔥 **NEXT STEP 1 — Generate Channel Creation Transaction (channel.tx)**

Still inside CLI container:

```
configtxgen -profile TwoOrgsChannel \
  -channelID mychannel \
  -outputCreateChannelTx ./channel-artifacts/channel.tx

```

This must produce:

```
./channel-artifacts/channel.tx

```

---

# 🔥 **NEXT STEP 2 — Generate Anchor Peer Updates**

## Org1 Anchor Update

```
configtxgen -profile TwoOrgsChannel \
  -channelID mychannel \
  -asOrg Org1MSP \
  -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx

```

## Org2 Anchor Update

```
configtxgen -profile TwoOrgsChannel \
  -channelID mychannel \
  -asOrg Org2MSP \
  -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx

```

---

# 🔥 **NEXT STEP 3 — Create Channel (AWS only)**

Exit CLI and re-enter with the correct environment for Org1:

```
docker exec -it cli bash

```

Set environment for Org1:

```
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051

```

Create channel:

```
peer channel create \
  -o orderer.example.com:7050 \
  -c mychannel \
  -f ./channel-artifacts/channel.tx

```

This will create:

```
mychannel.block

```

Copy that to host:

```
cp mychannel.block ./channel-artifacts/

```

---

# 🔥 **NEXT STEP 4 — Join Org1 Peer (AWS)**

```
peer channel join -b ./channel-artifacts/mychannel.block

```

---

# 🔥 **NEXT STEP 5 — Copy mychannel.block to GCP**

Exit container:

```
exit

```

Now from AWS host:

```
scp ./channel-artifacts/mychannel.block ubuntu@72.61.113.7:~/fabric-network/channel-artifacts/

```

---

# 🔥 **NEXT STEP 6 — Join Org2 Peer (GCP)**

On GCP:

```
docker exec -it cli_org2 bash

```

Set Org2 ENV:

```
export CORE_PEER_LOCALMSPID=Org2MSP
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=peer0.org2.example.com:7051

```

Join:

```
peer channel join -b ./channel-artifacts/mychannel.block

```

---

# 🔥 **NEXT STEP 7 — Update Anchor Peers**

## Org1 (AWS)

```
peer channel update -o orderer.example.com:7050 \
 -c mychannel \
 -f ./channel-artifacts/Org1MSPanchors.tx

```

## Org2 (GCP)

```
peer channel update -o orderer.example.com:7050 \
 -c mychannel \
 -f ./channel-artifacts/Org2MSPanchors.tx

```

---

# 🔥 **NEXT STEP 8 — Chaincode Lifecycle (Install → Approve → Commit)**

If you want, I can generate chaincode commands too.

Just tell me:

➡️ What is your chaincode name?

➡️ Is it Go / TypeScript / JavaScript?

➡️ Chaincode folder path (looks like `/chaincode/asset-transfer`?)

I will generate all commands ready to copy.

---