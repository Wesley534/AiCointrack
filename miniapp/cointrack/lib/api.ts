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
}) => api.post("/api/v1/transactions/onchain", {
  tx_hash: data.tx_hash,
  amount: data.amount_usdc,
  recipient: data.recipient,
  description: data.note,
  category: data.category,
  currency: "USDC",
})

export const recordOffchainTx = (data: {
  amount: number
  description: string
  source: "mpesa" | "bank" | "cash"
  category?: string
  reference_number?: string
  currency?: string
}) => api.post("/api/v1/transactions/offchain", {
  amount: data.amount,
  description: data.description,
  source: data.source,
  category: data.category,
  reference_number: data.reference_number,
  currency: data.currency || "KES",
  transaction_type: "expense",
})

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
}) => api.get("/api/v1/transactions/", { params })

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

// ── SHOPPING ──────────────────────────────────────────
export const getShoppingLists = () =>
  api.get("/api/v1/shopping-lists")

export const createShoppingList = (data: {
  name: string
  budget: number
}) => api.post("/api/v1/shopping-lists", data)

export const getShoppingList = (listId: number) =>
  api.get(`/api/v1/shopping-lists/${listId}`)

export const addShoppingItem = (listId: number, data: {
  name: string
  qty: number
  price: number
}) => api.post(`/api/v1/shopping-lists/${listId}/items`, data)
