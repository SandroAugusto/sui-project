import { useState, useEffect } from 'react'
import { useCurrentAccount } from '@mysten/dapp-kit'
import { ConnectButton } from '@mysten/dapp-kit'
import { Wallet, UserPlus, Send, BarChart3, History, Search, Edit } from 'lucide-react'
import CreateProfile from './components/CreateProfile'
import SendTip from './components/SendTip'
import Statistics from './components/Statistics'
import HistoryView from './components/HistoryView'
import SearchProfiles from './components/SearchProfiles'
import EditProfile from './components/EditProfile'
import WalletBalance from './components/WalletBalance'

function App() {
  const account = useCurrentAccount()
  const [activeTab, setActiveTab] = useState<'create' | 'send' | 'search' | 'edit' | 'stats' | 'history'>('create')

  // Check for profile parameter in URL and redirect to send tab
  const [profileAddressFromUrl, setProfileAddressFromUrl] = useState<string | null>(null)

  useEffect(() => {
    const urlParams = new URLSearchParams(window.location.search)
    const profileAddress = urlParams.get('profile')
    if (profileAddress) {
      setProfileAddressFromUrl(profileAddress)
      setActiveTab('send')
      // Clean up URL to remove the parameter after reading it
      const newUrl = window.location.pathname
      window.history.replaceState({}, '', newUrl)
    }
  }, [])

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      <div className="container mx-auto px-4 py-8">
        {/* Header */}
        <header className="mb-8">
          <div className="flex items-center justify-between bg-white rounded-lg shadow-md p-6">
            <div className="flex items-center gap-3">
              <Wallet className="w-8 h-8 text-indigo-600" />
              <h1 className="text-3xl font-bold text-gray-800">Sui Tipping System</h1>
            </div>
            <ConnectButton />
          </div>
        </header>

        {!account ? (
          <div className="bg-white rounded-lg shadow-md p-12 text-center">
            <Wallet className="w-16 h-16 text-gray-400 mx-auto mb-4" />
            <h2 className="text-2xl font-semibold text-gray-700 mb-2">Connect Your Wallet</h2>
            <p className="text-gray-500 mb-6">Please connect your Sui wallet to get started</p>
          </div>
        ) : (
          <>
            {/* Wallet Balance */}
            <WalletBalance />

            {/* Navigation Tabs */}
            <div className="bg-white rounded-lg shadow-md mb-6">
              <div className="flex border-b border-gray-200 flex-wrap">
                <button
                  onClick={() => setActiveTab('create')}
                  className={`flex-1 min-w-[120px] px-4 py-4 text-center font-medium transition-colors ${activeTab === 'create'
                    ? 'text-indigo-600 border-b-2 border-indigo-600'
                    : 'text-gray-600 hover:text-gray-900'
                    }`}
                >
                  <UserPlus className="w-5 h-5 inline-block mr-2" />
                  Create Profile
                </button>
                <button
                  onClick={() => setActiveTab('search')}
                  className={`flex-1 min-w-[120px] px-4 py-4 text-center font-medium transition-colors ${activeTab === 'search'
                    ? 'text-indigo-600 border-b-2 border-indigo-600'
                    : 'text-gray-600 hover:text-gray-900'
                    }`}
                >
                  <Search className="w-5 h-5 inline-block mr-2" />
                  Search
                </button>
                <button
                  onClick={() => setActiveTab('edit')}
                  className={`flex-1 min-w-[120px] px-4 py-4 text-center font-medium transition-colors ${activeTab === 'edit'
                    ? 'text-indigo-600 border-b-2 border-indigo-600'
                    : 'text-gray-600 hover:text-gray-900'
                    }`}
                >
                  <Edit className="w-5 h-5 inline-block mr-2" />
                  Edit Profile
                </button>
                <button
                  onClick={() => setActiveTab('send')}
                  className={`flex-1 min-w-[120px] px-4 py-4 text-center font-medium transition-colors ${activeTab === 'send'
                    ? 'text-indigo-600 border-b-2 border-indigo-600'
                    : 'text-gray-600 hover:text-gray-900'
                    }`}
                >
                  <Send className="w-5 h-5 inline-block mr-2" />
                  Send Tip
                </button>
                <button
                  onClick={() => setActiveTab('stats')}
                  className={`flex-1 min-w-[120px] px-4 py-4 text-center font-medium transition-colors ${activeTab === 'stats'
                    ? 'text-indigo-600 border-b-2 border-indigo-600'
                    : 'text-gray-600 hover:text-gray-900'
                    }`}
                >
                  <BarChart3 className="w-5 h-5 inline-block mr-2" />
                  Statistics
                </button>
                <button
                  onClick={() => setActiveTab('history')}
                  className={`flex-1 min-w-[120px] px-4 py-4 text-center font-medium transition-colors ${activeTab === 'history'
                    ? 'text-indigo-600 border-b-2 border-indigo-600'
                    : 'text-gray-600 hover:text-gray-900'
                    }`}
                >
                  <History className="w-5 h-5 inline-block mr-2" />
                  History
                </button>
              </div>
            </div>

            {/* Tab Content */}
            <div className="bg-white rounded-lg shadow-md p-6">
              {activeTab === 'create' && <CreateProfile />}
              {activeTab === 'search' && <SearchProfiles />}
              {activeTab === 'edit' && <EditProfile />}
              {activeTab === 'send' && <SendTip prefillAddress={profileAddressFromUrl} />}
              {activeTab === 'stats' && <Statistics />}
              {activeTab === 'history' && <HistoryView />}
            </div>
          </>
        )}
      </div>
    </div>
  )
}

export default App
