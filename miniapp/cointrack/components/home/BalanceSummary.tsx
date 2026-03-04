"use client"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"
import { formatKes } from "@/lib/format"
import { useWalletBalance } from "@/hooks/useWalletBalance"

export default function BalanceSummary() {
  const { theme } = useAppStore()
  const { data, isLoading } = useWalletBalance()
  const colors = theme === "light" ? lightTheme : darkTheme

  if (isLoading) {
    return (
      <div
        style={{
          background: theme === "light" 
            ? `linear-gradient(135deg, ${colors.green}, #00c48c)` 
            : `linear-gradient(135deg, ${colors.accent}, ${colors.accentDim})`,
          borderRadius: 20,
          padding: "24px 20px",
          margin: "0 20px 20px",
          color: theme === "light" ? "#fff" : "#000",
        }}
      >
        <div style={{ fontSize: 14, opacity: 0.9, marginBottom: 8 }}>Loading...</div>
      </div>
    )
  }

  return (
    <div
      style={{
        background: theme === "light" 
          ? `linear-gradient(135deg, ${colors.green}, #00c48c)` 
          : `linear-gradient(135deg, ${colors.accent}, ${colors.accentDim})`,
        borderRadius: 20,
        padding: "24px 20px",
        margin: "0 20px 20px",
        color: theme === "light" ? "#fff" : "#000",
      }}
    >
      <div style={{ fontSize: 14, opacity: 0.9, marginBottom: 8 }}>Total Balance</div>
      <div
        style={{
          fontFamily: "Syne, sans-serif",
          fontWeight: 800,
          fontSize: 36,
          marginBottom: 12,
        }}
      >
        {formatKes(data?.kes || 0)}
      </div>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <div style={{ fontSize: 13, opacity: 0.85 }}>
          ${(data?.usdc || 0).toFixed(2)} USDC
        </div>
        <div
          style={{
            background: "rgba(255,255,255,0.2)",
            borderRadius: 8,
            padding: "4px 10px",
            fontSize: 11,
            fontWeight: 600,
          }}
        >
          Base ⚡
        </div>
      </div>
    </div>
  )
}
