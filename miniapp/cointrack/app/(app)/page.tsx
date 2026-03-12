"use client"
import { useEffect, useState, useRef } from "react"
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
  const hasStarted = useRef(false)
  const colors = theme === "light" ? lightTheme : darkTheme

  // Tell Base app the miniapp is ready
  useEffect(() => {
    setMiniAppReady()
  }, [setMiniAppReady])

  // Connection timeout
  useEffect(() => {
    if (isConnected) return;
    const isDemo = process.env.NEXT_PUBLIC_DEMO_MODE === "true";
    if (isDemo) return;

    const timer = setTimeout(() => {
      if (!isConnected) {
        setError("Could not connect to Base wallet. Please ensure you are opening this app inside the Base app.");
        setLoading(false);
      }
    }, 3000);

    return () => clearTimeout(timer);
  }, [isConnected]);

  useEffect(() => {
    if (!hasHydrated) return

    const isDemo = process.env.NEXT_PUBLIC_DEMO_MODE === "true"
    if (!isConnected || !address) {
      if (isDemo) {
        setAuth("0x0000000000000000000000000000000000000000", "demo-token", {})
        router.replace("/dashboard")
      }
      return // wait for MiniKit autoConnect
    }

    if (hasStarted.current) return
    hasStarted.current = true

    async function authenticate() {
      // 1. Check in-memory zustand store
      if (jwt && user) {
        try {
          await getMe()
          router.replace("/dashboard")
          return
        } catch {
          logout()
          if (typeof window !== "undefined") {
            localStorage.removeItem("pocketpal_jwt")
            localStorage.removeItem("pocketpal_address")
          }
        }
      }

      // 2. Check localStorage fallback (needs address verification)
      let existingJwt = null
      let existingAddress = null
      if (typeof window !== "undefined") {
        existingJwt = localStorage.getItem("pocketpal_jwt")
        existingAddress = localStorage.getItem("pocketpal_address")
      }

      if (existingJwt && existingAddress && existingAddress.toLowerCase() === address?.toLowerCase()) {
        try {
          const res = await getMe()
          setAuth(address!, existingJwt, res.data)
          router.replace("/dashboard")
          return
        } catch {
          if (typeof window !== "undefined") {
            localStorage.removeItem("pocketpal_jwt")
            localStorage.removeItem("pocketpal_address")
          }
          logout()
        }
      } else {
        if (typeof window !== "undefined" && (existingJwt || existingAddress)) {
          localStorage.removeItem("pocketpal_jwt")
          localStorage.removeItem("pocketpal_address")
        }
      }

      // 3. Fallback: Full SIWE Auth flow
      try {
        const token = await authenticateWallet(
          address!,
          chainId ?? 8453,
          signMessageAsync
        )
        const userRes = await getMe()
        setAuth(address!, token, userRes.data)
        if (typeof window !== "undefined") {
          localStorage.setItem("pocketpal_address", address!)
        }
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

    authenticate()

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
        fontSize: 24,
        animation: "pulse 2s infinite"
      }}>
        💰
      </div>
      <div style={{ fontSize: 14, color: colors.muted }}>Loading AiCoinTrack...</div>
      <style dangerouslySetInnerHTML={{__html: `
        @keyframes pulse {
          0% { opacity: 1; transform: scale(1); }
          50% { opacity: 0.8; transform: scale(0.95); }
          100% { opacity: 1; transform: scale(1); }
        }
      `}} />
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
        Welcome to AiCoinTrack
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
            hasStarted.current = false
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