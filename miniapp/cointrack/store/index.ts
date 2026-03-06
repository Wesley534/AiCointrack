import { create } from "zustand"
import { persist } from "zustand/middleware"

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

      theme: "dark",
      setTheme: theme => {
        if (typeof window !== "undefined") localStorage.setItem("cointrack_theme", theme)
        set({ theme })
      },
    }),
    {
      name: "cointrack_store",
      onRehydrateStorage: () => (state) => {
        state?.setHasHydrated(true)
      },
      partialize: state => ({
        address: state.address,
        jwt: state.jwt,
        user: state.user,
        theme: state.theme,
      }),
    }
  )
)

// ─── Hydration hook ───────────────────────────────────────────────────────────
// This is the critical piece. Instead of relying on onRehydrateStorage firing
// before components mount, we expose a hook that components can use to wait
// for hydration. This triggers a re-render when _hasHydrated flips to true,
// which causes React Query's enabled condition to be re-evaluated.
export function useHasHydrated() {
  return useAppStore(state => state._hasHydrated)
}