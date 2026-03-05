import { create } from "zustand"
import { persist } from "zustand/middleware"

const STORAGE_KEY = "cointrack_theme"

function getStoredTheme(): "light" | "dark" {
  if (typeof window === "undefined") return "dark"
  const s = localStorage.getItem(STORAGE_KEY)
  return s === "light" || s === "dark" ? s : "dark"
}

interface AppState {
  // Hydration state
  _hasHydrated: boolean
  setHasHydrated: (val: boolean) => void

  // Auth
  address: string | null
  jwt: string | null
  user: any | null
  setAuth: (address: string, jwt: string, user: any) => void
  logout: () => void

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

export const useAppStore = create<AppState>()(
  persist(
    set => ({
      _hasHydrated: false,
      setHasHydrated: (val) => set({ _hasHydrated: val }),
      address: null,
      jwt: null,
      user: null,
      setAuth: (address, jwt, user) => {
        if (typeof window !== "undefined") {
          localStorage.setItem("pocketpal_jwt", jwt)
        }
        set({ address, jwt, user })
      },
      logout: () => {
        if (typeof window !== "undefined") {
          localStorage.removeItem("pocketpal_jwt")
        }
        set({ address: null, jwt: null, user: null })
      },

      balanceUsdc: 0,
      balanceKes: 0,
      usdKesRate: 130,
      setWalletBalance: (usdc, kes, rate) =>
        set({ balanceUsdc: usdc, balanceKes: kes, usdKesRate: rate }),

      activeTab: "home",
      setActiveTab: tab => set({ activeTab: tab }),
      activeSheet: null,
      setActiveSheet: sheet => set({ activeSheet: sheet }),

      theme: getStoredTheme(),
      setTheme: theme => {
        if (typeof window !== "undefined") localStorage.setItem(STORAGE_KEY, theme)
        set({ theme })
      },
    }),
    {
      name: "cointrack_store",
      onRehydrateStorage: () => (state) => {
        state?.setHasHydrated(true)
      },
      // Only persist auth fields — not UI/balance state
      partialize: state => ({
        address: state.address,
        jwt: state.jwt,
        user: state.user,
      }),
    }
  )
)