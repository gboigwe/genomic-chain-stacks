// Main navigation component for GenomicChain landing page

import React, { useState } from 'react';

/**
 * Navigation Component
 * Top navigation bar with GenomicChain branding and menu items
 * Includes Connect Wallet integration for Stacks blockchain
 */
const Navigation = () => {
  const [isWalletConnected, setIsWalletConnected] = useState(false);
  const [walletAddress, setWalletAddress] = useState('');

  // Navigation menu items from design
  const menuItems = [
    { label: 'About', href: '#about' },
    { label: 'How it works', href: '#how-it-works' },
    { label: 'Tokenomics', href: '#tokenomics' },
    { label: 'For Researchers', href: '#researchers' },
    { label: 'Dashboard', href: '#dashboard' }
  ];

  // Connect wallet function (Stacks integration)
  const handleConnectWallet = async () => {
    try {
      // TODO: Integrate with @stacks/connect
      // For now, simulate connection
      if (!isWalletConnected) {
        // Simulate wallet connection
        setIsWalletConnected(true);
        setWalletAddress('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM');
      } else {
        // Disconnect wallet
        setIsWalletConnected(false);
        setWalletAddress('');
      }
    } catch (error) {
      console.error('Wallet connection error:', error);
    }
  };

  // Format wallet address for display
  const formatAddress = (address) => {
    if (!address) return '';
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
  };

  return (
    <nav className="relative z-50 bg-[#0F192D]/90 backdrop-blur-lg border-b border-[#2DD4BF]/10">
      <div className="max-w-7xl mx-auto px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <div className="flex items-center">
            <div className="flex-shrink-0">
              <h1 className="text-xl font-bold text-white">
                <span className="text-[#2DD4BF]">Genomic</span>Chain
              </h1>
            </div>
          </div>

          {/* Desktop Navigation Menu */}
          <div className="hidden md:block">
            <div className="ml-10 flex items-baseline space-x-8">
              {menuItems.map((item) => (
                <a
                  key={item.label}
                  href={item.href}
                  className="text-gray-300 hover:text-[#2DD4BF] px-3 py-2 text-sm font-medium transition-colors duration-200 hover:bg-[#2DD4BF]/5 rounded-lg"
                >
                  {item.label}
                </a>
              ))}
            </div>
          </div>

          {/* Connect Wallet Button */}
          <div className="flex items-center space-x-4">
            <button
              onClick={handleConnectWallet}
              className={`
                px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200 
                ${isWalletConnected 
                  ? 'bg-[#37A36B] hover:bg-[#37A36B]/80 text-white border border-[#37A36B]' 
                  : 'bg-[#5594E0] hover:bg-[#5594E0]/80 text-white border border-[#5594E0]'
                }
                hover:shadow-lg hover:shadow-[#5594E0]/25 transform hover:scale-105
              `}
            >
              {isWalletConnected ? (
                <span className="flex items-center space-x-2">
                  <div className="w-2 h-2 bg-[#2DD4BF] rounded-full animate-pulse" />
                  <span>{formatAddress(walletAddress)}</span>
                </span>
              ) : (
                'Connect Wallet'
              )}
            </button>
          </div>

          {/* Mobile menu button */}
          <div className="md:hidden">
            <button
              type="button"
              className="bg-[#121F40] inline-flex items-center justify-center p-2 rounded-md text-gray-400 hover:text-white hover:bg-[#2DD4BF]/10 transition-colors duration-200"
              aria-controls="mobile-menu"
              aria-expanded="false"
            >
              <span className="sr-only">Open main menu</span>
              {/* Hamburger icon */}
              <svg className="block h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
              </svg>
            </button>
          </div>
        </div>
      </div>

      {/* Mobile menu - TODO: Add mobile menu state management */}
      <div className="md:hidden" id="mobile-menu" style={{ display: 'none' }}>
        <div className="px-2 pt-2 pb-3 space-y-1 bg-[#121F40]/95 backdrop-blur-lg">
          {menuItems.map((item) => (
            <a
              key={item.label}
              href={item.href}
              className="text-gray-300 hover:text-[#2DD4BF] block px-3 py-2 text-base font-medium hover:bg-[#2DD4BF]/5 rounded-lg transition-colors duration-200"
            >
              {item.label}
            </a>
          ))}
        </div>
      </div>
    </nav>
  );
};

export default Navigation;
