import { useState, useEffect } from 'react'
import { useSignAndExecuteTransaction, useSuiClient, useCurrentAccount } from '@mysten/dapp-kit'
import { Transaction } from '@mysten/sui/transactions'
import { bcs, fromB64 } from '@mysten/bcs'
import { Send, Loader2, Coins, AlertCircle } from 'lucide-react'
import { TIPPING_PACKAGE_ID, TIPPING_SYSTEM_ID } from '../lib/constants'
import { useProfile } from '../hooks/useProfile'

interface SendTipProps {
    prefillAddress?: string | null
}

export default function SendTip({ prefillAddress }: SendTipProps) {
    const [receiverAddress, setReceiverAddress] = useState('')
    const [amount, setAmount] = useState('')
    const [message, setMessage] = useState('')
    const [loading, setLoading] = useState(false)
    const [error, setError] = useState<string | null>(null)
    const [success, setSuccess] = useState(false)
    const [transactionDigest, setTransactionDigest] = useState<string | null>(null)
    const [sentToAddress, setSentToAddress] = useState<string | null>(null)
    const { mutate: signAndExecute } = useSignAndExecuteTransaction()
    const client = useSuiClient()
    const account = useCurrentAccount()

    // Fetch sender profile
    const { data: senderProfile, isLoading: loadingSenderProfile } = useProfile()

    // Pre-fill receiver address from URL parameter
    useEffect(() => {
        if (prefillAddress) {
            setReceiverAddress(prefillAddress)
        }
    }, [prefillAddress])

    const resolveHandle = async (handle: string): Promise<string | null> => {
        try {
            const tx = new Transaction()
            const system = tx.object(TIPPING_SYSTEM_ID)
            tx.moveCall({
                target: `${TIPPING_PACKAGE_ID}::system_queries::get_address_by_handle`,
                arguments: [
                    system,
                    tx.pure.vector('u8', Array.from(new TextEncoder().encode(handle))),
                ],
            })

            const sender = account?.address ?? '0x0'
            const result = await client.devInspectTransactionBlock({
                transactionBlock: tx,
                sender,
            })

            const returnVals = result.results?.[0]?.returnValues
            if (!returnVals?.length) return null

            const [bytes] = returnVals[0]
            const decoded = bcs.option(bcs.Address).parse(fromB64(bytes))
            return decoded ?? null
        } catch (error) {
            console.error('Failed to resolve handle', error)
            return null
        }
    }

    const handleSendTip = async () => {
        if (!receiverAddress.trim()) {
            setError('Please enter receiver address')
            return
        }
        if (!amount || parseFloat(amount) <= 0) {
            setError('Please enter a valid amount')
            return
        }

        setLoading(true)
        setError(null)
        setSuccess(false)

        try {
            // Validate and normalize address or twitter handle
            const normalizedInput = receiverAddress.trim()
            if (!normalizedInput) {
                setError('Please enter a receiver address or @handle')
                setLoading(false)
                return
            }

            let resolvedAddress = normalizedInput

            if (!normalizedInput.startsWith('0x')) {
                const lookupHandle = normalizedInput.replace('@', '').toLowerCase()
                if (!lookupHandle) {
                    setError('Please enter a valid Twitter handle')
                    setLoading(false)
                    return
                }

                const resolved = await resolveHandle(lookupHandle)
                if (!resolved) {
                    setError('Twitter handle not found')
                    setLoading(false)
                    return
                }
                resolvedAddress = resolved
            } else if (normalizedInput.length > 66 || normalizedInput.length < 3) {
                setError('Invalid address format')
                setLoading(false)
                return
            }

            const amountMist = BigInt(Math.floor(parseFloat(amount) * 1_000_000_000))

            const tx = new Transaction()

            // Set gas budget explicitly
            tx.setGasBudget(100000000)

            // Get system
            const system = tx.object(TIPPING_SYSTEM_ID)

            // Get coin
            const [coin] = tx.splitCoins(tx.gas, [amountMist])

            // Use send_tip if sender has profile, otherwise use send_tip_no_profile
            if (senderProfile?.data?.objectId) {
                // Get sender profile object
                const senderProfileObj = tx.object(senderProfile.data.objectId)

                tx.moveCall({
                    target: `${TIPPING_PACKAGE_ID}::tip_operations::send_tip_with_profile_address`,
                    arguments: [
                        system,
                        senderProfileObj,
                        tx.pure.address(resolvedAddress),
                        coin,
                        tx.pure.string(message || ''),
                    ],
                })
            } else {
                // Send tip without profile (simpler)
                tx.moveCall({
                    target: `${TIPPING_PACKAGE_ID}::tip_operations::send_tip_no_profile`,
                    arguments: [
                        system,
                        tx.pure.address(resolvedAddress),
                        coin,
                        tx.pure.string(message || ''),
                    ],
                })
            }

            signAndExecute(
                {
                    transaction: tx,
                },
                {
                    onSuccess: (result) => {
                        setSuccess(true)
                        setTransactionDigest(result.digest)
                        setSentToAddress(resolvedAddress)
                        setReceiverAddress('')
                        setAmount('')
                        setMessage('')
                        setTimeout(() => {
                            setSuccess(false)
                            setTransactionDigest(null)
                            setSentToAddress(null)
                        }, 10000)
                    },
                    onError: (err) => {
                        const errorMsg = err.message || 'Failed to send tip'
                        if (errorMsg.includes('gas') || errorMsg.includes('No valid gas coins')) {
                            setError('Insufficient SUI for gas fees. Please request test tokens from the faucet (see balance above).')
                        } else {
                            setError(errorMsg)
                        }
                    },
                    onSettled: () => {
                        setLoading(false)
                    },
                }
            )
        } catch (err: any) {
            const errorMsg = err.message || 'Failed to send tip'
            if (errorMsg.includes('gas') || errorMsg.includes('No valid gas coins')) {
                setError('Insufficient SUI for gas fees. Please request test tokens from the faucet (see balance above).')
            } else {
                setError(errorMsg)
            }
            setLoading(false)
        }
    }

    return (
        <div className="max-w-md mx-auto">
            <h2 className="text-2xl font-bold text-gray-800 mb-6 flex items-center gap-2">
                <Send className="w-6 h-6" />
                Send a Tip
            </h2>

            <div className="space-y-4">
                {!senderProfile?.data && !loadingSenderProfile && (
                    <div className="bg-blue-50 border border-blue-200 text-blue-700 px-4 py-3 rounded-lg flex items-center gap-2">
                        <AlertCircle className="w-5 h-5" />
                        <span>💡 Profile is optional. You can send tips without a profile, but creating one helps track your statistics.</span>
                    </div>
                )}

                <div>
                    <label htmlFor="receiver" className="block text-sm font-medium text-gray-700 mb-2">
                        Receiver Address or @handle
                    </label>
                    <input
                        id="receiver"
                        type="text"
                        value={receiverAddress}
                        onChange={(e) => setReceiverAddress(e.target.value)}
                        placeholder="0x... or @creator"
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent font-mono text-sm"
                        disabled={loading || loadingSenderProfile}
                    />
                    <p className="mt-1 text-xs text-gray-500">
                        Enter a Sui address or the creator's Twitter handle
                    </p>
                </div>

                <div>
                    <label htmlFor="amount" className="block text-sm font-medium text-gray-700 mb-2">
                        Amount (SUI)
                    </label>
                    <div className="relative">
                        <Coins className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
                        <input
                            id="amount"
                            type="number"
                            step="0.000000001"
                            min="0"
                            value={amount}
                            onChange={(e) => setAmount(e.target.value)}
                            placeholder="0.0"
                            className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                            disabled={loading}
                        />
                    </div>
                </div>

                <div>
                    <label htmlFor="message" className="block text-sm font-medium text-gray-700 mb-2">
                        Message (Optional)
                    </label>
                    <textarea
                        id="message"
                        value={message}
                        onChange={(e) => setMessage(e.target.value)}
                        placeholder="Add a message..."
                        rows={3}
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent resize-none"
                        disabled={loading}
                    />
                </div>

                {error && (
                    <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
                        {error}
                    </div>
                )}

                {success && (
                    <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg">
                        <div className="flex items-center gap-2 mb-2">
                            <span className="font-semibold">✅ Tip sent successfully!</span>
                        </div>
                        {transactionDigest && (
                            <div className="mt-2 text-sm">
                                <p className="mb-1">Transaction: <code className="bg-green-100 px-1 rounded text-xs font-mono break-all">{transactionDigest}</code></p>
                                <div className="flex gap-3 mt-2">
                                    <a
                                        href={`https://suiscan.xyz/mainnet/tx/${transactionDigest}`}
                                        target="_blank"
                                        rel="noopener noreferrer"
                                        className="text-green-800 hover:text-green-900 underline text-xs"
                                    >
                                        View on Suiscan →
                                    </a>
                                </div>
                            </div>
                        )}
                        <p className="text-xs mt-2 text-green-600">
                            💡 The coins should arrive in the receiver's wallet immediately.
                            <br />
                            • Sent to: <code className="bg-green-100 px-1 rounded text-xs font-mono break-all">{sentToAddress || 'N/A'}</code>
                            <br />
                            • Ask the receiver to refresh their wallet or check the transaction links above
                            <br />
                            • Verify both wallets are on the same network
                        </p>
                    </div>
                )}

                <button
                    onClick={handleSendTip}
                    disabled={loading || !receiverAddress.trim() || !amount || loadingSenderProfile}
                    className="w-full bg-indigo-600 text-white py-3 px-4 rounded-lg font-medium hover:bg-indigo-700 disabled:bg-gray-400 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                >
                    {loading ? (
                        <>
                            <Loader2 className="w-5 h-5 animate-spin" />
                            Sending...
                        </>
                    ) : (
                        <>
                            <Send className="w-5 h-5" />
                            Send Tip
                        </>
                    )}
                </button>
            </div>
        </div>
    )
}
