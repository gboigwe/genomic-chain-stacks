/**
 * WalletConnect Context for Stacks Blockchain
 *
 * This context provides WalletConnect integration using Reown infrastructure
 * for connecting Stacks wallets, signing transactions, and managing sessions.
 *
 * Features:
 * - QR Code wallet connection via Reown/WalletConnect
 * - Session management and persistence
 * - Transaction signing (STX transfers, contract calls, message signing)
 * - Support for Stacks mainnet and testnet
 */

import { createContext, useContext, useState, useEffect, useCallback } from 'react';
import Client from '@walletconnect/sign-client';
import { WalletConnectModal } from '@walletconnect/modal';

// WalletConnect Project ID - Get yours at https://cloud.walletconnect.com
const WALLETCONNECT_PROJECT_ID = import.meta.env.VITE_WALLETCONNECT_PROJECT_ID || 'YOUR_PROJECT_ID';

// Stacks chain IDs using CAIP-2 format
const STACKS_CHAINS = {
  mainnet: 'stacks:1',
  testnet: 'stacks:2147483648',
};

// Supported WalletConnect methods for Stacks
const STACKS_METHODS = [
  'stacks_signMessage',
  'stacks_stxTransfer',
  'stacks_contractCall',
  'stacks_contractDeploy',
];

// Create the wallet context
const WalletContext = createContext(null);

/**
 * Wallet Provider Component
 * Wraps the application to provide wallet connection functionality
 */
export const WalletProvider = ({ children }) => {
  const [client, setClient] = useState(null);
  const [session, setSession] = useState(null);
  const [accounts, setAccounts] = useState([]);
  const [chain, setChain] = useState(STACKS_CHAINS.mainnet);
  const [isConnecting, setIsConnecting] = useState(false);
  const [walletConnectModal, setWalletConnectModal] = useState(null);

  // Initialize WalletConnect client on mount
  useEffect(() => {
    initializeClient();
  }, []);

  // Restore session from storage
  useEffect(() => {
    if (client) {
      restoreSession();
    }
  }, [client]);

  /**
   * Initialize WalletConnect Sign Client
   */
  const initializeClient = async () => {
    try {
      const signClient = await Client.init({
        logger: 'debug',
        relayUrl: 'wss://relay.walletconnect.com',
        projectId: WALLETCONNECT_PROJECT_ID,
        metadata: {
          name: 'GenomicChain',
          description: 'Privacy-preserved genetic data marketplace on Stacks',
          url: window.location.origin,
          icons: [`${window.location.origin}/favicon.ico`],
        },
      });

      // Initialize WalletConnect Modal
      const modal = new WalletConnectModal({
        projectId: WALLETCONNECT_PROJECT_ID,
        chains: [STACKS_CHAINS.mainnet, STACKS_CHAINS.testnet],
      });

      setClient(signClient);
      setWalletConnectModal(modal);

      // Set up event listeners
      signClient.on('session_event', handleSessionEvent);
      signClient.on('session_update', handleSessionUpdate);
      signClient.on('session_delete', handleSessionDelete);
    } catch (error) {
      console.error('Failed to initialize WalletConnect client:', error);
    }
  };

  /**
   * Restore previous session if available
   */
  const restoreSession = useCallback(() => {
    if (!client) return;

    const lastSession = client.session.getAll().find((s) =>
      s.namespaces.stacks !== undefined
    );

    if (lastSession) {
      setSession(lastSession);
      updateAccounts(lastSession);
    }
  }, [client]);

  /**
   * Update accounts from session
   */
  const updateAccounts = (sess) => {
    if (!sess || !sess.namespaces.stacks) return;

    const stacksAccounts = sess.namespaces.stacks.accounts.map((account) => {
      // CAIP-10 format: "stacks:chainId:address"
      const parts = account.split(':');
      return {
        address: parts[2],
        chain: `${parts[0]}:${parts[1]}`,
      };
    });

    setAccounts(stacksAccounts);
  };

  /**
   * Connect wallet via QR code
   */
  const connect = async (chainType = 'mainnet') => {
    if (!client || isConnecting) return;

    setIsConnecting(true);
    const selectedChain = STACKS_CHAINS[chainType] || STACKS_CHAINS.mainnet;

    try {
      const { uri, approval } = await client.connect({
        pairingTopic: undefined,
        requiredNamespaces: {
          stacks: {
            methods: STACKS_METHODS,
            chains: [selectedChain],
            events: [],
          },
        },
      });

      // Open modal with QR code
      if (uri && walletConnectModal) {
        walletConnectModal.openModal({ uri });
      }

      // Wait for session approval
      const newSession = await approval();

      // Close modal
      if (walletConnectModal) {
        walletConnectModal.closeModal();
      }

      setSession(newSession);
      setChain(selectedChain);
      updateAccounts(newSession);
    } catch (error) {
      console.error('Failed to connect wallet:', error);
      if (walletConnectModal) {
        walletConnectModal.closeModal();
      }
    } finally {
      setIsConnecting(false);
    }
  };

  /**
   * Disconnect wallet
   */
  const disconnect = async () => {
    if (!client || !session) return;

    try {
      await client.disconnect({
        topic: session.topic,
        reason: {
          code: 6000,
          message: 'User disconnected',
        },
      });

      setSession(null);
      setAccounts([]);
    } catch (error) {
      console.error('Failed to disconnect:', error);
    }
  };

  /**
   * Sign a message
   */
  const signMessage = async (message) => {
    if (!client || !session || accounts.length === 0) {
      throw new Error('No active session');
    }

    try {
      const result = await client.request({
        chainId: chain,
        topic: session.topic,
        request: {
          method: 'stacks_signMessage',
          params: {
            pubkey: accounts[0].address,
            message,
          },
        },
      });

      return result;
    } catch (error) {
      console.error('Failed to sign message:', error);
      throw error;
    }
  };

  /**
   * Transfer STX tokens
   */
  const transferSTX = async (recipient, amount, memo = '') => {
    if (!client || !session || accounts.length === 0) {
      throw new Error('No active session');
    }

    try {
      // BigInt serialization workaround
      BigInt.prototype.toJSON = function() { return this.toString(); };

      const result = await client.request({
        chainId: chain,
        topic: session.topic,
        request: {
          method: 'stacks_stxTransfer',
          params: {
            pubkey: accounts[0].address,
            recipient,
            amount: BigInt(amount),
            memo: memo || undefined,
          },
        },
      });

      return result;
    } catch (error) {
      console.error('Failed to transfer STX:', error);
      throw error;
    }
  };

  /**
   * Call a smart contract function
   */
  const callContract = async ({
    contractAddress,
    contractName,
    functionName,
    functionArgs = [],
    postConditions = [],
    postConditionMode = 'Allow',
  }) => {
    if (!client || !session || accounts.length === 0) {
      throw new Error('No active session');
    }

    try {
      const result = await client.request({
        chainId: chain,
        topic: session.topic,
        request: {
          method: 'stacks_contractCall',
          params: {
            pubkey: accounts[0].address,
            contractAddress,
            contractName,
            functionName,
            functionArgs,
            postConditions,
            postConditionMode,
          },
        },
      });

      return result;
    } catch (error) {
      console.error('Failed to call contract:', error);
      throw error;
    }
  };

  /**
   * Deploy a smart contract
   */
  const deployContract = async (contractName, codeBody, postConditionMode = 'Allow') => {
    if (!client || !session || accounts.length === 0) {
      throw new Error('No active session');
    }

    try {
      const result = await client.request({
        chainId: chain,
        topic: session.topic,
        request: {
          method: 'stacks_contractDeploy',
          params: {
            pubkey: accounts[0].address,
            contractName,
            codeBody,
            postConditionMode,
          },
        },
      });

      return result;
    } catch (error) {
      console.error('Failed to deploy contract:', error);
      throw error;
    }
  };

  /**
   * Event handlers
   */
  const handleSessionEvent = (event) => {
    console.log('Session event:', event);
  };

  const handleSessionUpdate = ({ topic, params }) => {
    console.log('Session updated:', topic, params);
    const updatedSession = client.session.get(topic);
    setSession(updatedSession);
    updateAccounts(updatedSession);
  };

  const handleSessionDelete = () => {
    console.log('Session deleted');
    setSession(null);
    setAccounts([]);
  };

  // Context value
  const value = {
    // State
    isConnected: !!session && accounts.length > 0,
    isConnecting,
    address: accounts[0]?.address || null,
    accounts,
    chain,

    // Actions
    connect,
    disconnect,
    signMessage,
    transferSTX,
    callContract,
    deployContract,
  };

  return (
    <WalletContext.Provider value={value}>
      {children}
    </WalletContext.Provider>
  );
};

/**
 * Hook to use wallet context
 */
export const useWallet = () => {
  const context = useContext(WalletContext);

  if (!context) {
    throw new Error('useWallet must be used within WalletProvider');
  }

  return context;
};

export default WalletContext;
