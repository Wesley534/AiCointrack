import { readContract, writeContract, waitForTransactionReceipt, type Config } from "@wagmi/core"
import { USDC_ADDRESS, ERC20_ABI, USDC_DECIMALS } from "./constants"
import { parseUsdc } from "./format"

/**
 * Get USDC balance for an address
 */
export async function getUsdcBalance(config: Config, address: string): Promise<bigint> {
  const balance = await readContract(config, {
    address: USDC_ADDRESS as `0x${string}`,
    abi: ERC20_ABI,
    functionName: "balanceOf",
    args: [address as `0x${string}`]
  })
  return balance
}

/**
 * Send USDC to another address
 */
export async function sendUsdc(
  config: Config,
  to: string,
  amount: string | number
): Promise<string> {
  const amountWei = parseUsdc(amount)
  
  const hash = await writeContract(config, {
    address: USDC_ADDRESS as `0x${string}`,
    abi: ERC20_ABI,
    functionName: "transfer",
    args: [to as `0x${string}`, amountWei]
  })

  // Wait for confirmation
  await waitForTransactionReceipt(config, { hash })

  return hash
}

/**
 * Helper to format USDC from wei
 */
export function formatUsdcFromWei(wei: bigint): number {
  return Number(wei) / Math.pow(10, USDC_DECIMALS)
}
