Next Steps:
1. Run './create-channel-aws.sh' to create the channel
2. Copy artifacts to GCP using './copy-to-gcp.sh'
3. Run setup on GCP side

To view logs:
docker logs -f orderer.example.com
docker logs -f peer0.org1.example.com
ubuntu@ip-172-31-183-39:~/fabric_multi_aws$ docker ps | grep orderer
ubuntu@ip-172-31-183-39:~/fabric_multi_aws$ docker logs -f orderer.example.com
2025-11-17 09:54:07.467 UTC 0001 INFO [localconfig] completeInitialization -> Kafka.Version unset, setting to 0.10.2.0
2025-11-17 09:54:07.467 UTC 0002 INFO [orderer.common.server] prettyPrintStruct -> Orderer config values:
        General.ListenAddress = "0.0.0.0"
        General.ListenPort = 7050
        General.TLS.Enabled = true
        General.TLS.PrivateKey = "/var/hyperledger/orderer/tls/server.key"
        General.TLS.Certificate = "/var/hyperledger/orderer/tls/server.crt"
        General.TLS.RootCAs = [/var/hyperledger/orderer/tls/ca.crt]
        General.TLS.ClientAuthRequired = false
        General.TLS.ClientRootCAs = []
        General.TLS.TLSHandshakeTimeShift = 0s
        General.Cluster.ListenAddress = ""
        General.Cluster.ListenPort = 0
        General.Cluster.ServerCertificate = ""
        General.Cluster.ServerPrivateKey = ""
        General.Cluster.ClientCertificate = "/var/hyperledger/orderer/tls/server.crt"
        General.Cluster.ClientPrivateKey = "/var/hyperledger/orderer/tls/server.key"
        General.Cluster.RootCAs = [/var/hyperledger/orderer/tls/ca.crt]
        General.Cluster.DialTimeout = 5s
        General.Cluster.RPCTimeout = 7s
        General.Cluster.ReplicationBufferSize = 20971520
        General.Cluster.ReplicationPullTimeout = 5s
        General.Cluster.ReplicationRetryTimeout = 5s
        General.Cluster.ReplicationBackgroundRefreshInterval = 5m0s
        General.Cluster.ReplicationMaxRetries = 12
        General.Cluster.SendBufferSize = 10
        General.Cluster.CertExpirationWarningThreshold = 168h0m0s
        General.Cluster.TLSHandshakeTimeShift = 0s
        General.Keepalive.ServerMinInterval = 1m0s
        General.Keepalive.ServerInterval = 2h0m0s
        General.Keepalive.ServerTimeout = 20s
        General.ConnectionTimeout = 0s
        General.GenesisMethod = ""
        General.GenesisFile = ""
        General.BootstrapMethod = "file"
        General.BootstrapFile = "/var/hyperledger/orderer/orderer.genesis.block"
        General.Profile.Enabled = false
        General.Profile.Address = "0.0.0.0:6060"
        General.LocalMSPDir = "/var/hyperledger/orderer/msp"
        General.LocalMSPID = "OrdererMSP"
        General.BCCSP.Default = "SW"
        General.BCCSP.SW.Security = 256
        General.BCCSP.SW.Hash = "SHA2"
        General.BCCSP.SW.FileKeystore.KeyStorePath = ""
        General.Authentication.TimeWindow = 15m0s
        General.Authentication.NoExpirationChecks = false
        General.MaxRecvMsgSize = 104857600
        General.MaxSendMsgSize = 104857600
        FileLedger.Location = "/var/hyperledger/production/orderer"
        FileLedger.Prefix = ""
        Kafka.Retry.ShortInterval = 5s
        Kafka.Retry.ShortTotal = 10m0s
        Kafka.Retry.LongInterval = 5m0s
        Kafka.Retry.LongTotal = 12h0m0s
        Kafka.Retry.NetworkTimeouts.DialTimeout = 10s
        Kafka.Retry.NetworkTimeouts.ReadTimeout = 10s
        Kafka.Retry.NetworkTimeouts.WriteTimeout = 10s
        Kafka.Retry.Metadata.RetryMax = 3
        Kafka.Retry.Metadata.RetryBackoff = 250ms
        Kafka.Retry.Producer.RetryMax = 3
        Kafka.Retry.Producer.RetryBackoff = 100ms
        Kafka.Retry.Consumer.RetryBackoff = 2s
        Kafka.Verbose = false
        Kafka.Version = 0.10.2.0
        Kafka.TLS.Enabled = false
        Kafka.TLS.PrivateKey = ""
        Kafka.TLS.Certificate = ""
        Kafka.TLS.RootCAs = []
        Kafka.TLS.ClientAuthRequired = false
        Kafka.TLS.ClientRootCAs = []
        Kafka.TLS.TLSHandshakeTimeShift = 0s
        Kafka.SASLPlain.Enabled = false
        Kafka.SASLPlain.User = ""
        Kafka.SASLPlain.Password = ""
        Kafka.Topic.ReplicationFactor = 3
        Debug.BroadcastTraceDir = ""
        Debug.DeliverTraceDir = ""
        Consensus = map[SnapDir:/var/hyperledger/production/orderer/etcdraft/snapshot WALDir:/var/hyperledger/production/orderer/etcdraft/wal]
        Operations.ListenAddress = "orderer.example.com:9443"
        Operations.TLS.Enabled = false
        Operations.TLS.PrivateKey = ""
        Operations.TLS.Certificate = ""
        Operations.TLS.RootCAs = []
        Operations.TLS.ClientAuthRequired = false
        Operations.TLS.ClientRootCAs = []
        Operations.TLS.TLSHandshakeTimeShift = 0s
        Metrics.Provider = "prometheus"
        Metrics.Statsd.Network = "udp"
        Metrics.Statsd.Address = "127.0.0.1:8125"
        Metrics.Statsd.WriteInterval = 30s
        Metrics.Statsd.Prefix = ""
        ChannelParticipation.Enabled = true
        ChannelParticipation.MaxRequestBodySize = 1048576
        Admin.ListenAddress = "0.0.0.0:7053"
        Admin.TLS.Enabled = true
        Admin.TLS.PrivateKey = "/var/hyperledger/orderer/tls/server.key"
        Admin.TLS.Certificate = "/var/hyperledger/orderer/tls/server.crt"
        Admin.TLS.RootCAs = [/var/hyperledger/orderer/tls/ca.crt]
        Admin.TLS.ClientAuthRequired = true
        Admin.TLS.ClientRootCAs = [/var/hyperledger/orderer/tls/ca.crt]
        Admin.TLS.TLSHandshakeTimeShift = 0s
2025-11-17 09:54:07.471 UTC 0003 INFO [orderer.common.server] initializeServerConfig -> Starting orderer with TLS enabled
2025-11-17 09:54:07.491 UTC 0004 INFO [blkstorage] NewProvider -> Creating new file ledger directory at /var/hyperledger/production/orderer/chains
panic: unable to bootstrap orderer. Error reading genesis block file: read /var/hyperledger/orderer/orderer.genesis.block: is a directory

goroutine 1 [running]:
github.com/hyperledger/fabric/orderer/common/bootstrap/file.(*fileBootstrapper).GenesisBlock(0x0?)
        /go/src/github.com/hyperledger/fabric/orderer/common/bootstrap/file/bootstrap.go:39 +0x113
github.com/hyperledger/fabric/orderer/common/server.Main()
        /go/src/github.com/hyperledger/fabric/orderer/common/server/main.go:128 +0x725
main.main()
        /go/src/github.com/hyperledger/fabric/cmd/orderer/main.go:15 +0x17
ubuntu@ip-172-31-183-39:~/fabric_multi_aws$ ./create-channel-aws.sh
========================================
  Create Channel & Join Org1 Peer
========================================

[1/3] Creating channel 'mychannel'...
Error: failed to create deliver client for orderer: orderer client failed to connect to orderer.example.com:7050: failed to create new connection: connection error: desc = "transport: error while dialing: dial tcp: lookup orderer.example.com: no such host"
ubuntu@ip-172-31-183-39:~/fabric_multi_aws$