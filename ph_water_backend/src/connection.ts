import * as grpc from "@grpc/grpc-js";
import {
  connect,
  Contract,
  hash,
  Identity,
  Signer,
  signers,
} from "@hyperledger/fabric-gateway";
import * as crypto from "crypto";
import { promises as fs } from "fs";
import * as path from "path";

// Environment variables with defaults
const channelName = process.env.CHANNEL_NAME || "mychannel";
const chaincodeName = process.env.CHAINCODE_NAME || "SensorContract";
const mspId = process.env.MSP_ID || "Org1MSP";

// Local Fabric crypto materials path
const FABRIC_CRYPTO = path.resolve(
  __dirname,
  "../../fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp"
);
const keyPath = path.join(FABRIC_CRYPTO, "keystore", "priv_sk"); // Ensure the correct key file
const certPath = path.join(
  FABRIC_CRYPTO,
  "signcerts",
  "User1@org1.example.com-cert.pem"
);
const tlsCertPath = path.resolve(
  __dirname,
  "../../fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem"
);

// Local peer configuration
const peerEndpoint = "localhost:7051"; // Local peer
const peerHostAlias = "peer0.org1.example.com";

let contractInstance: Contract | null = null;

// Initialize Fabric connection
export async function initFabric(): Promise<Contract> {
  if (contractInstance) return contractInstance; // Return if already initialized

  const client = await newGrpcConnection();
  const gateway = connect({
    client,
    identity: await newIdentity(),
    signer: await newSigner(),
    hash: hash.sha256,
    evaluateOptions: () => ({ deadline: Date.now() + 150000 }),
    endorseOptions: () => ({ deadline: Date.now() + 150000 }),
    submitOptions: () => ({ deadline: Date.now() + 150000 }),
    commitStatusOptions: () => ({ deadline: Date.now() + 60000 }),
  });

  try {
    const network = gateway.getNetwork(channelName);
    contractInstance = network.getContract(chaincodeName);
    console.log("Hyperledger Fabric contract initialized successfully.");
    return contractInstance;
  } catch (error) {
    console.error("Error initializing Fabric contract:", error);
    throw error;
  }
}

// gRPC connection setup
async function newGrpcConnection(): Promise<grpc.Client> {
  const tlsRootCert = await fs.readFile(tlsCertPath);
  const tlsCredentials = grpc.credentials.createSsl(tlsRootCert);
  return new grpc.Client(peerEndpoint, tlsCredentials, {
    "grpc.ssl_target_name_override": peerHostAlias,
  });
}

// Load user identity
async function newIdentity(): Promise<Identity> {
  const credentials = await fs.readFile(certPath);
  return { mspId, credentials };
}

// Load signer from private key
async function newSigner(): Promise<Signer> {
  const privateKeyPem = await fs.readFile(keyPath);
  const privateKey = crypto.createPrivateKey(privateKeyPem);
  return signers.newPrivateKeySigner(privateKey);
}

// Export contract instance
export function getContract(): Contract {
  if (!contractInstance)
    throw new Error("Fabric contract not initialized yet.");
  return contractInstance;
}
