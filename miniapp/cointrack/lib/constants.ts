export const BASE_CHAIN_ID = 8453

// USDC on Base mainnet
export const USDC_ADDRESS = "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"

// Your deployed PocketPal vault contract (add this after you deploy)
export const VAULT_CONTRACT_ADDRESS = ""

// Your FastAPI backend
export const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "https://api.cointrack.xyz"

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
  }
] as const

// Unified theme type
export interface Theme {
  bg: string
  card: string
  border: string
  text: string
  muted: string
  // Light theme specific
  bg2?: string
  bg3?: string
  borderMid?: string
  green?: string
  greenDim?: string
  greenBg?: string
  indigo?: string
  indigoBg?: string
  amber?: string
  amberBg?: string
  red?: string
  redBg?: string
  mid?: string
  white?: string
  // Dark theme specific
  surface?: string
  accent?: string
  accentDim?: string
  purple?: string
  warning?: string
  danger?: string
}

// Theme colors (Light Mode - Mint Ledger Palette)
export const lightTheme: Theme = {
  bg: "#FFFFFF",
  bg2: "#F4F7F5",
  bg3: "#EBF5F0",
  card: "#FFFFFF",
  border: "#E0EDE7",
  borderMid: "#C8DDD4",
  green: "#00A86B",
  greenDim: "#007A4D",
  greenBg: "#E8F9F2",
  indigo: "#4F46E5",
  indigoBg: "#EEF2FF",
  amber: "#D97706",
  amberBg: "#FFF4E6",
  red: "#DC2626",
  redBg: "#FEF0F0",
  text: "#0F1F17",
  mid: "#4A6358",
  muted: "#8FA89C",
  white: "#FFFFFF",
}

// Theme colors (Dark Mode)
export const darkTheme: Theme = {
  bg: "#0A0D12",
  surface: "#111620",
  card: "#161C28",
  border: "#1E2A3A",
  accent: "#00E5A0",
  accentDim: "#00A372",
  purple: "#7C6AFA",
  warning: "#F59E0B",
  danger: "#EF4444",
  text: "#E8EDF5",
  muted: "#6B7A90",
  // Aliases for compatibility
  green: "#00E5A0",
  red: "#EF4444",
  mid: "#6B7A90",
  bg2: "#161C28",
  bg3: "#1E2A3A",
  greenBg: "rgba(0,229,160,0.1)",
  amberBg: "rgba(245,158,11,0.1)",
  redBg: "rgba(239,68,68,0.1)",
  indigoBg: "rgba(124,106,250,0.15)",
}

