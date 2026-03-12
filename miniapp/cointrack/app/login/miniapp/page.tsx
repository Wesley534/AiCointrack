"use client"

import { useCallback, useEffect, useState } from "react"
import { useRouter } from "next/navigation"
import sdk from "@farcaster/miniapp-sdk"
import { useMiniKit } from "@coinbase/onchainkit/minikit"

type Status = "idle" | "authenticating" | "success" | "error"

export default function MiniAppLoginPage() {
  const router = useRouter()
  const { setMiniAppReady } = useMiniKit()
  const [status, setStatus] = useState<Status>("idle")
  const [error, setError] = useState<string | null>(null)
  const [userFid, setUserFid] = useState<string | null>(null)

  useEffect(() => {
    setMiniAppReady()
  }, [setMiniAppReady])

  const authenticate = useCallback(async () => {
    setStatus("authenticating")
    setError(null)

    try {
      const response = await sdk.quickAuth.fetch("/api/auth")
      const payload = (await response.json()) as { userFid?: string; message?: string }

      if (!response.ok || !payload?.userFid) {
        throw new Error(payload?.message || "Mini App authentication failed")
      }

      setUserFid(payload.userFid)
      setStatus("success")
      setTimeout(() => router.replace("/"), 700)
    } catch (err) {
      const message = err instanceof Error ? err.message : "Mini App authentication failed"
      setError(message)
      setStatus("error")
    }
  }, [router])

  useEffect(() => {
    authenticate()
  }, [authenticate])

  return (
    <main style={styles.root}>
      <div style={styles.card}>
        <h1 style={styles.title}>Mini App Sign-In</h1>
        <p style={styles.subtitle}>Authenticating your Farcaster session…</p>

        {status === "authenticating" && <p style={styles.info}>Please approve if prompted in Base app.</p>}

        {status === "success" && (
          <p style={styles.success}>Authenticated{userFid ? ` (FID: ${userFid})` : ""}. Redirecting…</p>
        )}

        {status === "error" && (
          <>
            <p style={styles.error}>{error}</p>
            <button type="button" style={styles.button} onClick={authenticate}>
              Retry Mini App Auth
            </button>
          </>
        )}
      </div>
    </main>
  )
}

const styles: Record<string, React.CSSProperties> = {
  root: {
    minHeight: "100vh",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    background: "#0A0D12",
    padding: 16,
  },
  card: {
    width: "100%",
    maxWidth: 420,
    borderRadius: 16,
    padding: 24,
    background: "#111620",
    border: "1px solid #1E2A3A",
    color: "#E8EDF5",
    textAlign: "center",
  },
  title: {
    margin: "0 0 8px",
    fontSize: 22,
    fontWeight: 800,
  },
  subtitle: {
    margin: "0 0 16px",
    color: "#6B7A90",
    fontSize: 14,
  },
  info: {
    color: "#E8EDF5",
    fontSize: 14,
    margin: 0,
  },
  success: {
    color: "#86EFAC",
    fontSize: 14,
    margin: 0,
  },
  error: {
    color: "#FCA5A5",
    fontSize: 14,
    margin: "0 0 12px",
  },
  button: {
    border: "none",
    borderRadius: 10,
    padding: "10px 14px",
    background: "#0052FF",
    color: "white",
    fontWeight: 700,
    cursor: "pointer",
  },
}
