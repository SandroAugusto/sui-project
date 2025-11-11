import { useState, useEffect } from 'react'
import { useSignAndExecuteTransaction } from '@mysten/dapp-kit'
import { Transaction } from '@mysten/sui/transactions'
import { Edit, Loader2, Save } from 'lucide-react'
import { TIPPING_PACKAGE_ID, TIPPING_SYSTEM_ID } from '../lib/constants'
import { useProfile } from '../hooks/useProfile'

const encoder = new TextEncoder()

export default function EditProfile() {
    const { data: profile, isLoading: loadingProfile } = useProfile()
    const [bio, setBio] = useState('')
    const [twitter, setTwitter] = useState('')
    const [loading, setLoading] = useState(false)
    const [error, setError] = useState<string | null>(null)
    const [success, setSuccess] = useState(false)
    const { mutate: signAndExecute } = useSignAndExecuteTransaction()

    useEffect(() => {
        if (profile?.data?.content) {
            const fields = (profile.data.content as any).fields
            setBio(fields.bio || '')
            setTwitter(fields.twitter_handle || '')
        }
    }, [profile])

    const handleUpdateTwitter = async () => {
        if (!profile?.data?.objectId) {
            setError('No profile found')
            return
        }

        const normalized = twitter.replace('@', '').toLowerCase()
        if (!normalized) {
            setError('Please provide a valid handle')
            return
        }

        setLoading(true)
        setError(null)
        setSuccess(false)

        try {
            const tx = new Transaction()
            const system = tx.object(TIPPING_SYSTEM_ID)
            const profileObj = tx.object(profile.data.objectId)

            tx.moveCall({
                target: `${TIPPING_PACKAGE_ID}::profile::update_twitter`,
                arguments: [
                    system,
                    profileObj,
                    tx.pure.vector('u8', Array.from(encoder.encode(normalized))),
                ],
            })

            signAndExecute(
                { transaction: tx },
                {
                    onSuccess: () => {
                        setSuccess(true)
                        setTimeout(() => setSuccess(false), 3000)
                    },
                    onError: (err) => {
                        const errorMsg = err.message || 'Failed to update Twitter handle'
                        if (errorMsg.includes('gas') || errorMsg.includes('No valid gas coins')) {
                            setError('Insufficient SUI for gas fees. Please request test tokens from the faucet.')
                        } else {
                            setError(errorMsg)
                        }
                    },
                    onSettled: () => setLoading(false),
                }
            )
        } catch (err: any) {
            setError(err.message || 'Failed to update Twitter handle')
            setLoading(false)
        }
    }

    const handleUpdateBio = async () => {
        if (!profile?.data?.objectId) {
            setError('No profile found')
            return
        }

        setLoading(true)
        setError(null)
        setSuccess(false)

        try {
            const tx = new Transaction()
            const profileObj = tx.object(profile.data.objectId)

            tx.moveCall({
                target: `${TIPPING_PACKAGE_ID}::profile::update_bio`,
                arguments: [
                    profileObj,
                    tx.pure.vector('u8', Array.from(encoder.encode(bio))),
                ],
            })

            signAndExecute(
                { transaction: tx },
                {
                    onSuccess: () => {
                        setSuccess(true)
                        setTimeout(() => setSuccess(false), 3000)
                    },
                    onError: (err) => {
                        const errorMsg = err.message || 'Failed to update bio'
                        if (errorMsg.includes('gas') || errorMsg.includes('No valid gas coins')) {
                            setError('Insufficient SUI for gas fees. Please request test tokens from the faucet.')
                        } else {
                            setError(errorMsg)
                        }
                    },
                    onSettled: () => setLoading(false),
                }
            )
        } catch (err: any) {
            setError(err.message || 'Failed to update bio')
            setLoading(false)
        }
    }

    if (loadingProfile) {
        return (
            <div className="text-center py-12">
                <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
                <p className="mt-4 text-gray-600">Loading profile...</p>
            </div>
        )
    }

    if (!profile?.data) {
        return (
            <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-6 text-center">
                <p className="text-yellow-700">You need to create a profile first</p>
                <p className="text-yellow-600 text-sm mt-2">Go to the "Create Profile" tab to get started</p>
            </div>
        )
    }

    const currentFields = (profile.data.content as any)?.fields || {}
    const currentBio = currentFields.bio || ''
    const currentTwitter = currentFields.twitter_handle || ''
    const currentAddress = currentFields.address || ''

    const tipPageUrl = typeof window !== 'undefined'
        ? `${window.location.origin}${window.location.pathname}?profile=${currentAddress}`
        : ''

    return (
        <div className="max-w-md mx-auto">
            <h2 className="text-2xl font-bold text-gray-800 mb-6 flex items-center gap-2">
                <Edit className="w-6 h-6" />
                Edit Your Profile
            </h2>

            <div className="space-y-6">
                <div>
                    <label htmlFor="bio" className="block text-sm font-medium text-gray-700 mb-2">
                        Bio / Description
                    </label>
                    <textarea
                        id="bio"
                        value={bio || currentBio}
                        onChange={(e) => setBio(e.target.value)}
                        placeholder="Tell people why they should tip you!"
                        rows={5}
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent resize-none mb-2"
                        disabled={loading}
                    />
                    <button
                        onClick={handleUpdateBio}
                        disabled={loading || (bio || '') === currentBio}
                        className="w-full bg-indigo-600 text-white py-2 px-4 rounded-lg font-medium hover:bg-indigo-700 disabled:bg-gray-400 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                    >
                        {loading ? (
                            <>
                                <Loader2 className="w-4 h-4 animate-spin" />
                                Updating...
                            </>
                        ) : (
                            <>
                                <Save className="w-4 h-4" />
                                Update Bio
                            </>
                        )}
                    </button>
                    <p className="mt-1 text-xs text-gray-500">
                        This text is shown when people view your profile.
                    </p>
                </div>

                <div>
                    <label htmlFor="twitter" className="block text-sm font-medium text-gray-700 mb-2">
                        Twitter/X Handle
                    </label>
                    <div className="flex items-center gap-2">
                        <span className="text-gray-500">@</span>
                        <input
                            id="twitter"
                            type="text"
                            value={twitter || currentTwitter}
                            onChange={(e) => setTwitter(e.target.value.replace('@', ''))}
                            placeholder="username"
                            className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                            disabled={loading}
                        />
                        <button
                            onClick={handleUpdateTwitter}
                            disabled={loading || (twitter || '') === currentTwitter}
                            className="bg-indigo-600 text-white px-4 py-2 rounded-lg font-medium hover:bg-indigo-700 disabled:bg-gray-400 disabled:cursor-not-allowed flex items-center gap-2"
                        >
                            {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
                        </button>
                    </div>
                    <p className="mt-1 text-xs text-gray-500">
                        Handles are stored in lowercase without @ and must be unique.
                    </p>
                </div>

                {tipPageUrl && (
                    <div className="bg-indigo-50 border border-indigo-200 rounded-lg p-4">
                        <p className="text-sm font-semibold text-indigo-900 mb-2">
                            🎁 Your Tip Page URL
                        </p>
                        <div className="flex items-center gap-2">
                            <input
                                type="text"
                                value={tipPageUrl}
                                readOnly
                                className="flex-1 px-3 py-2 bg-white border border-indigo-300 rounded text-sm font-mono text-gray-700"
                            />
                            <button
                                onClick={() => {
                                    navigator.clipboard.writeText(tipPageUrl)
                                    setSuccess(true)
                                    setTimeout(() => setSuccess(false), 2000)
                                }}
                                className="bg-indigo-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-indigo-700"
                            >
                                Copy
                            </button>
                        </div>
                        <p className="text-xs text-indigo-700 mt-2">
                            Share this link so fans can tip you directly.
                        </p>
                    </div>
                )}

                {error && (
                    <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
                        {error}
                    </div>
                )}

                {success && (
                    <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg">
                        Profile updated successfully!
                    </div>
                )}
            </div>
        </div>
    )
}
