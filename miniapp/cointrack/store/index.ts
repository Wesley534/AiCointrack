import { create } from "zustand"

interface AppState {
  // Auth
  address: string | null
  jwt: string | null
  user: any | null
  setAuth: (address: string, jwt: string, user: any) => void

  // Wallet
  balanceUsdc: number
  balanceKes: number
  usdKesRate: number
  setWalletBalance: (usdc: number, kes: number, rate: number) => void

  // UI
  activeTab: "home" | "wallet" | "budget" | "savings" | "transactions"
  setActiveTab: (tab: AppState["activeTab"]) => void
  activeSheet: string | null
  setActiveSheet: (sheet: string | null) => void

  // Theme
  theme: "light" | "dark"
  setTheme: (theme: "light" | "dark") => void
}

export const useAppStore = create<AppState>(set => ({
  address: null,
  jwt: null,
  user: null,
  setAuth: (address, jwt, user) => set({ address, jwt, user }),

  balanceUsdc: 0,
  balanceKes: 0,
  usdKesRate: 130,
  setWalletBalance: (usdc, kes, rate) =>
    set({ balanceUsdc: usdc, balanceKes: kes, usdKesRate: rate }),

  activeTab: "home",
  setActiveTab: tab => set({ activeTab: tab }),
  activeSheet: null,
  setActiveSheet: sheet => set({ activeSheet: sheet }),

  theme: "light",
  setTheme: theme => set({ theme }),
}))
