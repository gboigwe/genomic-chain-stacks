// Main GenomicChain landing page component

import React from 'react';
import Navigation from './Navigation.jsx';
import HeroSection from './sections/HeroSection.jsx';
import HowItWorksSection from './sections/HowItWorksSection.jsx';
import PrivacyTrustSection from './sections/PrivacyTrustSection.jsx';
import CTASection from './sections/CTASection.jsx';
import Footer from './Footer.jsx';

/**
 * GenomicChainLanding Component
 * Main landing page that combines all sections with proper web3 styling
 * Following the exact design provided with sophisticated scroll animations
 */
const GenomicChainLanding = () => {
  return (
    <div className="min-h-screen bg-gradient-to-br from-[#0F192D] via-[#121F40] to-[#0F192D] text-white overflow-x-hidden">
      {/* Navigation */}
      <Navigation />
      
      {/* Main Content */}
      <main className="relative">
        {/* Hero Section - Take Control of Your DNA */}
        <HeroSection />
        
        {/* How GenomicChain Works - 4 Steps */}
        <HowItWorksSection />
        
        {/* Built for Privacy, Designed for Trust */}
        <PrivacyTrustSection />
        
        {/* Ready to Take Control CTA */}
        <CTASection />
      </main>
      
      {/* Footer */}
      <Footer />
      
      {/* Background Effects */}
      <div className="fixed inset-0 pointer-events-none z-0">
        {/* Gradient Overlays */}
        <div className="absolute inset-0 bg-gradient-to-r from-[#0F192D]/80 via-transparent to-[#192643]/60" />
        <div className="absolute inset-0 bg-gradient-to-b from-transparent via-[#121F40]/30 to-[#0F192D]/90" />
        
        {/* Animated Background Particles */}
        <div className="absolute top-1/4 left-1/4 w-2 h-2 bg-[#2DD4BF]/30 rounded-full animate-pulse" />
        <div className="absolute top-3/4 right-1/3 w-1 h-1 bg-[#5594E0]/40 rounded-full animate-ping" />
        <div className="absolute bottom-1/4 left-1/6 w-3 h-3 bg-[#20A7BD]/20 rounded-full animate-pulse" />
        <div className="absolute top-1/2 right-1/4 w-1 h-1 bg-[#37A36B]/50 rounded-full animate-ping" />
      </div>
    </div>
  );
};

export default GenomicChainLanding;
