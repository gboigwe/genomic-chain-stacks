# GenomicChain Phase 2: ZK Implementation & Storage

This directory contains the Phase 2 implementation of GenomicChain, which provides zero-knowledge proof generation, IPFS storage, and blockchain contract integration for genetic data.

## 🏗️ Architecture Overview

Phase 2 implements the core privacy-preserving infrastructure:

- **ZK Proofs**: Zero-knowledge proof generation and verification for genetic data
- **Storage**: Encrypted IPFS storage with multi-tier access control
- **Contract Integration**: JavaScript clients for all Clarity smart contracts
- **Utilities**: Cryptographic and data formatting utilities

## 📁 Directory Structure

```
src/
├── zk-proofs/
│   ├── generators/          # ZK proof generators
│   ├── verifiers/          # Proof verification
│   ├── utils/              # Proof utilities
│   └── index.js           # ZK proofs entry point
├── storage/
│   ├── ipfs-client.js     # IPFS integration
│   ├── encryption.js      # Multi-tier encryption
│   ├── storage-manager.js # Storage orchestration
│   └── index.js          # Storage entry point
├── contract-integration/
│   ├── genetic-data-client.js    # Genetic data contract client
│   ├── verification-client.js    # Verification contract client
│   ├── marketplace-client.js     # Marketplace contract client
│   ├── compliance-client.js      # Compliance contract client
│   └── index.js                 # Contracts entry point
├── utils/
│   ├── crypto-utils.js    # Cryptographic utilities
│   ├── data-formatter.js  # Data format conversion
│   └── index.js          # Utils entry point
├── config/
│   └── phase2-config.js   # Configuration management
└── main.js               # Main SDK entry point
```

## 🚀 Quick Start

### Installation

```bash
# Install dependencies
npm install

# Install additional Phase 2 dependencies
npm install ipfs-http-client buffer crypto-browserify
```

### Basic Usage

```javascript
import GenomicChain from './src/main.js';
import { Phase2Config } from './src/config/phase2-config.js';

// Initialize SDK
const config = Phase2Config.forEnvironment('development');
const genomicChain = GenomicChain.create({ config });

// Initialize with Stacks API and contract addresses
await genomicChain.initialize(stacksApi, contractAddresses);

// Store genetic data with encryption and proofs
const result = await genomicChain.storeGeneticData(
    geneticData,
    password,
    {
        generateProofs: true,
        proofs: {
            genePresence: [{ targetGene: 'BRCA1' }],
            variants: [{ targetVariant: { gene: 'BRCA1', type: 'SNP' } }]
        }
    }
);

// Retrieve and decrypt data
const retrieved = await genomicChain.retrieveGeneticData(
    result.datasetId,
    password,
    2 // Access level
);
```

## 🔐 Zero-Knowledge Proofs

### Supported Proof Types

1. **Gene Presence Proofs**: Prove a specific gene exists without revealing the full genome
2. **Gene Variant Proofs**: Prove specific genetic variants without exposing other variants
3. **Aggregate Proofs**: Prove statistical properties without revealing individual data points

### Generating Proofs

```javascript
import { ZKProofFactory } from './src/zk-proofs/index.js';

// Create proof generator
const generator = ZKProofFactory.createGenerator('gene-presence');

// Generate proof
const proof = await generator.generatePresenceProof(
    geneticData,
    'BRCA1',
    { privacyLevel: 'high' }
);

// Verify proof
const verifier = ZKProofFactory.createVerifier();
const isValid = await verifier.verifyProof(proof, { targetGene: 'BRCA1' });
```

## 💾 Storage System

### IPFS Integration

```javascript
import { StorageFactory } from './src/storage/index.js';

// Create storage manager
const storage = StorageFactory.createStorageManager({
    ipfs: { host: 'localhost', port: 5001 },
    encryption: { algorithm: 'aes-256-gcm' }
});

// Store encrypted data
const result = await storage.storeGeneticData(
    geneticData,
    password,
    { compressionEnabled: true }
);

// Retrieve data
const retrieved = await storage.retrieveGeneticData(
    result.storageUrl,
    password,
    2 // Access level
);
```

### Multi-Tier Encryption

The storage system supports three access levels:

- **Level 1**: Basic metadata and aggregate statistics
- **Level 2**: Partial data with filtered information
- **Level 3**: Full access to all genetic information

Each level uses different encryption keys and algorithms for granular access control.

## 🔗 Contract Integration

### Genetic Data Contract

```javascript
import { ContractFactory } from './src/contract-integration/index.js';

const contracts = ContractFactory.create(contractConfig, stacksApi);
const geneticDataClient = contracts.createGeneticDataClient();

// Register genetic data
await geneticDataClient.registerGeneticData({
    dataId: 12345,
    price: 1000000,
    accessLevel: 3,
    metadataHash: metadataHash,
    storageUrl: 'ipfs://...',
    description: 'High-quality genomic data'
}, senderAddress);
```

### Marketplace Contract

```javascript
const marketplaceClient = contracts.createMarketplaceClient();

// Create listing
await marketplaceClient.createListing({
    listingId: 67890,
    price: 2000000,
    dataContract: geneticDataContract,
    dataId: 12345,
    accessLevel: 3,
    requiresVerification: true
}, sellerAddress);

// Purchase data
await marketplaceClient.purchaseListingDirect(
    67890,
    2, // Access level
    txId,
    buyerAddress
);
```

### Verification Contract

```javascript
const verificationClient = contracts.createVerificationClient();

// Register proof
await verificationClient.registerProof({
    dataId: 12345,
    proofType: 1, // Gene presence
    proofHash: proofHashBuffer,
    parameters: proofParametersBuffer
}, senderAddress);

// Verify proof
await verificationClient.verifyProof(
    proofId,
    verifierId,
    verificationTxId,
    verifierAddress
);
```

### Compliance Contract

```javascript
const complianceClient = contracts.createComplianceClient();

// Register consent
await complianceClient.registerConsent({
    dataId: 12345,
    researchConsent: true,
    commercialConsent: false,
    clinicalConsent: true,
    jurisdiction: 2, // EU (GDPR)
    consentDuration: 8640 // ~30 days
}, dataOwnerAddress);

// Check consent validity
const isValid = await complianceClient.checkConsentValidity(
    12345,
    1 // Research purpose
);
```

## 🛠️ Utilities

### Cryptographic Utilities

```javascript
import { CryptoUtils } from './src/utils/crypto-utils.js';

// Generate secure keys
const key = CryptoUtils.generateSecureKey(32);

// Create data fingerprints
const fingerprint = CryptoUtils.createDataFingerprint(geneticData);

// Generate HMACs
const hmac = CryptoUtils.generateHMAC(data, key);
```

### Data Formatting

```javascript
import { DataFormatter } from './src/utils/data-formatter.js';

// Convert to VCF format
const vcf = DataFormatter.toVCF(geneticData);

// Parse VCF data
const parsed = DataFormatter.fromVCF(vcfContent);

// Format for contracts
const contractData = DataFormatter.formatForContract(data, 'marketplace');
```

## ⚙️ Configuration

### Environment Configuration

```javascript
import { Phase2Config } from './src/config/phase2-config.js';

// Create environment-specific config
const config = Phase2Config.forEnvironment('production');

// Get component configuration
const ipfsConfig = config.getIPFSConfig();
const zkConfig = config.getZKProofConfig();

// Update configuration
config.updateConfig('ipfs', { host: 'my-ipfs-node.com' });
```

### Configuration Options

- **Development**: Relaxed security, debug logging, local IPFS
- **Testing**: Fast operations, in-memory storage, minimal security
- **Staging**: Production-like with test networks
- **Production**: Full security, monitoring, mainnet contracts

## 🧪 Testing

```bash
# Run all tests
npm test

# Run Phase 2 specific tests
npm run test:phase2

# Run with coverage
npm run test:report
```

## 📋 Examples

See `examples/basic-usage.js` for comprehensive usage examples including:

- Data storage and retrieval
- Proof generation and verification
- Marketplace interactions
- Compliance management
- Batch operations

```bash
# Run the example
node examples/basic-usage.js
```

## 🔧 Development

### Adding New Proof Types

1. Create a new generator in `src/zk-proofs/generators/`
2. Implement the required interface methods
3. Add proof type constants to contracts
4. Update the `ZKProofFactory`

### Extending Storage

1. Add new storage backends in `src/storage/`
2. Implement the storage interface
3. Update `StorageManager` to support new backends

### Adding Contract Clients

1. Create client in `src/contract-integration/`
2. Implement contract interaction methods
3. Add to `ContractFactory`

## 🚨 Security Considerations

- **Private Keys**: Never log or expose private keys
- **Passwords**: Use strong passwords for encryption
- **Proof Verification**: Always verify proofs before trusting results
- **Contract Calls**: Validate all contract parameters
- **IPFS Security**: Use private IPFS networks for sensitive data

## 📚 Documentation

- [ZK Proofs Documentation](./docs/zk-proofs.md)
- [Storage System Documentation](./docs/storage.md)
- [Contract Integration Guide](./docs/contracts.md)
- [Configuration Reference](./docs/configuration.md)

## 🐛 Troubleshooting

### Common Issues

1. **IPFS Connection Failed**
   - Check IPFS node is running
   - Verify host/port configuration
   - Check firewall settings

2. **Proof Generation Slow**
   - Reduce data size for testing
   - Adjust timeout settings
   - Use development environment

3. **Contract Call Failed**
   - Verify contract addresses
   - Check network configuration
   - Ensure sufficient STX balance

4. **Decryption Failed**
   - Verify password is correct
   - Check data integrity
   - Ensure access level permissions

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Implement changes with tests
4. Update documentation
5. Submit pull request

## 📄 License

MIT License - see LICENSE file for details.

---

🧬 **GenomicChain Phase 2** - Privacy-preserving genetic data infrastructure for the decentralized web.
