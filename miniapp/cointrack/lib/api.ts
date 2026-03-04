import axios from "axios"
import { API_BASE_URL } from "./constants"

const api = axios.create({ baseURL: API_BASE_URL })

// Attach JWT to every request
api.interceptors.request.use(config => {
  const token = localStorage.getItem("pocketpal_jwt")
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

// ── AUTH ──────────────────────────────────────────────
export const getNonce = async (): Promise<string> => {
  const { data } = await api.get("/api/v1/auth/nonce")
  if (typeof data === "string") return data
  return (data as { nonce?: string })?.nonce ?? ""
}

export const walletLogin = (address: string, signature: string, message: string) =>
  api.post("/api/v1/auth/wallet", { address, signature, message })

export const getMe = () =>
  api.get("/api/v1/auth/me")

// ── HOME ──────────────────────────────────────────────
export const getHomeData = () =>
  api.get("/miniapp/home")

// ── WALLET ────────────────────────────────────────────
export const getWalletAddress = () =>
  api.get("/wallet/address")

export const getWithdrawDestinations = () =>
  api.get("/withdraw/destinations")

export const initiateWithdrawal = (data: {
  amount_usdc: number
  destination_type: "mpesa" | "bank"
  destination_id: string
}) => api.post("/withdraw/initiate", data)

export const getWithdrawalStatus = (id: string) =>
  api.get(`/withdraw/${id}/status`)

export const recordOnchainTx = (data: {
  tx_hash: string
  amount_usdc: number
  recipient?: string
  note?: string
  category?: string
}) => api.post("/transactions/record", data)

// ── BUDGET ────────────────────────────────────────────
export const getCurrentBudget = () =>
  api.get("/budget/current")

// ── SAVINGS ───────────────────────────────────────────
export const getGoals = () =>
  api.get("/goals")

export const contributeToGoal = (goalId: string, data: {
  amount_usdc: number
  tx_hash: string
}) => api.post(`/goals/${goalId}/contribute`, data)

// ── TRANSACTIONS ──────────────────────────────────────
export const getTransactions = (params?: {
  limit?: number
  offset?: number
  source?: string
  month?: string
}) => api.get("/transactions", { params })

export const createTransaction = (data: {
  amount: number
  description: string
  category_id: string
  date: string
  source: "manual"
  note?: string
}) => api.post("/transaction", data)

export const categorizeWithAI = (description: string, amount: number) =>
  api.post("/ai/categorize", { description, amount })
