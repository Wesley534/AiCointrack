"use client"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"

export default function BottomNav() {
  const { activeTab, setActiveTab, theme } = useAppStore()
  const colors = theme === "light" ? lightTheme : darkTheme

  const tabs = [
    { id: "home" as const, icon: "🏠", label: "Home" },
    { id: "wallet" as const, icon: "💰", label: "Wallet" },
    { id: "budget" as const, icon: "📊", label: "Budget" },
    { id: "savings" as const, icon: "🎯", label: "Goals" },
    { id: "transactions" as const, icon: "📝", label: "History" },
  ]

  return (
    <nav
      style={{
        position: "fixed",
        bottom: 0,
        left: 0,
        right: 0,
        maxWidth: 390,
        margin: "0 auto",
        background: colors.card,
        borderTop: `1px solid ${colors.border}`,
        display: "flex",
        justifyContent: "space-around",
        padding: "10px 0 20px",
        zIndex: 100,
      }}
    >
      {tabs.map(tab => (
        <button
          key={tab.id}
          onClick={() => setActiveTab(tab.id)}
          style={{
            background: "transparent",
            border: "none",
            cursor: "pointer",
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            gap: 3,
            padding: 0,
            color: activeTab === tab.id 
              ? (theme === "light" ? colors.green : colors.accent)
              : colors.muted,
            transition: "color 0.2s",
          }}
        >
          <span style={{ fontSize: 20 }}>{tab.icon}</span>
          <span style={{ fontSize: 9, fontWeight: 600 }}>{tab.label}</span>
        </button>
      ))}
    </nav>
  )
}
