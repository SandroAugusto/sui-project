// Contract IDs - Set these via environment variables or update directly
// For production, use environment variables (see .env.example)

export const TIPPING_PACKAGE_ID = import.meta.env.VITE_TIPPING_PACKAGE_ID || ''
export const TIPPING_SYSTEM_ID = import.meta.env.VITE_TIPPING_SYSTEM_ID || ''

// Network configuration
export const DEFAULT_NETWORK = (import.meta.env.VITE_DEFAULT_NETWORK || 'mainnet') as 'localnet' | 'devnet' | 'testnet' | 'mainnet'

// Validate that contract IDs are set
if (!TIPPING_PACKAGE_ID || !TIPPING_SYSTEM_ID) {
    console.warn('⚠️ TIPPING_PACKAGE_ID and TIPPING_SYSTEM_ID must be set. Please check your environment variables or constants.ts')
}
