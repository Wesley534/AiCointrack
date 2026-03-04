"use client"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"

type PillVariant = "default" | "green" | "warn" | "red" | "indigo"

interface PillProps {
  children: React.ReactNode
  variant?: PillVariant
}

export default function Pill({ children, variant = "default" }: PillProps) {
  const { theme } = useAppStore()
  const colors = theme === "light" ? lightTheme : darkTheme

  const styles = {
    default: {
      background: theme === "light" ? colors.bg2 : colors.card,
      border: `1px solid ${colors.border}`,
      color: colors.mid,
    },
    green: {
      background: theme === "light" ? colors.greenBg : "rgba(0,229,160,0.1)",
      border: `1px solid ${theme === "light" ? "rgba(0,168,107,0.25)" : "rgba(0,229,160,0.3)"}`,
      color: theme === "light" ? colors.green : colors.accent,
    },
    warn: {
      background: theme === "light" ? colors.amberBg : "rgba(245,158,11,0.1)",
      border: `1px solid ${theme === "light" ? "rgba(217,119,6,0.25)" : "rgba(245,158,11,0.3)"}`,
      color: theme === "light" ? colors.amber : darkTheme.warning,
    },
    red: {
      background: theme === "light" ? colors.redBg : "rgba(239,68,68,0.1)",
      border: `1px solid ${theme === "light" ? "rgba(220,38,38,0.25)" : "rgba(239,68,68,0.3)"}`,
      color: theme === "light" ? colors.red : darkTheme.danger,
    },
    indigo: {
      background: theme === "light" ? colors.indigoBg : "rgba(124,106,250,0.15)",
      border: `1px solid ${theme === "light" ? "rgba(79,70,229,0.25)" : "rgba(124,106,250,0.3)"}`,
      color: theme === "light" ? colors.indigo : darkTheme.purple,
    },
  }

  return (
    <span
      style={{
        ...styles[variant],
        borderRadius: 999,
        padding: "3px 10px",
        fontSize: 11,
        fontWeight: 600,
        display: "inline-block",
      }}
    >
      {children}
    </span>
  )
}
