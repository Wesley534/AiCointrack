"use client"
import { usePathname } from "next/navigation"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"

const TABS = [
  { key: "home", label: "Home", icon: "🏠", href: "/dashboard" },
  { key: "wallet", label: "Wallet", icon: "💳", href: "/wallet" },
  { key: "budget", label: "Budget", icon: "📊", href: "/budget" },
  { key: "savings", label: "Savings", icon: "🎯", href: "/savings" },
  { key: "transactions", label: "Transactions", icon: "📝", href: "/transactions" },
]

export default function BottomNav() {
  const pathname = usePathname()
  const { theme, jwt } = useAppStore()
  const colors = theme === "light" ? lightTheme : darkTheme

  // Don't show nav on the auth/splash page or when not authenticated
  if (!jwt || pathname === "/") return null

  return (
    <nav
      style={{
        position: "fixed",
        bottom: 0,
        left: "50%",
        transform: "translateX(-50%)",
        width: "100%",
        maxWidth: 390,
        background: colors.card,
        borderTop: `1px solid ${colors.border}`,
        display: "flex",
        justifyContent: "space-around",
        padding: "8px 0 12px",
        zIndex: 100,
      }}
    >
      {TABS.map(tab => {
        const isActive = pathname === tab.href
        return (
          <a
            key={tab.key}
            href={tab.href}
            style={{
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              gap: 4,
              textDecoration: "none",
              opacity: isActive ? 1 : 0.5,
              transition: "opacity 0.2s",
            }}
          >
            <span style={{ fontSize: 20 }}>{tab.icon}</span>
            <span
              style={{
                fontSize: 10,
                fontWeight: isActive ? 700 : 400,
                color: isActive ? colors.accent : colors.muted,
                fontFamily: "Syne, sans-serif",
              }}
            >
              {tab.label}
            </span>
          </a>
        )
      })}
    </nav>
  )
}