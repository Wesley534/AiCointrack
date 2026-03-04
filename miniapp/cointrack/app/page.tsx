"use client"
import { useEffect, useState } from "react"
import { useAccount, useSignMessage } from "wagmi"
import { useMiniKit } from "@coinbase/onchainkit/minikit"
import { authenticateWallet } from "@/lib/auth"
import { getMe } from "@/lib/api"
import { useAppStore } from "@/store"
import HomeTab from "@/components/home/HomeTab"
import { lightTheme, darkTheme } from "@/lib/constants"

export default function Page() {
  const { address, isConnected, chainId } = useAccount()
  const { signMessageAsync } = useSignMessage()
  const { setMiniAppReady } = useMiniKit()
  const { setAuth, theme } = useAppStore()
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [retryKey, setRetryKey] = useState(0)
  const colors = theme === "light" ? lightTheme : darkTheme

  // Tell Base app the miniapp is ready
  useEffect(() => { 
    setMiniAppReady() 
  }, [setMiniAppReady])

  useEffect(() => {
    // For development: allow demo access without wallet connection
    const isDemo = process.env.NEXT_PUBLIC_DEMO_MODE === "true"
    
    if (!isConnected || !address) {
      if (isDemo) {
        // Demo mode: set mock address for testing
        setAuth("0x0000000000000000000000000000000000000000", "demo-token", {})
        setLoading(false)
      } else {
        setLoading(false)
      }
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
          address!,
          chainId || 8453,
          signMessageAsync
        )
        const userRes = await getMe()
        setAuth(address!, token, userRes.data)
      } catch (err: unknown) {
        console.error("Auth error:", err)
        const res = err && typeof err === "object" && "response" in err
          ? (err as { response?: { data?: unknown; status?: number } }).response
          : null
        const detail = res?.data && typeof res.data === "object" && "detail" in res.data
          ? (res.data as { detail: unknown }).detail
          : null
        const msg =
          typeof detail === "string"
            ? detail
            : Array.isArray(detail)
              ? detail.map(String).join(", ")
              : err instanceof Error
                ? err.message
                : "Authentication failed. Please try again."
        setError(msg)
      } finally {
        setLoading(false)
      }
    }
  }, [isConnected, address, chainId, signMessageAsync, setAuth, retryKey])

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

  if (!isConnected && process.env.NEXT_PUBLIC_DEMO_MODE !== "true") return (
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
      background: theme === "light" ? colors.bg : colors.surface,
      minHeight: "100vh",
      display: "flex",
      flexDirection: "column",
      alignItems: "center",
      justifyContent: "center",
      gap: 16,
    }}>
      <div style={{ color: colors.red || colors.danger, fontSize: 14 }}>{error}</div>
      <button
        type="button"
        onClick={() => {
          setError(null)
          setLoading(true)
          setRetryKey((k) => k + 1)
        }}
        style={{
          padding: "12px 24px",
          borderRadius: 8,
          border: "none",
          background: colors.green || colors.accent,
          color: "#fff",
          fontWeight: 600,
          cursor: "pointer",
        }}
      >
        Retry
      </button>
    </div>
  )

  return (
    <div style={{ 
      background: theme === "light" ? colors.bg : colors.surface,
      minHeight: "100vh",
    }}>
      <HomeTab />
    </div>
  )
}
