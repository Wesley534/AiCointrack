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
  api.get("/api/v1/dashboard/miniapp")

// ── WALLET ────────────────────────────────────────────
export const getWalletAddress = () =>
  api.get("/api/v1/wallet/address")

export const getWithdrawDestinations = () =>
  api.get("/api/v1/wallet/destinations")

export const initiateWithdrawal = (data: {
  amount_usdc: number
  destination_type: "mpesa" | "bank"
  destination_id: string
}) => api.post("/api/v1/wallet/withdraw/initiate", data)

export const getWithdrawalStatus = (id: string) =>
  api.get(`/api/v1/wallet/withdraw/${id}/status`)

export const recordOnchainTx = (data: {
  tx_hash: string
  amount_usdc: number
  recipient?: string
  note?: string
  category?: string
}) => api.post("/api/v1/transactions/record", data)

// ── BUDGET ────────────────────────────────────────────
export const getCurrentBudget = () =>
  api.get("/api/v1/budgets/current")

// ── SAVINGS ───────────────────────────────────────────
export const getGoals = () =>
  api.get("/api/v1/savings-goals")

export const contributeToGoal = (goalId: string, data: {
  amount_usdc: number
  tx_hash: string
}) => api.post(`/api/v1/savings-goals/${goalId}/contribute`, data)

// ── TRANSACTIONS ──────────────────────────────────────
export const getTransactions = (params?: {
  limit?: number
  offset?: number
  source?: string
  month?: string
}) => api.get("/api/v1/transactions", { params })

export const createTransaction = (data: {
  amount: number
  description: string
  category_id?: string
  date: string
  source: "manual"
  note?: string
  currency?: string
}) => api.post("/api/v1/transactions/", data)

export const categorizeWithAI = (description: string, amount: number) =>
  api.post("/api/v1/transactions/ai-categorize", { description, amount })
