"use client"
import { useEffect, useState } from "react"
import { useRouter } from "next/navigation"
import { useAccount, useSignMessage } from "wagmi"
import { useMiniKit } from "@coinbase/onchainkit/minikit"
import { authenticateWallet } from "@/lib/auth"
import { getMe } from "@/lib/api"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"

export default function Page() {
  const router = useRouter()
  const { address, isConnected, chainId } = useAccount()
  const { signMessageAsync } = useSignMessage()
  const { setMiniAppReady } = useMiniKit()
  const { jwt, user, setAuth, logout, theme } = useAppStore()
  const hasHydrated = useAppStore(state => state._hasHydrated)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [retryKey, setRetryKey] = useState(0)
  const colors = theme === "light" ? lightTheme : darkTheme

  // Tell Base app the miniapp is ready
  useEffect(() => {
    setMiniAppReady()
  }, [setMiniAppReady])

  useEffect(() => {
    if (!hasHydrated) return
    const isDemo = process.env.NEXT_PUBLIC_DEMO_MODE === "true"

    // Already authenticated in store — verify JWT is still valid
    if (jwt && user) {
      getMe()
        .then(() => {
          router.replace("/dashboard")
        })
        .catch(() => {
          // JWT expired — clear store and re-auth
          logout()
          setLoading(false)
        })
      return
    }

    if (!isConnected || !address) {
      if (isDemo) {
        setAuth("0x0000000000000000000000000000000000000000", "demo-token", {})
        router.replace("/dashboard")
      } else {
        setLoading(false)
      }
      return
    }

    // Check localStorage JWT as fallback (handles cases where persist hasn't rehydrated yet)
    const existingJwt = typeof window !== "undefined"
      ? localStorage.getItem("pocketpal_jwt")
      : null

    if (existingJwt) {
      getMe()
        .then(res => {
          setAuth(address, existingJwt, res.data)
          router.replace("/dashboard")
        })
        .catch(() => {
          localStorage.removeItem("pocketpal_jwt")
          logout()
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
        router.replace("/dashboard")
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
        setLoading(false)
      }
    }
  }, [hasHydrated, isConnected, address, chainId, signMessageAsync, setAuth, logout, retryKey, jwt, user, router])

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
      <div style={{ fontWeight: 800, fontSize: 24, marginBottom: 8, color: colors.text }}>Cointrack</div>
      <div style={{ color: colors.muted, fontSize: 15 }}>
        Open this app inside the Base app to connect your wallet automatically.
      </div>
    </div>
  )

  return (
    <div style={{
      background: theme === "light" ? colors.bg : colors.surface,
      minHeight: "100vh",
      display: "flex",
      flexDirection: "column",
      alignItems: "center",
      justifyContent: "center",
      padding: 32,
      textAlign: "center"
    }}>
      <div style={{ fontSize: 64, marginBottom: 24 }}>💰</div>
      <h1 style={{ color: colors.text, fontSize: 28, fontFamily: "Syne, sans-serif", marginBottom: 16 }}>
        Welcome to Cointrack
      </h1>
      <p style={{ color: colors.muted, fontSize: 16, lineHeight: 1.6, marginBottom: 32, maxWidth: 300 }}>
        The all-in-one wallet and financial tracker. Manage your budget, reach your savings goals, and track everyday transactions effortlessly on Base.
      </p>

      {error && (
        <div style={{ color: colors.red || "#EF4444", fontSize: 14, marginBottom: 16 }}>
          {error}
        </div>
      )}

      {error ? (
        <button
          onClick={() => {
            setError(null)
            setLoading(true)
            setRetryKey(k => k + 1)
          }}
          style={{
            padding: "16px 32px",
            borderRadius: 14,
            border: "none",
            background: colors.green || colors.accent,
            color: "#fff",
            fontWeight: 700,
            fontSize: 16,
            fontFamily: "Syne, sans-serif",
            cursor: "pointer",
            width: "100%"
          }}
        >
          Retry Connection
        </button>
      ) : (
        <div style={{ color: colors.muted, fontSize: 14 }}>
          Authenticating securely via Base...
        </div>
      )}
    </div>
  )
}