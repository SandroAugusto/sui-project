import { useState } from 'react'
import { useSignAndExecuteTransaction } from '@mysten/dapp-kit'
import { Transaction } from '@mysten/sui/transactions'
import { UserPlus, Loader2 } from 'lucide-react'
import { TIPPING_PACKAGE_ID, TIPPING_SYSTEM_ID } from '../lib/constants'
import { useProfile } from '../hooks/useProfile'

export default function CreateProfile() {
    const { data: existingProfile, isLoading: loadingProfile } = useProfile()
    const [bio, setBio] = useState('')
    const [twitter, setTwitter] = useState('')
    const [loading, setLoading] = useState(false)
    const [error, setError] = useState<string | null>(null)
    const [success, setSuccess] = useState(false)
    const { mutate: signAndExecute } = useSignAndExecuteTransaction()

    const handleCreateProfile = async () => {
        if (existingProfile?.data) {
            setError('This wallet already has a profile. Edit it instead of creating a new one.')
            return
        }

        if (!twitter.trim()) {
            setError('Please add your Twitter handle')
            return
        }

        if (!twitter.trim()) {
            setError('Please add your Twitter handle')
            return
        }

        const normalizedHandle = twitter.replace('@', '').toLowerCase()
        if (!normalizedHandle) {
            setError('Invalid Twitter handle')
            return
        }

        const displayName = normalizedHandle ? `@${normalizedHandle}` : '@user'

        setLoading(true)
        setError(null)
        setSuccess(false)

        try {
            const tx = new Transaction()
            const system = tx.object(TIPPING_SYSTEM_ID)

            tx.moveCall({
                target: `${TIPPING_PACKAGE_ID}::profile::create_profile_with_system`,
                arguments: [
                    system,
                    tx.pure.string(displayName),
                    tx.pure.string(bio || ''),
                    tx.pure.string(normalizedHandle),
                ],
            })

            signAndExecute(
                {
                    transaction: tx,
                },
                {
                    onSuccess: () => {
                        setSuccess(true)
                        setBio('')
                        setTwitter('')
                        setTimeout(() => setSuccess(false), 3000)
                    },
                    onError: (err) => {
                        const errorMsg = err.message || 'Failed to create profile'
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
            setError(err.message || 'Failed to create profile')
            setLoading(false)
        }
    }

    return (
        <div className="max-w-md mx-auto">
            <h2 className="text-2xl font-bold text-gray-800 mb-6 flex items-center gap-2">
                <UserPlus className="w-6 h-6" />
                Create Your Profile
            </h2>

            <div className="space-y-4">
                {existingProfile?.data && (
                    <div className="bg-indigo-50 border border-indigo-200 text-indigo-800 px-4 py-3 rounded-lg text-sm">
                        This wallet already has a profile. Use the Edit tab to update it.
                    </div>
                )}

                <div>
                    <label htmlFor="bio" className="block text-sm font-medium text-gray-700 mb-2">
                        Bio / Description
                    </label>
                    <textarea
                        id="bio"
                        value={bio}
                        onChange={(e) => setBio(e.target.value)}
                        placeholder="Tell people why they should tip you! What do you create? What value do you provide?"
                        rows={4}
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent resize-none"
                        disabled={loading}
                    />
                    <p className="mt-1 text-xs text-gray-500">
                        This will be visible to others when they search for your profile
                    </p>
                </div>

                <div>
                    <label htmlFor="twitter" className="block text-sm font-medium text-gray-700 mb-2">
                        Twitter/X Handle *
                    </label>
                    <div className="flex items-center gap-2">
                        <span className="text-gray-500">@</span>
                        <input
                            id="twitter"
                            type="text"
                            value={twitter}
                            onChange={(e) => setTwitter(e.target.value.replace('@', ''))}
                            placeholder="username"
                            className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                            disabled={loading}
                        />
                    </div>
                    <p className="mt-1 text-xs text-gray-500">
                        We store it in lowercase without @ so others can find you easily
                    </p>
                </div>

                {error && (
                    <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
                        {error}
                    </div>
                )}

                {success && (
                    <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg">
                        Profile created successfully!
                    </div>
                )}

                <button
                    onClick={handleCreateProfile}
                    disabled={loading || loadingProfile || !!existingProfile?.data || !twitter.trim()}
                    className="w-full bg-indigo-600 text-white py-3 px-4 rounded-lg font-medium hover:bg-indigo-700 disabled:bg-gray-400 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                >
                    {loading ? (
                        <>
                            <Loader2 className="w-5 h-5 animate-spin" />
                            Creating...
                        </>
                    ) : (
                        <>
                            <UserPlus className="w-5 h-5" />
                            Create Profile
                        </>
                    )}
                </button>
            </div>
        </div>
    )
}
