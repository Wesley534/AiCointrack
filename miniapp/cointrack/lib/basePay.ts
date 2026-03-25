// Lightweight wrapper around the Base Account Pay SDK (window.base)
export interface BasePaymentResult {
  id?: string
  [key: string]: unknown
}

export interface BasePaymentStatus {
  status?: string
  transactionHash?: string
  [key: string]: unknown
}

export interface BaseAccountSDK {
  pay: (opts: { amount: string; to: string; testnet?: boolean; payerInfo?: unknown }) => Promise<BasePaymentResult>
  getPaymentStatus: (opts: { id: string; testnet?: boolean }) => Promise<BasePaymentStatus>
}

function getBaseSdk(): BaseAccountSDK | undefined {
  if (typeof window === "undefined") return undefined
  return (window as unknown as Window & { base?: BaseAccountSDK }).base
}

export async function payWithBase(amount: string, to: string, testnet = true): Promise<BasePaymentResult> {
  const base = getBaseSdk()
  if (!base || typeof base.pay !== "function") {
    throw new Error("Base Pay SDK not available on window.base")
  }
  return base.pay({ amount, to, testnet })
}

export async function getBasePaymentStatus(id: string, testnet = true): Promise<BasePaymentStatus> {
  const base = getBaseSdk()
  if (!base || typeof base.getPaymentStatus !== "function") {
    throw new Error("Base Pay SDK not available on window.base")
  }
  return base.getPaymentStatus({ id, testnet })
}
