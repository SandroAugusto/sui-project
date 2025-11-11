import { useQuery } from '@tanstack/react-query'
import { useSuiClient } from '@mysten/dapp-kit'
import { BarChart3, TrendingUp, TrendingDown, Coins, AlertCircle } from 'lucide-react'
import { TIPPING_SYSTEM_ID } from '../lib/constants'
import { parseTippingSystem, formatSui } from '../lib/utils'

export default function Statistics() {
    const client = useSuiClient()

    const { data: systemData, isLoading, error } = useQuery({
        queryKey: ['tipping-system', TIPPING_SYSTEM_ID],
        queryFn: async () => {
            try {
                console.log('Fetching object:', TIPPING_SYSTEM_ID)
                const object = await client.getObject({
                    id: TIPPING_SYSTEM_ID,
                    options: {
                        showContent: true,
                        showType: true,
                        showOwner: true,
                    },
                })
                console.log('Object fetched:', object)
                if (!object.data) {
                    throw new Error('Object not found')
                }
                return object
            } catch (err: any) {
                console.error('Error fetching TippingSystem:', err)
                throw new Error(`Failed to fetch object: ${err.message || String(err)}`)
            }
        },
        retry: 2,
    })

    if (isLoading) {
        return (
            <div className="text-center py-12">
                <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
                <p className="mt-4 text-gray-600">Loading statistics...</p>
            </div>
        )
    }

    if (error) {
        return (
            <div className="p-6 bg-red-50 border-2 border-red-200 rounded-lg">
                <div className="flex items-center gap-2 mb-2">
                    <AlertCircle className="w-5 h-5 text-red-600" />
                    <p className="text-red-700 font-medium">Error loading statistics</p>
                </div>
                <p className="text-red-600 text-sm mt-2">{String(error)}</p>
                <div className="mt-4 p-3 bg-red-100 rounded text-xs font-mono break-all">
                    <p className="font-semibold mb-1">System ID:</p>
                    <p>{TIPPING_SYSTEM_ID}</p>
                </div>
                <p className="text-red-600 text-xs mt-4">
                    💡 Make sure the contract is deployed and the ID is correct.
                </p>
            </div>
        )
    }

    const parsedData = parseTippingSystem(systemData || null)

    if (!parsedData) {
        return (
            <div className="p-6 bg-yellow-50 border-2 border-yellow-200 rounded-lg">
                <div className="flex items-center gap-2 mb-2">
                    <AlertCircle className="w-5 h-5 text-yellow-600" />
                    <p className="text-yellow-700 font-medium">Could not parse system data</p>
                </div>
                <p className="text-yellow-600 text-sm mt-2">
                    The object exists but the data structure might be different than expected.
                </p>
                <div className="mt-4 p-3 bg-yellow-100 rounded text-xs font-mono break-all">
                    <p className="font-semibold mb-1">Raw data:</p>
                    <pre>{JSON.stringify(systemData, null, 2)}</pre>
                </div>
            </div>
        )
    }

    const totalTips = parsedData.total_tips || 0
    const totalVolume = parsedData.total_volume || 0
    const historySize = parsedData.history.length || 0
    const creatorsRegistered = parsedData.profiles_registered || 0

    return (
        <div>
            <h2 className="text-2xl font-bold text-gray-800 mb-6 flex items-center gap-2">
                <BarChart3 className="w-6 h-6" />
                System Statistics
            </h2>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="bg-gradient-to-br from-blue-50 to-blue-100 rounded-lg p-6 border border-blue-200">
                    <div className="flex items-center justify-between mb-2">
                        <h3 className="text-sm font-medium text-blue-700">Total Tips</h3>
                        <TrendingUp className="w-5 h-5 text-blue-600" />
                    </div>
                    <p className="text-3xl font-bold text-blue-900">{totalTips}</p>
                </div>

                <div className="bg-gradient-to-br from-green-50 to-green-100 rounded-lg p-6 border border-green-200">
                    <div className="flex items-center justify-between mb-2">
                        <h3 className="text-sm font-medium text-green-700">Total Volume</h3>
                        <Coins className="w-5 h-5 text-green-600" />
                    </div>
                    <p className="text-3xl font-bold text-green-900">
                        {formatSui(totalVolume)} SUI
                    </p>
                </div>

                <div className="bg-gradient-to-br from-purple-50 to-purple-100 rounded-lg p-6 border border-purple-200">
                    <div className="flex items-center justify-between mb-2">
                        <h3 className="text-sm font-medium text-purple-700">Creators Registered</h3>
                        <TrendingDown className="w-5 h-5 text-purple-600" />
                    </div>
                    <p className="text-3xl font-bold text-purple-900">{creatorsRegistered}</p>
                    <p className="text-xs text-purple-700 mt-1">
                        Total tips recorded: {historySize}
                    </p>
                </div>
            </div>
        </div>
    )
}
