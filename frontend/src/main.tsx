import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { SuiClientProvider, WalletProvider } from '@mysten/dapp-kit'
import { getFullnodeUrl } from '@mysten/sui/client'
import '@mysten/dapp-kit/dist/index.css'
import './index.css'
import App from './App.tsx'

const queryClient = new QueryClient()

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <QueryClientProvider client={queryClient}>
      <SuiClientProvider networks={{
        localnet: { url: 'http://127.0.0.1:9000' },
        devnet: { url: getFullnodeUrl('devnet') },
        mainnet: { url: getFullnodeUrl('mainnet') },
        testnet: { url: getFullnodeUrl('testnet') },
      }} defaultNetwork="mainnet">
        <WalletProvider 
          storageKey="sui-wallet"
          autoConnect
        >
          <App />
        </WalletProvider>
      </SuiClientProvider>
    </QueryClientProvider>
  </StrictMode>,
)
