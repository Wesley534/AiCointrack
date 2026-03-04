export const BASE_CHAIN_ID = 8453

// USDC on Base mainnet
export const USDC_ADDRESS = "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"

// Your deployed PocketPal vault contract (add this after you deploy)
export const VAULT_CONTRACT_ADDRESS = ""

// Your FastAPI backend
export const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL 

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
  green: "#0052FF", // Base blue
  greenDim: "#0047B3",
  greenBg: "rgba(0,82,255,0.1)",
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

// Theme colors (Dark Mode) – aligned with mobile AppColors
export const darkTheme: Theme = {
  bg: "#0A0D12",
  surface: "#111620",
  card: "#161C28",
  border: "#1E2A3A",
  accent: "#0052FF", // Base blue
  accentDim: "#0047B3",
  purple: "#4F46E5", // AppColors.purple
  warning: "#D97706", // AppColors.warning
  danger: "#DC2626", // AppColors.danger
  text: "#E8EDF5",
  muted: "#6B7A90",
  // Aliases for compatibility
  green: "#0052FF",
  red: "#DC2626",
  mid: "#6B7A90",
  bg2: "#161C28",
  bg3: "#1E2A3A",
  greenBg: "rgba(0,82,255,0.1)",
  amberBg: "rgba(217,119,6,0.1)",
  redBg: "rgba(220,38,38,0.1)",
  indigoBg: "rgba(79,70,229,0.15)",
}

