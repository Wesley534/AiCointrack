"use client"
import { useEffect, useState } from "react"
import { useRouter } from "next/navigation"
import { useAccount, useSignMessage } from "wagmi"
import { useMiniKit } from "@coinbase/onchainkit/minikit"
import { authenticateWallet } from "@/lib/auth"
import { getMe } from "@/lib/api"
import { useAppStore } from "@/store"
import { darkTheme } from "@/lib/constants"

export default function Page() {
  const router = useRouter()
  const { address, isConnected, chainId } = useAccount()
  const { signMessageAsync } = useSignMessage()
  const { setMiniAppReady } = useMiniKit()
  const { jwt, user, setAuth, logout, _hasHydrated } = useAppStore()
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const colors = darkTheme

  useEffect(() => {
    setMiniAppReady()
  }, [setMiniAppReady])

  useEffect(() => {
    if (!_hasHydrated) return

    const isDemo = process.env.NEXT_PUBLIC_DEMO_MODE === "true"

    if (isDemo) {
      setAuth("0x0000000000000000000000000000000000000000", "demo-token", {})
      router.replace("/dashboard")
      return
    }

    // Already have JWT + user — go straight to dashboard.
    // Do NOT call getMe() here — a transient network failure would
    // call logout() and wipe the session, breaking all subsequent queries.
    if (jwt && user) {
      router.replace("/dashboard")
      return
    }

    // JWT exists in localStorage but not in store (e.g. store was reset
    // but localStorage wasn't). Verify it and restore the session.
    const existingJwt = typeof window !== "undefined"
      ? localStorage.getItem("pocketpal_jwt")
      : null

    if (existingJwt) {
      getMe()
        .then(res => {
          setAuth(address || "", existingJwt, res.data)
          router.replace("/dashboard")
        })
        .catch(() => {
          // JWT genuinely expired — clear it and re-auth
          localStorage.removeItem("pocketpal_jwt")
          if (isConnected && address) {
            doAuth()
          } else {
            setLoading(false)
          }
        })
      return
    }

    if (!isConnected || !address) {
      setLoading(false)
      return
    }

    doAuth()

    async function doAuth() {
      try {
        console.log("[Auth] Starting SIWE auth for", address)
        const token = await authenticateWallet(
          address!,
          chainId || 8453,
          signMessageAsync
        )
        console.log("[Auth] Got JWT, fetching user profile")
        const userRes = await getMe()
        setAuth(address!, token, userRes.data)
        console.log("[Auth] Complete, redirecting to dashboard")
        router.replace("/dashboard")
      } catch (err: unknown) {
        console.error("[Auth] Error:", err)
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
  }, [_hasHydrated, isConnected, address, chainId, signMessageAsync, setAuth, logout, jwt, user, router])

  if (!_hasHydrated || loading) return (
    <div style={{
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      height: "100vh",
      flexDirection: "column",
      gap: 16,
      background: colors.surface,
    }}>
      <div style={{
        width: 48,
        height: 48,
        borderRadius: 14,
        background: `linear-gradient(135deg, ${colors.accent}, ${colors.accentDim})`,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        fontSize: 24,
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
      background: colors.surface,
      minHeight: "100vh",
    }}>
      <div style={{ fontSize: 48, marginBottom: 16 }}>💰</div>
      <div style={{ fontWeight: 800, fontSize: 24, marginBottom: 8, color: colors.text }}>
        Cointrack
      </div>
      <div style={{ color: colors.muted, fontSize: 15 }}>
        Open this app inside the Base app to connect your wallet automatically.
      </div>
    </div>
  )

  return (
    <div style={{
      background: colors.surface,
      minHeight: "100vh",
      display: "flex",
      flexDirection: "column",
      alignItems: "center",
      justifyContent: "center",
      padding: 32,
      textAlign: "center",
    }}>
      <div style={{ fontSize: 64, marginBottom: 24 }}>💰</div>
      <h1 style={{
        color: colors.text,
        fontSize: 28,
        fontFamily: "Syne, sans-serif",
        marginBottom: 16,
      }}>
        Welcome to Cointrack
      </h1>
      <p style={{
        color: colors.muted,
        fontSize: 16,
        lineHeight: 1.6,
        marginBottom: 32,
        maxWidth: 300,
      }}>
        Connecting your wallet...
      </p>
      {error && (
        <div style={{
          color: "#EF4444",
          fontSize: 14,
          marginBottom: 16,
          background: "rgba(220,38,38,0.1)",
          padding: "12px 16px",
          borderRadius: 8,
          border: "1px solid rgba(220,38,38,0.3)",
          maxWidth: 300,
        }}>
          {error}
        </div>
      )}
    </div>
  )
}