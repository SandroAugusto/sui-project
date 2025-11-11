import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { useSuiClient } from '@mysten/dapp-kit'
import { Search, User, Copy, Check, Send, Twitter } from 'lucide-react'
import { SUI_TYPE_ARG } from '@mysten/sui/utils'
import { TIPPING_PACKAGE_ID, TIPPING_SYSTEM_ID } from '../lib/constants'
import { formatSui } from '../lib/utils'

interface ProfileInfo {
    objectId: string
    address: string
    name: string
    bio: string
    twitter_handle: string
    total_received: number
    tips_received_count: number
}

const encoder = new TextEncoder()

export default function SearchProfiles() {
    const client = useSuiClient()
    const [searchTerm, setSearchTerm] = useState('')
    const [selectedProfile, setSelectedProfile] = useState<ProfileInfo | null>(null)
    const [copied, setCopied] = useState(false)

    const { data: registryId, isLoading: loadingRegistry } = useQuery({
        queryKey: ['twitter-registry-id', TIPPING_SYSTEM_ID],
        queryFn: async () => {
            const resp = await client.getObject({
                id: TIPPING_SYSTEM_ID,
                options: { showContent: true },
            })
            const id = resp.data?.content?.fields?.twitter_registry?.fields?.id?.id
            if (!id) throw new Error('Registry ID not found on TippingSystem')
            return id as string
        },
    })

    const searchProfiles = async (term: string, registry: string | null) => {
        if (!term) return []

        try {
            if (term.startsWith('0x')) {
                return fetchProfilesByAddress(term)
            }

            if (!registry) return []

            const normalizedHandle = term.replace('@', '').toLowerCase()
            if (!normalizedHandle) return []

            const resolved = await resolveHandle(normalizedHandle, registry)
            if (!resolved) return []

            return fetchProfilesByAddress(resolved)
        } catch (err) {
            console.error('Error searching profiles:', err)
            return []
        }
    }

    const { data: profiles, isLoading } = useQuery({
        queryKey: ['profiles-search', searchTerm, registryId],
        queryFn: async () => searchProfiles(searchTerm.trim(), registryId ?? null),
        enabled:
            searchTerm.trim().length > 0 &&
            (!!registryId || searchTerm.trim().startsWith('0x')),
    })

    const resolveHandle = async (
        handle: string,
        registry: string
    ): Promise<string | null> => {
        try {
            const nameBytes = Array.from(encoder.encode(handle))
            const field = await client.getDynamicFieldObject({
                parentId: registry,
                name: {
                    type: 'vector<u8>',
                    value: nameBytes,
                },
            })

            const value = field.data?.content?.fields?.value
            return typeof value === 'string' ? value : null
        } catch {
            return null
        }
    }

    const fetchProfilesByAddress = async (address: string) => {
        const owner = address.trim()
        if (!owner) return []

        const objects = await client.getOwnedObjects({
            owner,
            filter: {
                StructType: `${TIPPING_PACKAGE_ID}::types::UserProfile`,
            },
            options: {
                showContent: true,
                showType: true,
            },
        })
        return objects.data.map(parseProfile)
    }

    function parseProfile(obj: any): ProfileInfo {
        const fields = obj.data?.content?.fields || {}
        return {
            objectId: obj.data?.objectId || '',
            address: fields.address || '',
            name: fields.name || '',
            bio: fields.bio || '',
            twitter_handle: fields.twitter_handle || '',
            total_received: Number(fields.total_received || 0),
            tips_received_count: Number(fields.tips_received_count || 0),
        }
    }

    const copyAddress = async (address: string) => {
        try {
            await navigator.clipboard.writeText(address)
            setCopied(true)
            setTimeout(() => setCopied(false), 2000)
        } catch (err) {
            console.error('Failed to copy address:', err)
        }
    }

    const handleSelectProfile = (profile: ProfileInfo) => {
        setSelectedProfile(profile)
        setSearchTerm('')
    }

    return (
        <div className="max-w-2xl mx-auto">
            <h2 className="text-2xl font-bold text-gray-800 mb-6 flex items-center gap-2">
                <Search className="w-6 h-6" />
                Search Profiles
            </h2>

            <div className="space-y-4">
                <div>
                    <div className="relative">
                        <div className="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
                            <Search className="text-gray-400 w-5 h-5" />
                        </div>
                        <input
                            type="text"
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            placeholder="Search @twitter handle or 0x address"
                            className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent font-mono text-sm"
                        />
                    </div>
                    <p className="mt-1 text-xs text-gray-500">
                        💡 Example: <code className="font-mono">@creator</code> or <code className="font-mono">0xabc...</code>
                    </p>
                </div>

                {(isLoading || loadingRegistry) && (
                    <div className="text-center py-8">
                        <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
                        <p className="mt-2 text-gray-600">Searching...</p>
                    </div>
                )}

                {profiles && profiles.length > 0 && (
                    <div className="space-y-3">
                        {profiles.map((profile) => (
                            <div
                                key={profile.objectId}
                                className="bg-white border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow cursor-pointer"
                                onClick={() => handleSelectProfile(profile)}
                            >
                                <div className="flex items-start justify-between">
                                    <div className="flex-1">
                                        <h3 className="font-semibold text-gray-900 flex items-center gap-2">
                                            <User className="w-4 h-4" />
                                            {profile.name || 'Unnamed'}
                                        </h3>
                                        <p className="text-sm text-gray-600 mt-1 font-mono break-all">
                                            {profile.address}
                                        </p>
                                        {profile.bio && (
                                            <p className="text-sm text-gray-700 mt-2 italic">
                                                "{profile.bio}"
                                            </p>
                                        )}
                                        {profile.twitter_handle && (
                                            <div className="flex items-center gap-1 mt-2 text-sm text-blue-600">
                                                <Twitter className="w-4 h-4" />
                                                <a
                                                    href={`https://twitter.com/${profile.twitter_handle.replace('@', '')}`}
                                                    target="_blank"
                                                    rel="noopener noreferrer"
                                                    className="hover:underline"
                                                    onClick={(e) => e.stopPropagation()}
                                                >
                                                    @{profile.twitter_handle.replace('@', '')}
                                                </a>
                                            </div>
                                        )}
                                        <div className="flex items-center gap-4 mt-3 text-xs text-gray-500">
                                            <span>💰 {formatSui(profile.total_received)} SUI received</span>
                                            <span>🎁 {profile.tips_received_count} tips</span>
                                        </div>
                                    </div>
                                    <button
                                        onClick={(e) => {
                                            e.stopPropagation()
                                            copyAddress(profile.address)
                                        }}
                                        className="text-indigo-600 hover:text-indigo-700 p-2"
                                    >
                                        {copied ? (
                                            <Check className="w-4 h-4" />
                                        ) : (
                                            <Copy className="w-4 h-4" />
                                        )}
                                    </button>
                                </div>
                            </div>
                        ))}
                    </div>
                )}

                {profiles && profiles.length === 0 && searchTerm && !isLoading && (
                    <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 text-center">
                        <p className="text-yellow-700">No profile found for this search.</p>
                        <p className="text-yellow-600 text-sm mt-1">
                            Make sure the handle was registered (lowercase, without @) or that the wallet owns a profile from this contract.
                        </p>
                    </div>
                )}

                {selectedProfile && (
                    <div className="bg-indigo-50 border-2 border-indigo-200 rounded-lg p-6 mt-4">
                        <h3 className="font-bold text-indigo-900 mb-4 flex items-center gap-2">
                            <User className="w-5 h-5" />
                            Selected Profile
                        </h3>
                        <div className="space-y-2">
                            <div>
                                <p className="text-sm font-semibold text-gray-700">Handle:</p>
                                <p className="text-gray-900">@{selectedProfile.twitter_handle.replace('@', '')}</p>
                            </div>
                            <div>
                                <p className="text-sm font-semibold text-gray-700">Address:</p>
                                <p className="font-mono text-gray-900 break-all">{selectedProfile.address}</p>
                            </div>
                            <div>
                                <p className="text-sm font-semibold text-gray-700">Bio:</p>
                                <p className="text-gray-900">{selectedProfile.bio || '—'}</p>
                            </div>
                        </div>
                        <button
                            onClick={() => setSelectedProfile(null)}
                            className="mt-4 text-sm text-indigo-600 hover:text-indigo-700"
                        >
                            Close
                        </button>
                    </div>
                )}
            </div>
        </div>
    )
}
