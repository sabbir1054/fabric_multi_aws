Successfully copied 20.2kB to /home/ubuntu/fabric_multi_aws/system-genesis-block/
cannot overwrite directory "/home/ubuntu/fabric_multi_aws/system-genesis-block/genesis.block" with non-directory "/home/ubuntu/fabric_multi_aws/system-genesis-block"
ubuntu@ip-172-31-183-39:~/fabric_multi_aws$ ./create-channel-aws.sh
========================================
  Create Channel & Join Org1 Peer
========================================

[1/3] Creating channel 'mychannel'...
Error: failed to create deliver client for orderer: orderer client failed to connect to orderer.example.com:7050: failed to create new connection: connection error: desc = "transport: error while dialing: dial tcp: lookup orderer.example.com: no such host"

e dialing: dial tcp: lookup orderer.example.com: no such host"
ubuntu@ip-172-31-183-39:~/fabric_multi_aws$ docker ps -a
CONTAINER ID   IMAGE                            COMMAND             CREATED              STATUS                          PORTS                                                                                      NAMES
d6da2747b69b   hyperledger/fabric-tools:2.4     "/bin/sh"           About a minute ago   Up About a minute                                                                                                          cli
9b68dc67bb6f   hyperledger/fabric-peer:2.4      "peer node start"   About a minute ago   Up About a minute               0.0.0.0:7051->7051/tcp, [::]:7051->7051/tcp, 0.0.0.0:7053->7053/tcp, [::]:7053->7053/tcp   peer0.org1.example.com
a81549765696   hyperledger/fabric-orderer:2.4   "orderer"           About a minute ago   Exited (2) About a minute ago                          