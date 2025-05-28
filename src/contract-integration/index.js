// Main export file for contract integration components
// Provides unified interface for all blockchain contract interactions

export { GeneticDataClient } from './genetic-data-client.js';
export { VerificationClient } from './verification-client.js';
export { MarketplaceClient } from './marketplace-client.js';
export { ComplianceClient } from './compliance-client.js';

/**
 * Contract Factory - Unified interface for creating contract clients
 */
export class ContractFactory {
    constructor(contractAddresses, stacksApi) {
        this.contractAddresses = contractAddresses;
        this.stacksApi = stacksApi;
    }

    /**
     * Create a genetic data contract client
     * @returns {GeneticDataClient} Genetic data client instance
     */
    createGeneticDataClient() {
        return new GeneticDataClient(
            this.contractAddresses.geneticData.address,
            this.contractAddresses.geneticData.name,
            this.stacksApi
        );
    }

    /**
     * Create a verification contract client
     * @returns {VerificationClient} Verification client instance
     */
    createVerificationClient() {
        return new VerificationClient(
            this.contractAddresses.verification.address,
            this.contractAddresses.verification.name,
            this.stacksApi
        );
    }

    /**
     * Create a marketplace contract client
     * @returns {MarketplaceClient} Marketplace client instance
     */
    createMarketplaceClient() {
        return new MarketplaceClient(
            this.contractAddresses.marketplace.address,
            this.contractAddresses.marketplace.name,
            this.stacksApi
        );
    }

    /**
     * Create a compliance contract client
     * @returns {ComplianceClient} Compliance client instance
     */
    createComplianceClient() {
        return new ComplianceClient(
            this.contractAddresses.compliance.address,
            this.contractAddresses.compliance.name,
            this.stacksApi
        );
    }

    /**
     * Create all contract clients
     * @returns {Object} All contract clients
     */
    createAllClients() {
        return {
            geneticData: this.createGeneticDataClient(),
            verification: this.createVerificationClient(),
            marketplace: this.createMarketplaceClient(),
            compliance: this.createComplianceClient()
        };
    }

    /**
     * Static factory method for creating contract factory
     * @param {Object} config - Contract configuration
     * @param {Object} stacksApi - Stacks API instance
     * @returns {ContractFactory} Contract factory instance
     */
    static create(config, stacksApi) {
        return new ContractFactory(config.addresses, stacksApi);
    }
}
