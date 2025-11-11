import { useQuery } from '@tanstack/react-query'
import { useSuiClient, useCurrentAccount } from '@mysten/dapp-kit'
import { TIPPING_PACKAGE_ID } from '../lib/constants'

export function useProfile(address?: string) {
  const client = useSuiClient()
  const account = useCurrentAccount()
  const targetAddress = address || account?.address

  return useQuery({
    queryKey: ['profile', targetAddress],
    queryFn: async () => {
      if (!targetAddress) return null

      // Get all objects owned by the address
      const objects = await client.getOwnedObjects({
        owner: targetAddress,
        filter: {
          StructType: `${TIPPING_PACKAGE_ID}::types::UserProfile`,
        },
        options: {
          showContent: true,
          showType: true,
        },
      })

      if (objects.data.length === 0) return null

      // Return the first profile found
      return objects.data[0]
    },
    enabled: !!targetAddress,
  })
}

