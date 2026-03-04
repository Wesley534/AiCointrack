"use client"
import { useEffect, useState } from "react"
import { useAccount, useSignMessage } from "wagmi"
import { useMiniKit } from "@coinbase/onchainkit/minikit"
import { authenticateWallet } from "@/lib/auth"
import { getMe } from "@/lib/api"
import { useAppStore } from "@/store"
import HomeTab from "@/components/home/HomeTab"
import WalletPage from "./wallet/page"
import BudgetPage from "./budget/page"
import SavingsPage from "./savings/page"
import TransactionsPage from "./transactions/page"
import { lightTheme, darkTheme } from "@/lib/constants"

export default function Page() {
  const { address, isConnected, chainId } = useAccount()
  const { signMessageAsync } = useSignMessage()
  const { setMiniAppReady } = useMiniKit()
  const { setAuth, activeTab, theme } = useAppStore()
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const colors = theme === "light" ? lightTheme : darkTheme

  // Tell Base app the miniapp is ready
  useEffect(() => { 
    setMiniAppReady() 
  }, [setMiniAppReady])

  useEffect(() => {
    if (!isConnected || !address) {
      setLoading(false)
      return
    }

    const existingJwt = localStorage.getItem("pocketpal_jwt")

    if (existingJwt) {
      // Verify existing JWT still valid
      getMe()
        .then(res => {
          setAuth(address, existingJwt, res.data)
          setLoading(false)
        })
        .catch(() => {
          // JWT expired — re-authenticate
          localStorage.removeItem("pocketpal_jwt")
          doAuth()
        })
    } else {
      doAuth()
    }

    async function doAuth() {
      try {
        const token = await authenticateWallet(
          address!, chainId || 8453, signMessageAsync
        )
        const userRes = await getMe()
        setAuth(address!, token, userRes.data)
      } catch (err) {
        console.error("Auth error:", err)
        setError("Authentication failed. Please try again.")
      } finally {
        setLoading(false)
      }
    }
  }, [isConnected, address, chainId, signMessageAsync, setAuth])

  if (loading) return (
    <div style={{ 
      display: "flex", 
      alignItems: "center", 
      justifyContent: "center", 
      height: "100vh", 
      flexDirection: "column", 
      gap: 16,
      background: theme === "light" ? colors.bg : colors.surface,
    }}>
      <div style={{ 
        width: 48, 
        height: 48, 
        borderRadius: 14, 
        background: theme === "light" 
          ? `linear-gradient(135deg, ${colors.green}, #00c48c)` 
          : `linear-gradient(135deg, ${colors.accent}, ${colors.accentDim})`,
        display: "flex", 
        alignItems: "center", 
        justifyContent: "center", 
        fontSize: 24 
      }}>
        💰
      </div>
      <div style={{ fontSize: 14, color: colors.muted }}>Loading Cointrack...</div>
    </div>
  )

  if (!isConnected) return (
    <div style={{ 
      padding: 32, 
      textAlign: "center",
      background: theme === "light" ? colors.bg : colors.surface,
      minHeight: "100vh",
    }}>
      <div style={{ fontSize: 48, marginBottom: 16 }}>💰</div>
      <div style={{ fontWeight: 800, fontSize: 22, marginBottom: 8, color: colors.text }}>Cointrack</div>
      <div style={{ color: colors.muted, fontSize: 14 }}>
        Open this app inside the Base app to connect your wallet automatically.
      </div>
    </div>
  )

  if (error) return (
    <div style={{ 
      padding: 32, 
      textAlign: "center", 
      color: colors.red,
      background: theme === "light" ? colors.bg : colors.surface,
      minHeight: "100vh",
    }}>
      {error}
    </div>
  )

  // Render the appropriate tab based on activeTab
  const renderTab = () => {
    switch (activeTab) {
      case "home":
        return <HomeTab />
      case "wallet":
        return <WalletPage />
      case "budget":
        return <BudgetPage />
      case "savings":
        return <SavingsPage />
      case "transactions":
        return <TransactionsPage />
      default:
        return <HomeTab />
    }
  }

  return (
    <div style={{ 
      background: theme === "light" ? colors.bg : colors.surface,
      minHeight: "100vh",
    }}>
      {renderTab()}
    </div>
  )
}
