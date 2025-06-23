// Final call-to-action section

import React from 'react';

/**
 * CTASection Component
 * Final call-to-action section encouraging users to get started
 * "Ready to Take Control of Your Genetic Data?"
 */
const CTASection = () => {
  return (
    <section className="relative py-20 bg-gradient-to-b from-[#0F192D] to-[#000000] overflow-hidden">
      {/* Background Effects */}
      <div className="absolute inset-0 bg-gradient-to-r from-[#121F40]/30 via-transparent to-[#192643]/30" />
      
      {/* Animated Background Elements */}
      <div className="absolute inset-0 overflow-hidden">
        <div className="absolute top-1/4 left-1/6 w-96 h-96 bg-[#2DD4BF]/5 rounded-full blur-3xl animate-pulse" />
        <div className="absolute bottom-1/4 right-1/6 w-80 h-80 bg-[#5594E0]/5 rounded-full blur-3xl animate-pulse delay-1000" />
        <div className="absolute top-3/4 left-1/3 w-64 h-64 bg-[#37A36B]/5 rounded-full blur-2xl animate-pulse delay-500" />
      </div>

      <div className="relative max-w-4xl mx-auto px-6 lg:px-8 text-center">
        {/* Main CTA Content */}
        <div className="space-y-8">
          {/* Headline */}
          <h2 className="text-4xl lg:text-6xl font-bold leading-tight">
            <span className="text-white">Ready to Take Control of</span>
            <br />
            <span className="text-white">Your </span>
            <span className="bg-gradient-to-r from-[#2DD4BF] to-[#5594E0] bg-clip-text text-transparent">
              Genetic Data
            </span>
            <span className="text-white">?</span>
          </h2>

          {/* Subtext */}
          <p className="text-xl text-[#C9E1FF] leading-relaxed max-w-2xl mx-auto">
            Join thousands of users who are already earning from their genomic data while 
            contributing to medical breakthroughs.
          </p>

          {/* Statistics */}
          <div className="flex flex-col sm:flex-row items-center justify-center space-y-4 sm:space-y-0 sm:space-x-12 py-8">
            <div className="text-center">
              <div className="text-3xl font-bold text-[#2DD4BF] mb-1">10,000+</div>
              <div className="text-sm text-[#6D7978]">Active Users</div>
            </div>
            <div className="hidden sm:block w-px h-12 bg-[#2DD4BF]/20" />
            <div className="text-center">
              <div className="text-3xl font-bold text-[#5594E0] mb-1">$2.5M+</div>
              <div className="text-sm text-[#6D7978]">Earnings Distributed</div>
            </div>
            <div className="hidden sm:block w-px h-12 bg-[#2DD4BF]/20" />
            <div className="text-center">
              <div className="text-3xl font-bold text-[#37A36B] mb-1">500+</div>
              <div className="text-sm text-[#6D7978]">Research Projects</div>
            </div>
          </div>

          {/* CTA Buttons */}
          <div className="flex flex-col sm:flex-row items-center justify-center space-y-4 sm:space-y-0 sm:space-x-6">
            <button className="group px-10 py-4 bg-gradient-to-r from-[#2DD4BF] to-[#20A7BD] text-white font-semibold rounded-lg hover:shadow-2xl hover:shadow-[#2DD4BF]/25 transform hover:scale-105 transition-all duration-300 min-w-[200px]">
              <span className="flex items-center justify-center space-x-2">
                <span>Get Started</span>
                <svg className="w-5 h-5 transform group-hover:translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7l5 5m0 0l-5 5m5-5H6" />
                </svg>
              </span>
            </button>

            <button className="px-8 py-4 text-[#2DD4BF] border border-[#2DD4BF]/30 rounded-lg hover:bg-[#2DD4BF]/5 hover:border-[#2DD4BF]/50 transition-all duration-300 min-w-[180px]">
              Watch Demo
            </button>
          </div>

          {/* Trust Signals */}
          <div className="pt-8">
            <div className="inline-flex items-center space-x-6 px-6 py-3 bg-[#0F192D]/60 backdrop-blur-sm border border-[#2DD4BF]/10 rounded-full">
              <div className="flex items-center space-x-2">
                <svg className="w-4 h-4 text-[#37A36B]" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M2.166 4.999A11.954 11.954 0 0010 1.944 11.954 11.954 0 0017.834 5c.11.65.166 1.32.166 2.001 0 5.225-3.34 9.67-8 11.317C5.34 16.67 2 12.225 2 7c0-.682.057-1.35.166-2.001zm11.541 3.708a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                </svg>
                <span className="text-[#C9E1FF] text-sm">Free to start</span>
              </div>
              <div className="w-px h-4 bg-[#2DD4BF]/20" />
              <div className="flex items-center space-x-2">
                <svg className="w-4 h-4 text-[#2DD4BF]" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z" clipRule="evenodd" />
                </svg>
                <span className="text-[#C9E1FF] text-sm">100% secure</span>
              </div>
              <div className="w-px h-4 bg-[#2DD4BF]/20" />
              <div className="flex items-center space-x-2">
                <svg className="w-4 h-4 text-[#5594E0]" fill="currentColor" viewBox="0 0 20 20">
                  <path d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <span className="text-[#C9E1FF] text-sm">No setup required</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Floating Particles */}
      <div className="absolute top-1/6 left-1/12 w-2 h-2 bg-[#2DD4BF]/40 rounded-full animate-pulse" />
      <div className="absolute bottom-1/5 right-1/12 w-1 h-1 bg-[#5594E0]/60 rounded-full animate-ping" />
      <div className="absolute top-2/3 left-1/8 w-3 h-3 bg-[#37A36B]/30 rounded-full animate-pulse delay-700" />
      <div className="absolute top-1/3 right-1/6 w-2 h-2 bg-[#E0BA1B]/40 rounded-full animate-pulse delay-300" />
    </section>
  );
};

export default CTASection;
