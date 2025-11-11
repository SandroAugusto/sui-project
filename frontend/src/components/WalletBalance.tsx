import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { useSuiClient, useCurrentAccount } from '@mysten/dapp-kit'
import { Coins, AlertCircle, RefreshCw, Copy, Check } from 'lucide-react'
import { formatSui } from '../lib/utils'

export default function WalletBalance() {
    const client = useSuiClient()
    const account = useCurrentAccount()
    const [copied, setCopied] = useState(false)

    const { data: balance, isLoading, refetch } = useQuery({
        queryKey: ['wallet-balance', account?.address],
        queryFn: async () => {
            if (!account?.address) return null
            const coins = await client.getCoins({
                owner: account.address,
                coinType: '0x2::sui::SUI',
            })
            const totalBalance = coins.data.reduce((sum, coin) => sum + BigInt(coin.balance), BigInt(0))
            return totalBalance
        },
        enabled: !!account?.address,
        refetchInterval: 10000, // Refetch every 10 seconds
    })

    const handleFaucet = async () => {
        if (!account?.address) return

        try {
            // Open official Sui faucet in new tab
            const faucetUrl = `https://faucet.sui.io/`
            window.open(faucetUrl, '_blank')

            // Wait a bit and refetch
            setTimeout(() => {
                refetch()
            }, 5000)
        } catch (err) {
            console.error('Error opening faucet:', err)
        }
    }

    const copyAddress = async () => {
        if (!account?.address) return
        try {
            await navigator.clipboard.writeText(account.address)
            setCopied(true)
            setTimeout(() => setCopied(false), 2000)
        } catch (err) {
            console.error('Failed to copy address:', err)
        }
    }

    if (!account) return null

    const balanceNumber = balance ? (typeof balance === 'bigint' ? Number(balance) : balance) : 0
    const hasLowBalance = balanceNumber < 100_000_000 // Less than 0.1 SUI

    return (
        <div className="bg-gradient-to-r from-indigo-50 to-purple-50 border border-indigo-200 rounded-lg p-4 mb-6">
            <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                    <div className="bg-indigo-100 rounded-full p-2">
                        <Coins className="w-5 h-5 text-indigo-600" />
                    </div>
                    <div>
                        <p className="text-sm text-gray-600">Wallet Balance</p>
                        {isLoading ? (
                            <p className="text-lg font-bold text-gray-800">Loading...</p>
                        ) : (
                            <p className="text-lg font-bold text-indigo-900">
                                {formatSui(balanceNumber)} SUI
                            </p>
                        )}
                    </div>
                </div>

                {hasLowBalance && (
                    <div className="flex items-center gap-2">
                        <div className="flex items-center gap-2 text-yellow-700 bg-yellow-50 px-3 py-2 rounded-lg border border-yellow-200">
                            <AlertCircle className="w-4 h-4" />
                            <span className="text-sm font-medium">Low balance</span>
                        </div>
                        <button
                            onClick={handleFaucet}
                            className="bg-indigo-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-indigo-700 flex items-center gap-2 transition-colors"
                        >
                            <RefreshCw className="w-4 h-4" />
                            Get Test SUI
                        </button>
                    </div>
                )}
            </div>

            {hasLowBalance && (
                <div className="mt-3 pt-3 border-t border-indigo-200">
                    <p className="text-xs text-gray-600 mb-3">
                        💡 You need SUI to pay for transaction fees. Click "Get Test SUI" to open the faucet.
                    </p>
                    <div className="bg-gray-50 p-3 rounded-lg border border-gray-200">
                        <div className="flex items-center justify-between mb-2">
                            <p className="text-xs text-gray-700 font-semibold">Your address (copy to faucet):</p>
                            <button
                                onClick={copyAddress}
                                className="text-indigo-600 hover:text-indigo-700 flex items-center gap-1 text-xs"
                            >
                                {copied ? (
                                    <>
                                        <Check className="w-3 h-3" />
                                        Copied!
                                    </>
                                ) : (
                                    <>
                                        <Copy className="w-3 h-3" />
                                        Copy
                                    </>
                                )}
                            </button>
                        </div>
                        <p className="text-xs font-mono text-gray-600 break-all">{account.address}</p>
                    </div>
                    <div className="mt-3 bg-blue-50 p-2 rounded border border-blue-200">
                        <p className="text-xs text-blue-700 font-semibold mb-1">📋 Instructions:</p>
                        <ol className="text-xs text-blue-600 list-decimal list-inside space-y-1">
                            <li>Click "Get Test SUI" to open faucet.sui.io</li>
                            <li>Select your network from the dropdown</li>
                            <li>Paste your address above and click "Request SUI"</li>
                        </ol>
                    </div>
                    <p className="text-xs text-gray-500 mt-2">
                        💻 Or use CLI: <code className="bg-gray-100 px-1.5 py-0.5 rounded">sui client faucet</code>
                    </p>
                </div>
            )}
        </div>
    )
}

