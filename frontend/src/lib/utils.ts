import type { SuiObjectResponse } from '@mysten/sui/client'

export interface TippingSystemData {
  total_tips: number
  total_volume: number
  profiles_registered: number
  history: TipData[]
}

export interface TipData {
  from: string
  to: string
  amount: string | number
  message: string
  timestamp: string | number
}

/**
 * Parse TippingSystem object data from Sui
 */
export function parseTippingSystem(object: SuiObjectResponse | null): TippingSystemData | null {
  if (!object?.data?.content) {
    console.error('No content in object response:', object)
    return null
  }

  const content = object.data.content
  if (content.dataType !== 'moveObject') {
    console.error('Object is not a moveObject:', content.dataType)
    return null
  }

  const fields = content.fields as any
  console.log('Parsing TippingSystem fields:', fields)

  // Handle different field name formats (snake_case vs camelCase)
  const totalTips = Number(fields.total_tips || fields.totalTips || 0)
  const totalVolume = Number(fields.total_volume || fields.totalVolume || 0)
  const history = parseHistory(fields.history || [])
  const profilesRegistered = Number(
    fields.twitter_registry?.fields?.size ||
      fields.twitterRegistry?.fields?.size ||
      0,
  )

  return {
    total_tips: totalTips,
    total_volume: totalVolume,
    profiles_registered: profilesRegistered,
    history: history,
  }
}

/**
 * Parse history vector from Move
 */
function parseHistory(history: any[]): TipData[] {
  if (!Array.isArray(history)) return []

  return history.map((tip: any) => {
    // Handle both nested fields and direct properties
    const fields = tip.fields || tip
    
    return {
      from: String(fields.from || ''),
      to: String(fields.to || ''),
      amount: fields.amount || 0,
      message: String(fields.message || ''),
      timestamp: fields.timestamp || 0,
    }
  })
}

/**
 * Convert MIST to SUI
 */
export function mistToSui(mist: number): number {
  return mist / 1_000_000_000
}

/**
 * Format SUI amount for display
 */
export function formatSui(amount: number): string {
  return mistToSui(amount).toFixed(9).replace(/\.?0+$/, '')
}
