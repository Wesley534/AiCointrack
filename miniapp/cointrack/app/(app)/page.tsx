"use client"
import { useEffect, useState } from "react"
import { useRouter } from "next/navigation"
import { useAuthenticate, useMiniKit } from "@coinbase/onchainkit/minikit"
import { AxiosError } from "axios"
import { getMe, miniappLogin } from "@/lib/api"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"

export default function Page() {
  const router = useRouter()
  const { setFrameReady, isFrameReady, context } = useMiniKit()
  const { signIn } = useAuthenticate(
    typeof window !== "undefined" ? window.location.origin : undefined,
    false
  )
  const { jwt, user, setAuth, logout, theme } = useAppStore()
  const hasHydrated = useAppStore(state => state._hasHydrated)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [retryKey, setRetryKey] = useState(0)
  const colors = theme === "light" ? lightTheme : darkTheme

  useEffect(() => {
    if (!isFrameReady) {
      setFrameReady()
    }
  }, [isFrameReady, setFrameReady])

  useEffect(() => {
    if (!hasHydrated || !isFrameReady) return

    const isDemo = process.env.NEXT_PUBLIC_DEMO_MODE === "true"

    // Already authenticated — verify JWT still valid
    if (jwt && user) {
      getMe()
        .then(() => router.replace("/dashboard"))
        .catch(() => {
          logout()
          setLoading(false)
        })
      return
    }

    if (isDemo) {
      setAuth("fid_demo", "demo-token", {})
      router.replace("/dashboard")
      return
    }

    doAuth()

    async function doAuth() {
      try {
        console.log("🚀 MiniApp auth starting")
        const authResult = await signIn()
        if (!authResult) {
          throw new Error("MiniApp authentication was rejected or unavailable")
        }

        const fid = context?.user?.fid
        if (!fid) {
          throw new Error("Missing verified Farcaster FID from MiniKit context")
        }

        const authRes = await miniappLogin({
          fid,
          username: context?.user?.username,
          display_name: context?.user?.displayName,
          pfp_url: context?.user?.pfpUrl,
        })

        const token = (authRes.data as { jwt?: string })?.jwt
        const authenticatedUser = (authRes.data as { user?: Record<string, unknown> })?.user

        if (!token || !authenticatedUser) {
          throw new Error("Invalid auth response from server")
        }

        setAuth(`fid_${fid}`, token, authenticatedUser)
        router.replace("/dashboard")
      } catch (err: unknown) {
        console.error("❌ MiniApp auth error:", err)

        const axiosErr = err as AxiosError
        if (axiosErr?.response) {
          console.error("Response status:", axiosErr.response.status)
          console.error("Response data:", JSON.stringify(axiosErr.response.data))
        } else if (axiosErr?.request) {
          console.error("Request sent but no response — CORS or network issue")
        } else {
          console.error("Error before request:", (err as Error)?.message)
        }

        const res = axiosErr?.response
        const detail = (res?.data as Record<string, unknown>)?.detail
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
  }, [hasHydrated, isFrameReady, signIn, context, setAuth, logout, retryKey, jwt, user, router])

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