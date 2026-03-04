"use client"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"

interface AIInsightCardProps {
  insight: string
  type?: "info" | "warning" | "success"
}

export default function AIInsightCard({ insight, type = "info" }: AIInsightCardProps) {
  const { theme } = useAppStore()
  const colors = theme === "light" ? lightTheme : darkTheme

  const typeStyles = {
    info: {
      bg: theme === "light" ? colors.indigoBg : "rgba(124,106,250,0.15)",
      border: theme === "light" ? "rgba(79,70,229,0.25)" : "rgba(124,106,250,0.3)",
      icon: "💡",
    },
    warning: {
      bg: theme === "light" ? colors.amberBg : "rgba(245,158,11,0.1)",
      border: theme === "light" ? "rgba(217,119,6,0.25)" : "rgba(245,158,11,0.3)",
      icon: "⚠️",
    },
    success: {
      bg: theme === "light" ? colors.greenBg : "rgba(0,229,160,0.1)",
      border: theme === "light" ? "rgba(0,168,107,0.25)" : "rgba(0,229,160,0.3)",
      icon: "✨",
    },
  }

  const style = typeStyles[type]

  return (
    <div
      style={{
        background: style.bg,
        border: `1px solid ${style.border}`,
        borderRadius: 16,
        padding: 16,
        margin: "0 20px 16px",
      }}
    >
      <div style={{ display: "flex", gap: 12, alignItems: "flex-start" }}>
        <span style={{ fontSize: 20 }}>{style.icon}</span>
        <div>
          <div
            style={{
              fontWeight: 700,
              fontSize: 12,
              color: colors.text,
              marginBottom: 4,
              fontFamily: "Syne, sans-serif",
            }}
          >
            AI Insight
          </div>
          <div style={{ fontSize: 13, color: colors.mid, lineHeight: 1.5 }}>
            {insight}
          </div>
        </div>
      </div>
    </div>
  )
}
