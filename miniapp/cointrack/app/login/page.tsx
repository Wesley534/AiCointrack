"use client"

import { useEffect, useRef, useState } from "react"
import { useAccount, useConnect, useSignMessage, useDisconnect } from "wagmi"
import { coinbaseWallet } from "wagmi/connectors"
import { SiweMessage } from "siwe"
import { getNonce } from "@/lib/api"
import { BASE_CHAIN_ID, APP_DOMAIN, APP_URL } from "@/lib/constants"

// ── Constants ────────────────────────────────────────────────────────────────

const DOMAIN = APP_DOMAIN
const ORIGIN = APP_URL

// ── Types ────────────────────────────────────────────────────────────────────

type Phase =
    | "idle"       // wallet not connected yet
    | "signing"    // building SIWE message + requesting signature
    | "redirecting"// signature obtained, about to redirect
    | "error"      // something failed

// ── Component ────────────────────────────────────────────────────────────────

export default function LoginPage() {
    const { address, isConnected, chainId } = useAccount()
    const { connect } = useConnect()
    const { disconnect } = useDisconnect()
    const { signMessageAsync } = useSignMessage()

    const [phase, setPhase] = useState<Phase>("idle")
    const [errorMsg, setErrorMsg] = useState<string | null>(null)
    const hasTriggered = useRef(false)

    // Read ?redirect= from the URL so Flutter can pass its scheme
    const [callbackScheme, setCallbackScheme] = useState("aicointrack")
    useEffect(() => {
        if (typeof window !== "undefined") {
            const params = new URLSearchParams(window.location.search)
            const r = params.get("redirect")
            if (r) setCallbackScheme(r)
        }
    }, [])

    // ── Auto-sign when wallet connects ────────────────────────────────────────
    useEffect(() => {
        if (!isConnected || !address) {
            hasTriggered.current = false
            return
        }
        if (hasTriggered.current) return
        hasTriggered.current = true

        doSign()
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [isConnected, address])

    async function doSign() {
        setPhase("signing")
        setErrorMsg(null)
        try {
            // 1. Get nonce (fallback to random if backend unreachable)
            let nonce: string
            try {
                nonce = await getNonce()
            } catch {
                nonce = Math.random().toString(36).slice(2) + Date.now().toString(36)
            }

            // 2. Build EIP-4361 SIWE message
            const effectiveChain = chainId ?? BASE_CHAIN_ID
            const siweMessage = new SiweMessage({
                domain: DOMAIN,
                address,
                statement: "Sign in to AiCointrack",
                uri: ORIGIN,
                version: "1",
                chainId: effectiveChain,
                nonce,
            })
            const messageString = siweMessage.prepareMessage()

            // 3. Request wallet signature (opens smart-wallet passkey prompt)
            const signature = await signMessageAsync({ message: messageString })

            setPhase("redirecting")

            // 4. Build the deep-link callback URL
            //    Flutter catches aicointrack://login?address=...&message=...&signature=...
            const params = new URLSearchParams({
                address: address!,
                message: messageString,
                signature,
            })
            const callbackUrl = `${callbackScheme}://login?${params.toString()}`

            // Small delay so the user sees the "redirecting" state briefly
            await new Promise(r => setTimeout(r, 600))
            window.location.href = callbackUrl
        } catch (err: unknown) {
            console.error("Login signing error:", err)

            let msg = "Signing cancelled or failed. Please try again."
            if (err instanceof Error) {
                if (err.message.toLowerCase().includes("rejected") ||
                    err.message.toLowerCase().includes("denied") ||
                    err.message.toLowerCase().includes("cancel")) {
                    msg = "You cancelled the signature request. Tap below to try again."
                } else {
                    msg = err.message
                }
            }
            setErrorMsg(msg)
            setPhase("error")
            hasTriggered.current = false
        }
    }

    // ── Derived UI state ──────────────────────────────────────────────────────

    const isBusy = phase === "signing" || phase === "redirecting"

    // ── Render ────────────────────────────────────────────────────────────────

    return (
        <div style={styles.root}>
            {/* Subtle grid background */}
            <div style={styles.grid} aria-hidden />

            {/* Glowing orb */}
            <div style={styles.orb} aria-hidden />

            <div style={styles.card}>
                {/* Logo */}
                <div style={styles.logoWrap}>
                    <span style={styles.logoEmoji}>🔵</span>
                </div>

                <h1 style={styles.heading}>Sign in to AiCoinTrack</h1>
                <p style={styles.sub}>
                    Connect your Base smart wallet — secured by passkey,<br />
                    no seed phrase needed.
                </p>

                {/* Error banner */}
                {errorMsg && (
                    <div style={styles.errorBanner} role="alert">
                        <span style={styles.errorIcon}>⚠️</span>
                        <span>{errorMsg}</span>
                    </div>
                )}

                {/* Wallet button — shown only when not busy */}
                {!isBusy && !isConnected && (
                    <button
                        id="base-connect-button"
                        style={styles.connectBtn}
                        // Ensure we don't default to Base smart-wallet (ERC-6492) signatures
                        // until backend verification supports them reliably.
                        onClick={() =>
                            connect({ connector: coinbaseWallet({ preference: "all" }) })
                        }
                    >
                        <span style={styles.connectIcon}>🔑</span>
                        <div>
                            <div style={styles.connectLabel}>Sign in with Base</div>
                            <div style={styles.connectSublabel}>Passkey · no seed phrase</div>
                        </div>
                    </button>
                )}

                {/* Connected but not yet redirected */}
                {!isBusy && isConnected && address && (
                    <div style={styles.busyWrap} aria-live="polite">
                        <Spinner />
                        <span style={styles.busyText}>Wallet connected — authenticating...</span>
                    </div>
                )}

                {/* Signing / redirecting state */}
                {isBusy && (
                    <div style={styles.busyWrap} aria-live="polite">
                        <Spinner />
                        <span style={styles.busyText}>
                            {phase === "signing"
                                ? "Waiting for signature…"
                                : "Authenticated! Returning to app…"}
                        </span>
                    </div>
                )}

                {/* Retry button after error */}
                {phase === "error" && isConnected && address && (
                    <button
                        id="retry-sign-button"
                        style={styles.retryBtn}
                        onClick={doSign}
                    >
                        Retry
                    </button>
                )}

                {/* Cancel/Disconnect after error */}
                {phase === "error" && isConnected && (
                    <button
                        style={styles.cancelBtn}
                        onClick={() => {
                            disconnect()
                            setPhase("idle")
                            setErrorMsg(null)
                        }}
                    >
                        Disconnect & Try Again
                    </button>
                )}

                {/* Feature pills */}
                <div style={styles.pills}>
                    {["🔒 Non-custodial", "⚡ Instant", "🌐 Base Network"].map(p => (
                        <span key={p} style={styles.pill}>{p}</span>
                    ))}
                </div>
            </div>
        </div>
    )
}

// ── Spinner ───────────────────────────────────────────────────────────────────

function Spinner() {
    return (
        <div
            style={{
                width: 28,
                height: 28,
                border: "3px solid rgba(0,82,255,0.25)",
                borderTopColor: "#0052FF",
                borderRadius: "50%",
                animation: "spin 0.75s linear infinite",
                flexShrink: 0,
            }}
            aria-hidden
        >
            <style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style>
        </div>
    )
}

// ── Styles ────────────────────────────────────────────────────────────────────

const bg = "#0A0D12"
const surface = "#111620"
const border = "#1E2A3A"
const blue = "#0052FF"
const text = "#E8EDF5"
const muted = "#6B7A90"

const styles: Record<string, React.CSSProperties> = {
    root: {
        minHeight: "100vh",
        background: bg,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        padding: "24px 16px",
        position: "relative",
        overflow: "hidden",
    },
    grid: {
        position: "absolute",
        inset: 0,
        backgroundImage: `
      linear-gradient(rgba(0,82,255,0.04) 1px, transparent 1px),
      linear-gradient(90deg, rgba(0,82,255,0.04) 1px, transparent 1px)
    `,
        backgroundSize: "40px 40px",
        pointerEvents: "none",
    },
    orb: {
        position: "absolute",
        top: -120,
        left: "50%",
        transform: "translateX(-50%)",
        width: 400,
        height: 400,
        borderRadius: "50%",
        background: "radial-gradient(circle, rgba(0,82,255,0.18) 0%, transparent 70%)",
        pointerEvents: "none",
    },
    card: {
        position: "relative",
        zIndex: 1,
        width: "100%",
        maxWidth: 380,
        background: surface,
        border: `1px solid ${border}`,
        borderRadius: 24,
        padding: "36px 28px 32px",
        boxShadow: "0 24px 64px rgba(0,0,0,0.5), 0 0 0 1px rgba(0,82,255,0.06)",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        gap: 0,
    },
    logoWrap: {
        width: 64,
        height: 64,
        borderRadius: 18,
        background: "linear-gradient(135deg, #0052FF22, #0052FF44)",
        border: `1px solid ${blue}44`,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        fontSize: 32,
        marginBottom: 20,
        boxShadow: `0 0 20px ${blue}33`,
    },
    logoEmoji: {
        lineHeight: 1,
    },
    heading: {
        color: text,
        fontSize: 22,
        fontWeight: 800,
        margin: "0 0 8px",
        textAlign: "center",
        letterSpacing: "-0.01em",
    },
    sub: {
        color: muted,
        fontSize: 14,
        lineHeight: 1.6,
        textAlign: "center",
        margin: "0 0 24px",
    },
    errorBanner: {
        width: "100%",
        display: "flex",
        alignItems: "flex-start",
        gap: 8,
        padding: "12px 14px",
        borderRadius: 12,
        background: "rgba(239,68,68,0.08)",
        border: "1px solid rgba(239,68,68,0.25)",
        color: "#FCA5A5",
        fontSize: 13,
        lineHeight: 1.5,
        marginBottom: 16,
        boxSizing: "border-box",
    },
    errorIcon: {
        flexShrink: 0,
        fontSize: 15,
        marginTop: 1,
    },
    connectBtn: {
        width: "100%",
        minHeight: 56,
        borderRadius: 14,
        background: "linear-gradient(135deg, #0052FF, #0040CC)",
        color: "#fff",
        fontSize: 16,
        fontWeight: 700,
        fontFamily: "'Outfit', sans-serif",
        border: "none",
        cursor: "pointer",
        boxShadow: "0 0 24px rgba(0,82,255,0.35)",
        transition: "opacity 0.15s, transform 0.12s",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        gap: 12,
        padding: "14px 20px",
        marginBottom: 16,
    },
    connectIcon: {
        fontSize: 22,
    },
    connectLabel: {
        fontWeight: 700,
        fontSize: 16,
    },
    connectSublabel: {
        fontSize: 12,
        opacity: 0.65,
        marginTop: 2,
    },
    busyWrap: {
        display: "flex",
        alignItems: "center",
        gap: 12,
        padding: "16px 20px",
        borderRadius: 14,
        background: `${blue}14`,
        border: `1px solid ${blue}33`,
        width: "100%",
        boxSizing: "border-box",
        marginBottom: 16,
    },
    busyText: {
        color: text,
        fontSize: 14,
        fontWeight: 500,
    },
    retryBtn: {
        width: "100%",
        padding: "14px 0",
        borderRadius: 14,
        border: `1px solid ${blue}66`,
        background: "transparent",
        color: blue,
        fontWeight: 700,
        fontSize: 15,
        cursor: "pointer",
        fontFamily: "'Outfit', sans-serif",
        marginBottom: 8,
        transition: "background 0.15s",
    },
    cancelBtn: {
        width: "100%",
        padding: "12px 0",
        borderRadius: 12,
        border: `1px solid ${border}`,
        background: "transparent",
        color: muted,
        fontWeight: 500,
        fontSize: 14,
        cursor: "pointer",
        fontFamily: "'Outfit', sans-serif",
        marginBottom: 16,
        transition: "background 0.15s",
    },
    pills: {
        display: "flex",
        gap: 8,
        flexWrap: "wrap",
        justifyContent: "center",
        marginTop: 24,
    },
    pill: {
        padding: "5px 12px",
        borderRadius: 99,
        background: "#1A2235",
        border: `1px solid ${border}`,
        color: muted,
        fontSize: 11,
        fontWeight: 500,
        whiteSpace: "nowrap",
    },
}
