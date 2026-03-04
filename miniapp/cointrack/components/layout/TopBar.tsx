"use client"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"
import { truncateAddress } from "@/lib/format"
import { useAccount } from "wagmi"

interface TopBarProps {
  title: string
  showAddress?: boolean
}

export default function TopBar({ title, showAddress = false }: TopBarProps) {
  const { theme, setTheme } = useAppStore()
  const { address } = useAccount()
  const colors = theme === "light" ? lightTheme : darkTheme

  return (
    <div
      style={{
        display: "flex",
        justifyContent: "space-between",
        alignItems: "center",
        padding: "12px 20px",
        borderBottom: `1px solid ${colors.border}`,
      }}
    >
      <div>
        <div
          style={{
            fontFamily: "Syne, sans-serif",
            fontWeight: 800,
            fontSize: 20,
            color: colors.text,
          }}
        >
          {title}
        </div>
        {showAddress && address && (
          <div style={{ fontSize: 11, color: colors.muted, marginTop: 2 }}>
            {truncateAddress(address)}
          </div>
        )}
      </div>
      <button
        onClick={() => setTheme(theme === "light" ? "dark" : "light")}
        style={{
          background: theme === "light" ? colors.bg2 : colors.card,
          border: `1px solid ${colors.border}`,
          borderRadius: 8,
          padding: 8,
          cursor: "pointer",
          fontSize: 16,
        }}
      >
        {theme === "light" ? "🌙" : "☀️"}
      </button>
    </div>
  )
}
