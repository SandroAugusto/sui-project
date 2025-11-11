import { useQuery } from '@tanstack/react-query'
import { useSuiClient } from '@mysten/dapp-kit'
import { History, Clock, ArrowRight, AlertCircle } from 'lucide-react'
import { TIPPING_SYSTEM_ID } from '../lib/constants'
import { parseTippingSystem, formatSui } from '../lib/utils'
import type { TipData } from '../lib/utils'

export default function HistoryView() {
    const client = useSuiClient()

    const { data: systemData, isLoading, error } = useQuery({
        queryKey: ['tipping-history', TIPPING_SYSTEM_ID],
        queryFn: async () => {
            try {
                const object = await client.getObject({
                    id: TIPPING_SYSTEM_ID,
                    options: {
                        showContent: true,
                        showType: true,
                    },
                })
                if (!object.data) {
                    throw new Error('Object not found')
                }
                return object
            } catch (err: any) {
                console.error('Error fetching history:', err)
                throw new Error(`Failed to fetch object: ${err.message || String(err)}`)
            }
        },
        retry: 2,
    })

    if (isLoading) {
        return (
            <div className="text-center py-12">
                <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
                <p className="mt-4 text-gray-600">Loading history...</p>
            </div>
        )
    }

    if (error) {
        return (
            <div className="p-6 bg-red-50 border-2 border-red-200 rounded-lg">
                <div className="flex items-center gap-2 mb-2">
                    <AlertCircle className="w-5 h-5 text-red-600" />
                    <p className="text-red-700 font-medium">Error loading history</p>
                </div>
                <p className="text-red-600 text-sm">{String(error)}</p>
            </div>
        )
    }

    const parsedData = parseTippingSystem(systemData || null)
    const tips: TipData[] = parsedData?.history || []

    return (
        <div>
            <h2 className="text-2xl font-bold text-gray-800 mb-6 flex items-center gap-2">
                <History className="w-6 h-6" />
                Tip History
            </h2>

            {tips.length === 0 ? (
                <div className="text-center py-12 bg-gray-50 rounded-lg border border-gray-200">
                    <History className="w-12 h-12 text-gray-400 mx-auto mb-4" />
                    <p className="text-gray-600">No tips have been sent yet.</p>
                    <p className="text-gray-500 text-sm mt-2">Be the first to send a tip!</p>
                </div>
            ) : (
                <div className="space-y-4">
                    {tips.reverse().map((tip, index) => (
                        <div
                            key={index}
                            className="bg-gradient-to-r from-gray-50 to-gray-100 p-4 rounded-lg shadow-sm border border-gray-200 hover:shadow-md transition-shadow"
                        >
                            <div className="flex items-center justify-between">
                                <div className="flex items-center gap-3">
                                    <div className="bg-indigo-100 rounded-full p-2">
                                        <ArrowRight className="w-5 h-5 text-indigo-600" />
                                    </div>
                                    <div>
                                        <p className="font-medium text-gray-900">
                                            {tip.from?.slice(0, 10)}... → {tip.to?.slice(0, 10)}...
                                        </p>
                                        {tip.message && (
                                            <p className="text-sm text-gray-600 mt-1 italic">"{tip.message}"</p>
                                        )}
                                    </div>
                                </div>
                                <div className="text-right">
                                    <p className="font-bold text-indigo-600">
                                        {formatSui(Number(tip.amount))} SUI
                                    </p>
                                    {tip.timestamp && Number(tip.timestamp) > 0 && (
                                        <p className="text-xs text-gray-500 mt-1 flex items-center gap-1 justify-end">
                                            <Clock className="w-3 h-3" />
                                            {new Date(Number(tip.timestamp)).toLocaleString()}
                                        </p>
                                    )}
                                </div>
                            </div>
                        </div>
                    ))}
                </div>
            )}

            {!parsedData && systemData && (
                <div className="mt-8 p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
                    <p className="text-sm text-yellow-700">
                        ⚠ Could not parse history data. Check console for details.
                    </p>
                </div>
            )}
        </div>
    )
}
