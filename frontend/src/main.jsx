// import React from 'react';
// import ReactDOM from 'react-dom/client';
// import DNAJourneyLanding from './components/landing/DNAJourneyLanding.jsx';
// import './index.css';

// ReactDOM.createRoot(document.getElementById('root')).render(
//   <React.StrictMode>
//     <DNAJourneyLanding />
//   </React.StrictMode>
// );









import React from 'react';
import ReactDOM from 'react-dom/client';
import GenomicChainLanding from './components/landing/GenomicChainLanding.jsx';
import { WalletProvider } from './contexts/WalletContext.jsx';
import './index.css';

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <WalletProvider>
      <GenomicChainLanding />
    </WalletProvider>
  </React.StrictMode>
);











// 
// import { StrictMode } from 'react'
// import { createRoot } from 'react-dom/client'
// import './index.css'
// import App from './App.jsx'

// createRoot(document.getElementById('root')).render(
//   <StrictMode>
//     <App />
//   </StrictMode>,
// )
