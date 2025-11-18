ubuntu@ip-172-31-183-39:~/fabric_multi_aws$ ./fix-orderer-now.sh
========================================
  ORDERER FIX - DEEP DIAGNOSIS
========================================

[1/8] Checking for orderer container...
Orderer container found with status: exited
Orderer is NOT running. Checking why it exited...

=== ORDERER LOGS (Last 30 lines) ===
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
2025-11-18 00:53:22.915 UTC 0003 INFO [orderer.common.server] initializeServerConfig -> Starting orderer with TLS enabled
2025-11-18 00:53:22.939 UTC 0004 PANI [orderer.common.server] Main -> Failed validating bootstrap block: the block isn't a system channel block because it lacks ConsortiumsConfig
panic: Failed validating bootstrap block: the block isn't a system channel block because it lacks ConsortiumsConfig

goroutine 1 [running]:
go.uber.org/zap/zapcore.(*CheckedEntry).Write(0xc0000e9080, {0x0, 0x0, 0x0})
        /go/src/github.com/hyperledger/fabric/vendor/go.uber.org/zap/zapcore/entry.go:234 +0x49b
go.uber.org/zap.(*SugaredLogger).log(0xc0001288e0, 0x4, {0xf6f78e?, 0xf1?}, {0xc0000f7730?, 0xc000223368?, 0x1?}, {0x0, 0x0, 0x0})
        /go/src/github.com/hyperledger/fabric/vendor/go.uber.org/zap/sugar.go:234 +0x13b
go.uber.org/zap.(*SugaredLogger).Panicf(...)
        /go/src/github.com/hyperledger/fabric/vendor/go.uber.org/zap/sugar.go:159
github.com/hyperledger/fabric/common/flogging.(*FabricLogger).Panicf(...)
        /go/src/github.com/hyperledger/fabric/common/flogging/zap.go:74
github.com/hyperledger/fabric/orderer/common/server.Main()
        /go/src/github.com/hyperledger/fabric/orderer/common/server/main.go:130 +0x7a8
main.main()
        /go/src/github.com/hyperledger/fabric/cmd/orderer/main.go:15 +0x17
=== END LOGS ===

FOUND PANIC! Orderer is crashing.
panic: Failed validating bootstrap block: the block isn't a system channel block because it lacks ConsortiumsConfig

goroutine 1 [running]:
go.uber.org/zap/zapcore.(*CheckedEntry).Write(0xc0000e9080, {0x0, 0x0, 0x0})
        /go/src/github.com/hyperledger/fabric/vendor/go.uber.org/zap/zapcore/entry.go:234 +0x49b
go.uber.org/zap.(*SugaredLogger).log(0xc0001288e0, 0x4, {0xf6f78e?, 0xf1?}, {0xc0000f7730?, 0xc000223368?, 0x1?}, {0x0, 0x0, 0x0})

Removing failed orderer container...
orderer.example.com

[2/8] Checking genesis block...
✓ Genesis block is a file
-rw-r----- 1 ubuntu ubuntu 20K Nov 18 00:28 ./system-genesis-block/genesis.block

[3/8] Skipping genesis generation (already exists)

[4/8] Checking TLS certificates...
✓ Orderer TLS directory exists
✓ All TLS certificates found

[5/8] Checking MSP...
✓ Orderer MSP directory exists

[6/8] Checking docker-compose-aws.yml...
✓ docker-compose-aws.yml exists

[7/8] Starting orderer...
WARN[0000] /home/ubuntu/fabric_multi_aws/docker-compose-aws.yml: the attribute `version` is obsolete, it will be ignored, please remove it to avoid potential confusion
[+] Running 1/1
 ✔ Container orderer.example.com  Started                                                                                                                                                       0.4s
Waiting 8 seconds for orderer to initialize...

[8/8] Verifying orderer...

========================================
  ✗ ORDERER FAILED TO START
========================================

Checking if container exists but exited...
Orderer exited immediately. Check logs:
2025-11-18 04:32:42.430 UTC 0001 INFO [localconfig] completeInitialization -> Kafka.Version unset, setting to 0.10.2.0
2025-11-18 04:32:42.430 UTC 0002 INFO [orderer.common.server] prettyPrintStruct -> Orderer config values:
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
2025-11-18 04:32:42.433 UTC 0003 INFO [orderer.common.server] initializeServerConfig -> Starting orderer with TLS enabled
2025-11-18 04:32:42.457 UTC 0004 PANI [orderer.common.server] Main -> Failed validating bootstrap block: the block isn't a system channel block because it lacks ConsortiumsConfig
panic: Failed validating bootstrap block: the block isn't a system channel block because it lacks ConsortiumsConfig

goroutine 1 [running]:
go.uber.org/zap/zapcore.(*CheckedEntry).Write(0xc0004c9080, {0x0, 0x0, 0x0})
        /go/src/github.com/hyperledger/fabric/vendor/go.uber.org/zap/zapcore/entry.go:234 +0x49b
go.uber.org/zap.(*SugaredLogger).log(0xc000130780, 0x4, {0xf6f78e?, 0xf1?}, {0xc0001d9730?, 0xc0000d45b8?, 0x1?}, {0x0, 0x0, 0x0})
        /go/src/github.com/hyperledger/fabric/vendor/go.uber.org/zap/sugar.go:234 +0x13b
go.uber.org/zap.(*SugaredLogger).Panicf(...)
        /go/src/github.com/hyperledger/fabric/vendor/go.uber.org/zap/sugar.go:159
github.com/hyperledger/fabric/common/flogging.(*FabricLogger).Panicf(...)
        /go/src/github.com/hyperledger/fabric/common/flogging/zap.go:74
github.com/hyperledger/fabric/orderer/common/server.Main()
        /go/src/github.com/hyperledger/fabric/orderer/common/server/main.go:130 +0x7a8
main.main()
        /go/src/github.com/hyperledger/fabric/cmd/orderer/main.go:15 +0x17
ubuntu@ip-172-31-183-39:~/fabric_multi_aws$ ^C
ubuntu@ip-172-31-183-39:~/fabric_multi_aws$