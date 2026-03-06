"use client"
import { useState } from "react"
import { useRouter } from "next/navigation"
import { emailLogin, getMe } from "@/lib/api"
import { useAppStore } from "@/store"
import { darkTheme } from "@/lib/constants"

export default function DebugLoginPage() {
    const router = useRouter()
    const { setAuth } = useAppStore()
    const colors = darkTheme
    const [email, setEmail] = useState("")
    const [password, setPassword] = useState("")
    const [loading, setLoading] = useState(false)
    const [error, setError] = useState<string | null>(null)

    const handleLogin = async () => {
        if (!email.trim() || !password.trim()) {
            setError("Enter both email and password")
            return
        }
        setLoading(true)
        setError(null)
        try {
            const res = await emailLogin(email.trim(), password)
            const jwt = res.data?.access_token
            if (!jwt) throw new Error("No token returned")

            // Store JWT then fetch user profile
            localStorage.setItem("pocketpal_jwt", jwt)
            const userRes = await getMe()
            setAuth(email.trim(), jwt, userRes.data)
            router.replace("/dashboard")
        } catch (err: unknown) {
            const detail = (err as { response?: { data?: { detail?: unknown } } })
                ?.response?.data?.detail
            setError(
                typeof detail === "string"
                    ? detail
                    : "Login failed. Check your credentials."
            )
        } finally {
            setLoading(false)
        }
    }

    return (
        <div
            style={{
                minHeight: "100vh",
                background: colors.surface,
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                justifyContent: "center",
                padding: 32,
            }}
        >
            {/* Header */}
            <div style={{ textAlign: "center", marginBottom: 40 }}>
                <div
                    style={{
                        width: 56,
                        height: 56,
                        borderRadius: 16,
                        background: `linear-gradient(135deg, ${colors.accent}, ${colors.accentDim})`,
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        fontSize: 28,
                        margin: "0 auto 16px",
                    }}
                >
                    💰
                </div>
                <div
                    style={{
                        fontFamily: "Syne, sans-serif",
                        fontWeight: 800,
                        fontSize: 24,
                        color: colors.text,
                        marginBottom: 6,
                    }}
                >
                    Cointrack
                </div>
                <div
                    style={{
                        fontSize: 12,
                        color: colors.muted,
                        background: "rgba(255,100,0,0.15)",
                        border: "1px solid rgba(255,100,0,0.3)",
                        borderRadius: 6,
                        padding: "4px 10px",
                        display: "inline-block",
                    }}
                >
                    🛠 Debug Login — not for production
                </div>
            </div>

            {/* Form */}
            <div
                style={{
                    width: "100%",
                    maxWidth: 340,
                    background: colors.card,
                    borderRadius: 16,
                    border: `1px solid ${colors.border}`,
                    padding: 24,
                    display: "flex",
                    flexDirection: "column",
                    gap: 16,
                }}
            >
                <div>
                    <label
                        style={{
                            display: "block",
                            fontSize: 12,
                            fontWeight: 600,
                            color: colors.muted,
                            marginBottom: 6,
                            textTransform: "uppercase",
                            letterSpacing: "0.05em",
                        }}
                    >
                        Email
                    </label>
                    <input
                        type="email"
                        value={email}
                        onChange={e => setEmail(e.target.value)}
                        onKeyDown={e => e.key === "Enter" && handleLogin()}
                        placeholder="you@example.com"
                        style={{
                            width: "100%",
                            padding: "12px 14px",
                            borderRadius: 10,
                            border: `1px solid ${colors.border}`,
                            background: colors.surface,
                            color: colors.text,
                            fontSize: 15,
                            outline: "none",
                            boxSizing: "border-box",
                        }}
                    />
                </div>

                <div>
                    <label
                        style={{
                            display: "block",
                            fontSize: 12,
                            fontWeight: 600,
                            color: colors.muted,
                            marginBottom: 6,
                            textTransform: "uppercase",
                            letterSpacing: "0.05em",
                        }}
                    >
                        Password
                    </label>
                    <input
                        type="password"
                        value={password}
                        onChange={e => setPassword(e.target.value)}
                        onKeyDown={e => e.key === "Enter" && handleLogin()}
                        placeholder="••••••••"
                        style={{
                            width: "100%",
                            padding: "12px 14px",
                            borderRadius: 10,
                            border: `1px solid ${colors.border}`,
                            background: colors.surface,
                            color: colors.text,
                            fontSize: 15,
                            outline: "none",
                            boxSizing: "border-box",
                        }}
                    />
                </div>

                {error && (
                    <div
                        style={{
                            padding: "10px 14px",
                            borderRadius: 8,
                            background: "rgba(220,38,38,0.1)",
                            border: "1px solid rgba(220,38,38,0.3)",
                            color: "#EF4444",
                            fontSize: 13,
                        }}
                    >
                        {error}
                    </div>
                )}

                <button
                    onClick={handleLogin}
                    disabled={loading}
                    style={{
                        width: "100%",
                        padding: "14px",
                        borderRadius: 10,
                        background: loading
                            ? colors.border
                            : `linear-gradient(135deg, ${colors.accent}, ${colors.accentDim})`,
                        color: "#fff",
                        border: "none",
                        fontFamily: "Syne, sans-serif",
                        fontWeight: 700,
                        fontSize: 15,
                        cursor: loading ? "not-allowed" : "pointer",
                        transition: "opacity 0.2s",
                    }}
                >
                    {loading ? "Signing in..." : "Sign In"}
                </button>

                <div
                    style={{
                        textAlign: "center",
                        fontSize: 12,
                        color: colors.muted,
                        lineHeight: 1.5,
                    }}
                >
                    This page bypasses wallet auth for browser debugging.
                    <br />
                    Only works with email/password accounts.
                </div>
            </div>

            {/* Back link */}
            <button
                onClick={() => router.replace("/")}
                style={{
                    marginTop: 24,
                    background: "transparent",
                    border: "none",
                    color: colors.muted,
                    fontSize: 13,
                    cursor: "pointer",
                    textDecoration: "underline",
                }}
            >
                ← Back to wallet login
            </button>
        </div>
    )
}
