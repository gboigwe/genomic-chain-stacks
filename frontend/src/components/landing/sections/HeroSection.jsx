// Hero section with DNA animation and Genomic Vault interface

import React from 'react';
import { HeroDNA } from '../3d/DNACanvas.jsx';

/**
 * HeroSection Component
 * Main hero section with "Take Control of Your DNA" messaging
 * Includes Genomic Vault interface mockup and DNA helix animation
 */
const HeroSection = () => {
  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden pt-16">
      {/* Background Effects */}
      <div className="absolute inset-0 bg-gradient-to-br from-[#0F192D] via-[#121F40] to-[#192643]" />
      <div className="absolute inset-0 bg-gradient-to-t from-black/20 to-transparent" />
      
      <div className="relative max-w-7xl mx-auto px-6 lg:px-8 grid lg:grid-cols-2 gap-12 items-center">
        {/* Left Content */}
        <div className="space-y-8 z-10">
          {/* Blockchain Technology Badge */}
          <div className="inline-flex items-center px-4 py-2 rounded-full bg-[#2DD4BF]/10 border border-[#2DD4BF]/20 backdrop-blur-sm">
            <div className="w-2 h-2 bg-[#2DD4BF] rounded-full mr-3 animate-pulse" />
            <span className="text-[#2DD4BF] text-sm font-medium">Powered by Blockchain Technology</span>
          </div>

          {/* Main Headlines */}
          <div className="space-y-6">
            <h1 className="text-5xl lg:text-6xl font-bold leading-tight">
              <span className="text-white">Take Control of</span>
              <br />
              <span className="text-white">Your </span>
              <span className="bg-gradient-to-r from-[#2DD4BF] to-[#5594E0] bg-clip-text text-transparent">
                DNA
              </span>
            </h1>

            <p className="text-xl text-[#C9E1FF] leading-relaxed max-w-lg">
              Securely store, manage, and monetize your genomic data while contributing to groundbreaking medical research. Your data, your choice, your profit.
            </p>
          </div>

          {/* CTA Button */}
          <div className="flex items-center space-x-6">
            <button className="group px-8 py-4 bg-gradient-to-r from-[#2DD4BF] to-[#20A7BD] text-white font-semibold rounded-lg hover:shadow-xl hover:shadow-[#2DD4BF]/25 transform hover:scale-105 transition-all duration-300">
              <span className="flex items-center space-x-2">
                <span>Get Started</span>
                <svg className="w-5 h-5 transform group-hover:translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7l5 5m0 0l-5 5m5-5H6" />
                </svg>
              </span>
            </button>

            <button className="px-6 py-3 text-[#2DD4BF] border border-[#2DD4BF]/30 rounded-lg hover:bg-[#2DD4BF]/5 transition-all duration-300">
              Learn More
            </button>
          </div>

          {/* Trust Indicators */}
          <div className="flex items-center space-x-8 pt-8">
            <div className="text-center">
              <div className="text-2xl font-bold text-[#2DD4BF]">256-bit</div>
              <div className="text-sm text-[#6D7978]">Encryption</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-[#2DD4BF]">HIPAA</div>
              <div className="text-sm text-[#6D7978]">Compliant</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-[#2DD4BF]">Zero</div>
              <div className="text-sm text-[#6D7978]">Breaches</div>
            </div>
          </div>
        </div>

        {/* Right Content - Genomic Vault Interface + DNA */}
        <div className="relative lg:h-[600px] flex items-center justify-center">
          {/* DNA Helix Animation */}
          <div className="absolute inset-0 z-10">
            <HeroDNA 
              className="w-full h-full" 
              enableScrollAnimation={true}
            />
          </div>

          {/* Genomic Vault Interface Overlay */}
          <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 z-20 w-80 max-w-sm">
            <div className="bg-[#0F192D]/80 backdrop-blur-xl border border-[#2DD4BF]/20 rounded-xl p-6 shadow-2xl">
              {/* Vault Header */}
              <div className="flex items-center justify-between mb-6">
                <h3 className="text-white font-semibold">Your Genomic Vault</h3>
                <div className="flex items-center space-x-1">
                  <div className="w-2 h-2 bg-[#37A36B] rounded-full animate-pulse" />
                  <span className="text-xs text-[#37A36B]">Secure</span>
                </div>
              </div>

              {/* Vault Items */}
              <div className="space-y-4">
                {/* Whole Genome Sequence */}
                <div className="flex items-center justify-between p-3 bg-[#121F40]/50 rounded-lg border border-[#2DD4BF]/10">
                  <div className="flex items-center space-x-3">
                    <div className="w-3 h-3 bg-[#2DD4BF] rounded-full" />
                    <span className="text-white text-sm">Whole Genome Sequence</span>
                  </div>
                  <span className="text-xs bg-[#37A36B] px-2 py-1 rounded text-white">Verified</span>
                </div>

                {/* Privacy Settings */}
                <div className="flex items-center justify-between p-3 bg-[#121F40]/50 rounded-lg border border-[#5594E0]/10">
                  <div className="flex items-center space-x-3">
                    <div className="w-3 h-3 bg-[#5594E0] rounded-full" />
                    <span className="text-white text-sm">Privacy Settings</span>
                  </div>
                  <span className="text-xs bg-[#5594E0] px-2 py-1 rounded text-white">Active</span>
                </div>

                {/* Token Earnings */}
                <div className="flex items-center justify-between p-3 bg-[#121F40]/50 rounded-lg border border-[#E0BA1B]/10">
                  <div className="flex items-center space-x-3">
                    <div className="w-3 h-3 bg-[#E0BA1B] rounded-full" />
                    <span className="text-white text-sm">Token Earnings</span>
                  </div>
                  <span className="text-xs text-[#E0BA1B] font-semibold">1,247 GMC</span>
                </div>
              </div>

              {/* Quick Actions */}
              <div className="mt-6 grid grid-cols-2 gap-3">
                <button className="px-3 py-2 bg-[#2DD4BF]/10 text-[#2DD4BF] text-xs rounded-lg border border-[#2DD4BF]/20 hover:bg-[#2DD4BF]/20 transition-colors">
                  Upload Data
                </button>
                <button className="px-3 py-2 bg-[#5594E0]/10 text-[#5594E0] text-xs rounded-lg border border-[#5594E0]/20 hover:bg-[#5594E0]/20 transition-colors">
                  View Analytics
                </button>
              </div>
            </div>
          </div>

          {/* Glow Effects */}
          <div className="absolute top-1/4 right-1/4 w-32 h-32 bg-[#2DD4BF]/10 rounded-full blur-3xl animate-pulse" />
          <div className="absolute bottom-1/4 left-1/4 w-24 h-24 bg-[#5594E0]/10 rounded-full blur-2xl animate-pulse delay-1000" />
        </div>
      </div>

      {/* Scroll Indicator */}
      <div className="absolute bottom-8 left-1/2 transform -translate-x-1/2 z-10">
        <div className="flex flex-col items-center space-y-2 animate-bounce">
          <span className="text-[#6D7978] text-xs">Scroll to explore</span>
          <svg className="w-4 h-4 text-[#2DD4BF]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 14l-7 7m0 0l-7-7m7 7V3" />
          </svg>
        </div>
      </div>
    </section>
  );
};

export default HeroSection;
