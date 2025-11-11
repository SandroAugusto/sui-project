# Tipping System Frontend

React frontend for the Sui Tipping System built with Vite, TypeScript, and Tailwind CSS.

## Features

- 🔐 Wallet connection using Sui Wallet Kit
- 👤 Create user profiles
- 💰 Send tips to other users
- 📊 View system statistics
- 📜 Browse tip history

## Prerequisites

- Node.js 18+ and npm
- A deployed Tipping smart contract on Sui

## Installation

```bash
npm install
```

## Configuration

Before running the app, you need to deploy the smart contract and configure the contract IDs.

### Setting Contract IDs

You have two options:

**Option 1: Environment Variables (Recommended)**

1. Copy the example environment file:
   ```bash
   cp env.example .env
   ```

2. Edit `.env` and add your contract IDs:
   ```env
   VITE_TIPPING_PACKAGE_ID=0x...
   VITE_TIPPING_SYSTEM_ID=0x...
   VITE_DEFAULT_NETWORK=mainnet
   ```

**Option 2: Direct Configuration**

Edit `src/lib/constants.ts` directly and set the values:
```typescript
export const TIPPING_PACKAGE_ID = '0x...'
export const TIPPING_SYSTEM_ID = '0x...'
```

### Getting Contract IDs

After deploying your contract:

1. **Package ID**: The `PackageID` from the publish output
2. **TippingSystem ID**: The `ObjectID` from the "Created Objects" section (the shared object)

**Note**: The `.env` file is gitignored and won't be committed to the repository.

## Development

```bash
npm run dev
```

The app will be available at `http://localhost:5173`

## Build

```bash
npm run build
```

## Project Structure

```
frontend/
├── src/
│   ├── components/      # React components
│   │   ├── CreateProfile.tsx
│   │   ├── SendTip.tsx
│   │   ├── Statistics.tsx
│   │   └── HistoryView.tsx
│   ├── hooks/          # Custom React hooks
│   ├── lib/            # Utility functions
│   ├── App.tsx         # Main app component
│   └── main.tsx        # Entry point
├── package.json
└── vite.config.ts
```

## Technologies

- **React 19** - UI library
- **TypeScript** - Type safety
- **Vite** - Build tool
- **Tailwind CSS** - Styling
- **@mysten/dapp-kit** - Sui wallet integration
- **@mysten/sui** - Sui SDK
- **@tanstack/react-query** - Data fetching
- **lucide-react** - Icons

## Notes

- The frontend assumes your smart contract is deployed and accessible
- You'll need to implement proper data parsing based on your contract's object structure
- Profile objects need to be fetched and passed correctly in the SendTip component
- Update network configuration in `src/main.tsx` if needed (devnet/testnet/mainnet)
