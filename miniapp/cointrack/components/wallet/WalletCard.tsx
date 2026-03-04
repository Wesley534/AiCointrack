"use client"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"
import { formatKes, truncateAddress } from "@/lib/format"
import { useWalletBalance } from "@/hooks/useWalletBalance"
import { useAccount } from "wagmi"

interface WalletCardProps {
  onSend: () => void
  onDeposit: () => void
  onSave: () => void
  onWithdraw: () => void
}

export default function WalletCard({ onSend, onDeposit, onSave, onWithdraw }: WalletCardProps) {
  const { theme } = useAppStore()
  const { data, isLoading } = useWalletBalance()
  const { address } = useAccount()
  const colors = theme === "light" ? lightTheme : darkTheme

  const actions = [
    { label: "Send", icon: "↑", onClick: onSend },
    { label: "Deposit", icon: "↓", onClick: onDeposit },
    { label: "Save", icon: "💰", onClick: onSave },
    { label: "Withdraw", icon: "🏦", onClick: onWithdraw },
  ]

  return (
    <div
      style={{
        background: theme === "light" 
          ? `linear-gradient(135deg, ${colors.green}, #00c48c)` 
          : `linear-gradient(135deg, ${colors.accent}, ${colors.accentDim})`,
        borderRadius: 20,
        padding: "24px 20px",
        margin: "0 20px 24px",
        color: theme === "light" ? "#fff" : "#000",
      }}
    >
      <div style={{ marginBottom: 20 }}>
        <div style={{ fontSize: 13, opacity: 0.85, marginBottom: 6 }}>Your Wallet</div>
        <div style={{ fontSize: 11, opacity: 0.75, fontFamily: "monospace" }}>
          {address ? truncateAddress(address) : "Not connected"}
        </div>
      </div>

      <div style={{ marginBottom: 20 }}>
        <div
          style={{
            fontFamily: "Syne, sans-serif",
            fontWeight: 800,
            fontSize: 32,
            marginBottom: 4,
          }}
        >
          {isLoading ? "Loading..." : formatKes(data?.kes || 0)}
        </div>
        <div style={{ fontSize: 14, opacity: 0.85 }}>
          ${isLoading ? "..." : (data?.usdc || 0).toFixed(2)} USDC on Base
        </div>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 12 }}>
        {actions.map(action => (
          <button
            key={action.label}
            onClick={action.onClick}
            style={{
              background: "rgba(255,255,255,0.2)",
              border: "none",
              borderRadius: 12,
              padding: "12px 8px",
              cursor: "pointer",
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              gap: 6,
              color: theme === "light" ? "#fff" : "#000",
              transition: "background 0.2s",
            }}
            onMouseOver={e => (e.currentTarget.style.background = "rgba(255,255,255,0.3)")}
            onMouseOut={e => (e.currentTarget.style.background = "rgba(255,255,255,0.2)")}
          >
            <span style={{ fontSize: 20 }}>{action.icon}</span>
            <span style={{ fontSize: 11, fontWeight: 600 }}>{action.label}</span>
          </button>
        ))}
      </div>
    </div>
  )
}
