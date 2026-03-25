import {
  readContract,
  writeContract,
  waitForTransactionReceipt,
  type Config,
} from "@wagmi/core"
import { keccak256, toHex } from "viem"
import {
  USDC_ADDRESS,
  ERC20_ABI,
  USDC_DECIMALS,
  HASH_STORE_ADDRESS,
  HASH_STORE_ABI,
} from "./constants"
import { parseUsdc } from "./format"

// ── Get USDC balance ───────────────────────────────────────────────
export async function getUsdcBalance(
  config: Config,
  address: string
): Promise<bigint> {
  return readContract(config, {
    address: USDC_ADDRESS,
    abi: ERC20_ABI,
    functionName: "balanceOf",
    args: [address as `0x${string}`],
  })
}

// ── Send USDC ──────────────────────────────────────────────
export async function sendUsdc(
  config: Config,
  to: string,
  amount: string | number
): Promise<`0x${string}`> {
  if (!to.startsWith("0x") || to.length !== 42) {
    throw new Error("Invalid recipient address")
  }
  const amountWei = parseUsdc(amount)
  if (amountWei === BigInt(0)) throw new Error("Amount must be greater than 0")

  let hash: `0x${string}`
  try {
    hash = await writeContract(config, {
      address: USDC_ADDRESS,
      abi: ERC20_ABI,
      functionName: "transfer",
      args: [to as `0x${string}`, amountWei],
    })
  } catch (err: unknown) {
    // Surface a helpful error message for common wallet/chain issues
    const hint = `writeContract failed — check wallet network (should be Base Sepolia), ensure your wallet is unlocked, has gas, and that USDC (${USDC_ADDRESS}) exists on that network.`
    let errMessage = ""
    if (err instanceof Error) errMessage = err.message
    else {
      try {
        errMessage = String(err ?? "")
      } catch {
        errMessage = "Unknown error"
      }
    }
    console.error("sendUsdc writeContract error:", err)
    throw new Error(errMessage ? `${errMessage} — ${hint}` : `sendUsdc failed — ${hint}`)
  }

  await waitForTransactionReceipt(config, {
    hash,
    confirmations: 1,
    timeout: 120_000,
    pollingInterval: 10_000,
    retryCount: 10,
  })

  return hash
}

// ── Generate transaction fingerprint ───────────────────────────────
export function generateTxHash(data: Record<string, unknown>): `0x${string}` {
  const sorted = JSON.stringify(data, Object.keys(data).sort())
  return keccak256(toHex(sorted))
}

// ── Store fingerprint on HashStore contract ────────────────────────
export async function storeHashOnChain(
  config: Config,
  userId: number,
  txId: number,
  txData: Record<string, unknown>
): Promise<`0x${string}`> {
  if (!HASH_STORE_ADDRESS) {
    throw new Error("HASH_STORE_ADDRESS not set")
  }

  const fingerprint = generateTxHash(txData)

  const hash = await writeContract(config, {
    address: HASH_STORE_ADDRESS,
    abi: HASH_STORE_ABI,
    functionName: "storeHash",
    args: [BigInt(userId), BigInt(txId), fingerprint],
  })

  await waitForTransactionReceipt(config, {
    hash,
    confirmations: 1,
    timeout: 120_000,
    pollingInterval: 10_000,
    retryCount: 10,
  })

  return fingerprint
}

export function formatUsdcFromWei(wei: bigint): number {
  return Number(wei) / Math.pow(10, USDC_DECIMALS)
}
