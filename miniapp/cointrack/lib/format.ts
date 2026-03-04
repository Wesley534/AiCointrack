import { USDC_DECIMALS } from "./constants"

/**
 * Format USDC amount from wei to human-readable
 */
export function formatUsdc(amount: bigint | number): string {
  const num = typeof amount === "bigint" 
    ? Number(amount) / Math.pow(10, USDC_DECIMALS)
    : amount
  return num.toFixed(2)
}

/**
 * Format KES currency
 */
export function formatKes(amount: number): string {
  return new Intl.NumberFormat("en-KE", {
    style: "currency",
    currency: "KES",
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount)
}

/**
 * Convert USDC to KES
 */
export function usdcToKes(usdc: number, rate: number = 130): number {
  return usdc * rate
}

/**
 * Convert KES to USDC
 */
export function kesToUsdc(kes: number, rate: number = 130): number {
  return kes / rate
}

/**
 * Parse USDC input to wei (bigint)
 */
export function parseUsdc(amount: string | number): bigint {
  const num = typeof amount === "string" ? parseFloat(amount) : amount
  return BigInt(Math.floor(num * Math.pow(10, USDC_DECIMALS)))
}

/**
 * Format date for display
 */
export function formatDate(date: Date | string): string {
  const d = typeof date === "string" ? new Date(date) : date
  return new Intl.DateTimeFormat("en-KE", {
    month: "short",
    day: "numeric",
    year: "numeric"
  }).format(d)
}

/**
 * Format date relative (e.g., "2 hours ago")
 */
export function formatRelativeDate(date: Date | string): string {
  const d = typeof date === "string" ? new Date(date) : date
  const now = new Date()
  const diffMs = now.getTime() - d.getTime()
  const diffMins = Math.floor(diffMs / 60000)
  const diffHours = Math.floor(diffMins / 60)
  const diffDays = Math.floor(diffHours / 24)

  if (diffMins < 1) return "Just now"
  if (diffMins < 60) return `${diffMins}m ago`
  if (diffHours < 24) return `${diffHours}h ago`
  if (diffDays < 7) return `${diffDays}d ago`
  
  return formatDate(d)
}

/**
 * Truncate wallet address
 */
export function truncateAddress(address: string): string {
  if (!address) return ""
  return `${address.slice(0, 6)}...${address.slice(-4)}`
}
