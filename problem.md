
Successfully copied 20.2kB to /home/ubuntu/fabric_multi_aws/system-genesis-block/genesis.block
open /home/ubuntu/fabric_multi_aws/system-genesis-block/genesis.block/genesis.block: permission denied
ubuntu@ip-172-31-183-39:~/fabric_multi_aws$ docker ps
CONTAINER ID   IMAGE                          COMMAND             CREATED          STATUS          PORTS                                                                                      NAMES
49d452d9b0d9   hyperledger/fabric-tools:2.4   "/bin/sh"           24 seconds ago   Up 23 seconds                                                                                              cli
ca4ee436544a   hyperledger/fabric-peer:2.4    "peer node start"   24 seconds ago   Up 23 seconds   0.0.0.0:7051->7051/tcp, [::]:7051->7051/tcp, 0.0.0.0:9444->9444/tcp, [::]:9444->9444/tcp   peer0.org1.example.com
ubuntu@ip-172-31-183-39:~/fabric_multi_aws$ docker ps | grep orderer
ubuntu@ip-172-31-183-39:~/fabric_multi_aws$ ./diagnose.sh
========================================
  Fabric Network Diagnostic Tool
========================================

Detected Location: AWS

[1/10] Checking Docker installation...
✓ Docker is installed
Docker version 29.0.1, build eedd969

[2/10] Checking Docker Compose...
✓ Docker Compose is installed
Docker Compose version v2.40.3

[3/10] Checking running containers...
✓ Containers found:
NAMES                    STATUS              PORTS
cli                      Up About a minute
peer0.org1.example.com   Up About a minute   0.0.0.0:7051->7051/tcp, [::]:7051->7051/tcp, 0.0.0.0:9444->9444/tcp, [::]:9444->9444/tcp

[4/10] Checking orderer status...
✗ Orderer container not found

[5/10] Checking peer status...
✓ Peer peer0.org1.example.com is running

[6/10] Checking CLI container...
✓ CLI container is running

[7/10] Checking crypto materials...
✓ Crypto materials found
  ✓ Orderer TLS certificates found
  ✓ Org1 Peer TLS certificates found

[8/10] Checking channel artifacts...
✓ Channel artifacts directory exists
  ✗ channel.tx missing
  ✓ mychannel.block found

[9/10] Checking genesis block...
✗ Genesis block not found

[10/10] Checking if peer has joined channel...
⚠ Peer has not joined mychannel yet
Available channels:
Error: error getting endorser client for channel: endorser client failed to connect to 0.0.0.0:7051: failed to create new connection: connection error: desc = "transport: error while dialing: dial tcp 0.0.0.0:7051: connect: connection refused"

========================================
  Network Connectivity
========================================

Testing connection to GCP peer (178.16.139.239)...
✓ Can reach GCP peer IP

========================================
  Diagnostic Summary
========================================

Next Steps:
1. If orderer is not running: Check logs with docker logs orderer.example.com
2. If channel not created: Run ./create-channel-aws.sh
3. View logs: docker logs -f peer0.org1.example.com

Useful Commands:
View all containers: docker ps -a
View networks: docker network ls
View volumes: docker volume ls
Restart network: docker-compose -f docker-compose-aws.yml restart

========================================
  Diagnostic Complete
========================================