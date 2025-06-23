// Built for Privacy, Designed for Trust section

import React from 'react';
import { PrivacyDNA } from '../3d/DNACanvas.jsx';

/**
 * PrivacyTrustSection Component
 * Shows privacy features, security dashboard, and DNA animation
 * Includes End-to-End Encryption, Medical Lab Verification, Smart Contract Automation
 */
const PrivacyTrustSection = () => {
  const privacyFeatures = [
    {
      icon: (
        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
        </svg>
      ),
      title: 'End-to-End Encryption',
      description: 'Your data is encrypted before it leaves your device and remains encrypted in storage',
      color: '#E0BA1B'
    },
    {
      icon: (
        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
        </svg>
      ),
      title: 'Medical Lab Verification',
      description: 'Certified labs verify data authenticity with cryptographic attestations',
      color: '#5594E0'
    },
    {
      icon: (
        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
        </svg>
      ),
      title: 'Smart Contract Automation',
      description: 'Automated payments and permissions through transparent smart contracts',
      color: '#37A36B'
    }
  ];

  const securityStats = [
    {
      value: '256-bit',
      label: 'Encryption',
      color: '#2DD4BF',
      bgColor: '#2DD4BF'
    },
    {
      value: '99.9%',
      label: 'Uptime',
      color: '#5594E0',
      bgColor: '#5594E0'
    },
    {
      value: 'HIPAA',
      label: 'Compliant',
      color: '#37A36B',
      bgColor: '#37A36B'
    },
    {
      value: 'Zero',
      label: 'Breaches',
      color: '#E0BA1B',
      bgColor: '#E0BA1B'
    }
  ];

  return (
    <section className="relative py-20 bg-gradient-to-br from-[#121F40] via-[#0F192D] to-[#192643] overflow-hidden">
      {/* Background Effects */}
      <div className="absolute inset-0 bg-gradient-to-t from-black/20 to-transparent" />
      
      <div className="relative max-w-7xl mx-auto px-6 lg:px-8">
        <div className="grid lg:grid-cols-2 gap-16 items-center">
          {/* Left Content - Privacy Features */}
          <div className="space-y-8">
            {/* Section Header */}
            <div className="space-y-6">
              <h2 className="text-4xl lg:text-5xl font-bold leading-tight">
                <span className="text-white">Built for </span>
                <span className="bg-gradient-to-r from-[#2DD4BF] to-[#5594E0] bg-clip-text text-transparent">
                  Privacy
                </span>
                <span className="text-white">,</span>
                <br />
                <span className="text-white">Designed for </span>
                <span className="bg-gradient-to-r from-[#5594E0] to-[#37A36B] bg-clip-text text-transparent">
                  Trust
                </span>
              </h2>

              <p className="text-xl text-[#C9E1FF] leading-relaxed">
                GenomicChain uses cutting-edge blockchain technology and medical-grade security to ensure your genetic data remains private, secure, and under your complete control.
              </p>
            </div>

            {/* Privacy Features List */}
            <div className="space-y-6">
              {privacyFeatures.map((feature, index) => (
                <div 
                  key={feature.title}
                  className="flex items-start space-x-4 p-4 rounded-xl bg-[#0F192D]/40 backdrop-blur-sm border border-[#2DD4BF]/10 hover:border-[#2DD4BF]/20 transition-all duration-300 group"
                >
                  {/* Icon */}
                  <div 
                    className="flex-shrink-0 w-12 h-12 rounded-lg flex items-center justify-center"
                    style={{ 
                      backgroundColor: `${feature.color}15`,
                      color: feature.color 
                    }}
                  >
                    {feature.icon}
                  </div>

                  {/* Content */}
                  <div className="flex-1 min-w-0">
                    <h3 className="text-lg font-semibold text-white mb-2 group-hover:text-[#2DD4BF] transition-colors duration-300">
                      {feature.title}
                    </h3>
                    <p className="text-[#C9E1FF] text-sm leading-relaxed">
                      {feature.description}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Right Content - Security Dashboard + DNA */}
          <div className="relative lg:h-[600px] flex items-center justify-center">
            {/* DNA Helix Animation */}
            <div className="absolute inset-0 z-10">
              <PrivacyDNA 
                className="w-full h-full" 
                enableScrollAnimation={true}
              />
            </div>

            {/* Security Dashboard Overlay */}
            <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 z-20 w-80 max-w-sm">
              <div className="bg-[#0F192D]/85 backdrop-blur-xl border border-[#2DD4BF]/20 rounded-xl p-6 shadow-2xl">
                {/* Dashboard Header */}
                <div className="flex items-center justify-between mb-6">
                  <h3 className="text-white font-semibold">Security Dashboard</h3>
                  <div className="flex items-center space-x-1">
                    <div className="w-2 h-2 bg-[#37A36B] rounded-full animate-pulse" />
                    <span className="text-xs text-[#37A36B]">All Systems Secure</span>
                  </div>
                </div>

                {/* Security Stats Grid */}
                <div className="grid grid-cols-2 gap-4 mb-6">
                  {securityStats.map((stat, index) => (
                    <div 
                      key={stat.label}
                      className="p-4 rounded-lg border text-center"
                      style={{ 
                        backgroundColor: `${stat.bgColor}10`,
                        borderColor: `${stat.color}20`
                      }}
                    >
                      <div 
                        className="text-2xl font-bold mb-1"
                        style={{ color: stat.color }}
                      >
                        {stat.value}
                      </div>
                      <div className="text-xs text-[#C9E1FF]">
                        {stat.label}
                      </div>
                    </div>
                  ))}
                </div>

                {/* Live Security Indicators */}
                <div className="space-y-3">
                  <div className="flex items-center justify-between p-2 bg-[#37A36B]/10 rounded-lg">
                    <span className="text-sm text-white">Network Status</span>
                    <div className="flex items-center space-x-2">
                      <div className="w-2 h-2 bg-[#37A36B] rounded-full animate-pulse" />
                      <span className="text-xs text-[#37A36B]">Active</span>
                    </div>
                  </div>

                  <div className="flex items-center justify-between p-2 bg-[#2DD4BF]/10 rounded-lg">
                    <span className="text-sm text-white">Encryption Level</span>
                    <span className="text-xs text-[#2DD4BF] font-semibold">Maximum</span>
                  </div>

                  <div className="flex items-center justify-between p-2 bg-[#5594E0]/10 rounded-lg">
                    <span className="text-sm text-white">Lab Verifications</span>
                    <span className="text-xs text-[#5594E0] font-semibold">24/7</span>
                  </div>
                </div>

                {/* Security Actions */}
                <div className="mt-6 grid grid-cols-1 gap-2">
                  <button className="px-3 py-2 bg-[#2DD4BF]/10 text-[#2DD4BF] text-xs rounded-lg border border-[#2DD4BF]/20 hover:bg-[#2DD4BF]/20 transition-colors">
                    View Security Report
                  </button>
                </div>
              </div>
            </div>

            {/* Additional Glow Effects */}
            <div className="absolute top-1/6 right-1/6 w-40 h-40 bg-[#5594E0]/5 rounded-full blur-3xl animate-pulse" />
            <div className="absolute bottom-1/6 left-1/6 w-32 h-32 bg-[#37A36B]/5 rounded-full blur-2xl animate-pulse delay-1000" />
          </div>
        </div>

        {/* Trust Indicators */}
        <div className="mt-20 text-center">
          <div className="inline-flex items-center space-x-8 px-8 py-4 bg-[#0F192D]/60 backdrop-blur-sm border border-[#2DD4BF]/20 rounded-full">
            <div className="flex items-center space-x-2">
              <div className="w-3 h-3 bg-[#37A36B] rounded-full animate-pulse" />
              <span className="text-[#C9E1FF] text-sm">SOC 2 Compliant</span>
            </div>
            <div className="w-px h-4 bg-[#2DD4BF]/20" />
            <div className="flex items-center space-x-2">
              <div className="w-3 h-3 bg-[#2DD4BF] rounded-full animate-pulse" />
              <span className="text-[#C9E1FF] text-sm">ISO 27001 Certified</span>
            </div>
            <div className="w-px h-4 bg-[#2DD4BF]/20" />
            <div className="flex items-center space-x-2">
              <div className="w-3 h-3 bg-[#5594E0] rounded-full animate-pulse" />
              <span className="text-[#C9E1FF] text-sm">GDPR Ready</span>
            </div>
          </div>
        </div>
      </div>

      {/* Floating Security Elements */}
      <div className="absolute top-1/5 left-1/12 w-2 h-2 bg-[#37A36B]/40 rounded-full animate-pulse" />
      <div className="absolute bottom-1/4 right-1/12 w-1 h-1 bg-[#E0BA1B]/60 rounded-full animate-ping" />
      <div className="absolute top-3/5 left-1/8 w-3 h-3 bg-[#2DD4BF]/30 rounded-full animate-pulse delay-700" />
    </section>
  );
};

export default PrivacyTrustSection;
