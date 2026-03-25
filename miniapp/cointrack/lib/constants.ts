export const CONFIG = {
  DOMAIN: "app.aicointrack.xyz",
  URL: "https://app.aicointrack.xyz",
  CHAIN_ID: 84532,
} as const

export const BASE_CHAIN_ID = CONFIG.CHAIN_ID
export const APP_DOMAIN = CONFIG.DOMAIN
export const APP_URL = CONFIG.URL

// Base Sepolia USDC (Circle's official test USDC on Base Sepolia)
// Faucet: https://faucet.circle.com (select Base Sepolia)
export const USDC_ADDRESS = "0x036CbD53842c5426634e7929541eC2318f3dCF7e"

// Your deployed PocketPal vault contract (add this after you deploy)
export const VAULT_CONTRACT_ADDRESS = ""

// HashStore contract address for onchain fingerprint storage (set after deployment)
// HashStore contract address for onchain fingerprint storage (set after deployment)
// Leave empty for now if not deployed — Send flow records to DB first.
export const HASH_STORE_ADDRESS = "" as `0x${string}`

// Your FastAPI backend — set NEXT_PUBLIC_API_URL in .env.local
export const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_URL 

export const USDC_DECIMALS = 6

// ERC-20 minimal ABI for balance + transfer
export const ERC20_ABI = [
  {
    name: "balanceOf",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "account", type: "address" }],
    outputs: [{ name: "", type: "uint256" }]
  },
  {
    name: "transfer",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      { name: "to", type: "address" },
      { name: "amount", type: "uint256" }
    ],
    outputs: [{ name: "", type: "bool" }]
  },
  {
    name: "allowance",
    type: "function",
    stateMutability: "view",
    inputs: [
      { name: "owner", type: "address" },
      { name: "spender", type: "address" },
    ],
    outputs: [{ name: "", type: "uint256" }],
  },
  {
    name: "approve",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      { name: "spender", type: "address" },
      { name: "amount", type: "uint256" },
    ],
    outputs: [{ name: "", type: "bool" }],
  },
] as const

// HashStore ABI for onchain fingerprint storage
export const HASH_STORE_ABI = [
  {
    name: "storeHash",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      { name: "userId", type: "uint256" },
      { name: "txId", type: "uint256" },
      { name: "hash", type: "bytes32" },
    ],
    outputs: [],
  },
  {
    name: "storeBatch",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      { name: "userId", type: "uint256" },
      { name: "txIds", type: "uint256[]" },
      { name: "hashes", type: "bytes32[]" },
    ],
    outputs: [],
  },
  {
    name: "verifyHash",
    type: "function",
    stateMutability: "view",
    inputs: [
      { name: "txId", type: "uint256" },
      { name: "hash", type: "bytes32" },
    ],
    outputs: [{ name: "", type: "bool" }],
  },
] as const

// Theme and UI constants
export interface Theme {
  bg: string; card: string; border: string; text: string; muted: string
  bg2?: string; bg3?: string; borderMid?: string
  accent?: string; accentDim?: string; accentBg?: string
  positive?: string; positiveBg?: string
  indigo?: string; indigoBg?: string
  amber?: string; amberBg?: string
  red?: string; redBg?: string
  mid?: string; white?: string
  surface?: string; purple?: string; warning?: string; danger?: string
}

export const lightTheme: Theme = {
  bg: "#FFFFFF", bg2: "#F4F7F5", bg3: "#EBF5F0",
  card: "#FFFFFF", border: "#E0EDE7", borderMid: "#C8DDD4",
  accent: "#0052FF", accentDim: "#0047B3", accentBg: "rgba(0,82,255,0.08)",
  positive: "#059669", positiveBg: "rgba(5,150,105,0.1)",
  indigo: "#4F46E5", indigoBg: "#EEF2FF",
  amber: "#D97706", amberBg: "#FFF4E6",
  red: "#DC2626", redBg: "#FEF0F0",
  text: "#0F1F17", mid: "#4A6358", muted: "#8FA89C", white: "#FFFFFF",
}

export const darkTheme: Theme = {
  bg: "#0A0D12", surface: "#111620", card: "#161C28", border: "#1E2A3A",
  accent: "#0052FF", accentDim: "#0047B3",
  purple: "#4F46E5", warning: "#D97706", danger: "#DC2626",
  text: "#E8EDF5", muted: "#6B7A90",
  positive: "#10B981", positiveBg: "rgba(16,185,129,0.1)",
  red: "#DC2626", mid: "#6B7A90",
  bg2: "#161C28", bg3: "#1E2A3A",
  accentBg: "rgba(0,82,255,0.08)", amberBg: "rgba(217,119,6,0.1)",
  redBg: "rgba(220,38,38,0.1)", indigoBg: "rgba(79,70,229,0.15)",
}
