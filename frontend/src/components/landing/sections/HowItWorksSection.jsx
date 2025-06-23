// How GenomicChain Works section with 4-step process

import React from 'react';

/**
 * HowItWorksSection Component
 * Displays the 4-step process of how GenomicChain works
 * Upload & Encrypt → Lab Verification → Set Permissions → Earn Tokens
 */
const HowItWorksSection = () => {
  const steps = [
    {
      number: '1',
      title: 'Upload & Encrypt',
      description: 'Securely upload your genomic data with encryption',
      icon: (
        <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
        </svg>
      ),
      color: '#2DD4BF',
      bgColor: '#2DD4BF'
    },
    {
      number: '2',
      title: 'Lab Verification',
      description: 'Certified medical labs verify your data authenticity',
      icon: (
        <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
      ),
      color: '#5594E0',
      bgColor: '#5594E0'
    },
    {
      number: '3',
      title: 'Set Permissions',
      description: 'Control who can access your data and under what conditions',
      icon: (
        <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
        </svg>
      ),
      color: '#20A7BD',
      bgColor: '#20A7BD'
    },
    {
      number: '4',
      title: 'Earn Tokens',
      description: 'Get paid when researchers access your verified data',
      icon: (
        <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1" />
        </svg>
      ),
      color: '#37A36B',
      bgColor: '#37A36B'
    }
  ];

  return (
    <section id="how-it-works" className="relative py-20 bg-gradient-to-b from-[#0F192D] to-[#121F40]">
      {/* Background Effects */}
      <div className="absolute inset-0 bg-gradient-to-r from-[#0F192D]/90 via-transparent to-[#192643]/90" />
      
      <div className="relative max-w-7xl mx-auto px-6 lg:px-8">
        {/* Section Header */}
        <div className="text-center mb-16">
          <h2 className="text-4xl lg:text-5xl font-bold text-white mb-6">
            How GenomicChain Works
          </h2>
          <p className="text-xl text-[#C9E1FF] max-w-3xl mx-auto leading-relaxed">
            Four simple steps to take control of your genetic data and start earning
          </p>
        </div>

        {/* Steps Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
          {steps.map((step, index) => (
            <div key={step.number} className="relative group">
              {/* Connection Line (desktop only) */}
              {index < steps.length - 1 && (
                <div className="hidden lg:block absolute top-16 left-full w-full h-0.5 bg-gradient-to-r from-[#2DD4BF]/50 to-[#5594E0]/30 transform translate-x-4 z-0" />
              )}

              {/* Step Card */}
              <div className="relative bg-gradient-to-br from-[#121F40]/60 to-[#0F192D]/60 backdrop-blur-sm border border-[#2DD4BF]/10 rounded-xl p-6 hover:border-[#2DD4BF]/30 transition-all duration-300 group-hover:transform group-hover:scale-105 z-10">
                {/* Step Number Circle */}
                <div className="relative mb-6">
                  <div 
                    className="w-16 h-16 rounded-full flex items-center justify-center mx-auto relative"
                    style={{ backgroundColor: `${step.bgColor}20` }}
                  >
                    <div 
                      className="absolute inset-0 rounded-full animate-pulse"
                      style={{ backgroundColor: `${step.color}10` }}
                    />
                    <div 
                      className="w-12 h-12 rounded-full flex items-center justify-center relative z-10"
                      style={{ backgroundColor: step.color }}
                    >
                      <span className="text-white font-bold text-lg">{step.number}</span>
                    </div>
                  </div>
                </div>

                {/* Icon */}
                <div className="flex justify-center mb-4">
                  <div 
                    className="p-3 rounded-lg"
                    style={{ 
                      backgroundColor: `${step.color}15`,
                      color: step.color 
                    }}
                  >
                    {step.icon}
                  </div>
                </div>

                {/* Content */}
                <div className="text-center">
                  <h3 className="text-xl font-semibold text-white mb-3">
                    {step.title}
                  </h3>
                  <p className="text-[#C9E1FF] text-sm leading-relaxed">
                    {step.description}
                  </p>
                </div>

                {/* Hover Effects */}
                <div 
                  className="absolute inset-0 rounded-xl opacity-0 group-hover:opacity-100 transition-opacity duration-300 pointer-events-none"
                  style={{ 
                    background: `linear-gradient(135deg, ${step.color}05, transparent)`,
                    boxShadow: `0 10px 40px ${step.color}15`
                  }}
                />
              </div>
            </div>
          ))}
        </div>

        {/* Process Flow Visualization (Mobile) */}
        <div className="lg:hidden mt-12 flex flex-col items-center space-y-4">
          {steps.slice(0, -1).map((_, index) => (
            <div key={index} className="flex flex-col items-center">
              <div className="w-0.5 h-8 bg-gradient-to-b from-[#2DD4BF] to-[#5594E0]" />
              <svg className="w-4 h-4 text-[#2DD4BF]" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clipRule="evenodd" />
              </svg>
            </div>
          ))}
        </div>

        {/* Bottom CTA */}
        <div className="text-center mt-16">
          <div className="inline-flex items-center space-x-4 px-6 py-3 bg-[#121F40]/60 backdrop-blur-sm border border-[#2DD4BF]/20 rounded-full">
            <div className="w-3 h-3 bg-[#37A36B] rounded-full animate-pulse" />
            <span className="text-[#C9E1FF] text-sm">
              Join thousands already earning from their genetic data
            </span>
          </div>
        </div>
      </div>

      {/* Floating Elements */}
      <div className="absolute top-1/4 left-1/12 w-2 h-2 bg-[#2DD4BF]/40 rounded-full animate-pulse" />
      <div className="absolute bottom-1/3 right-1/12 w-1 h-1 bg-[#5594E0]/60 rounded-full animate-ping" />
      <div className="absolute top-3/4 left-1/6 w-3 h-3 bg-[#20A7BD]/30 rounded-full animate-pulse delay-500" />
    </section>
  );
};

export default HowItWorksSection;
