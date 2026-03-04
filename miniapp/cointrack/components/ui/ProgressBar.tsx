"use client"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"

interface ProgressBarProps {
  current: number
  total: number
  color?: string
}

export default function ProgressBar({ current, total, color }: ProgressBarProps) {
  const { theme } = useAppStore()
  const colors = theme === "light" ? lightTheme : darkTheme
  
  const percentage = Math.min((current / total) * 100, 100)
  const barColor = color || (theme === "light" ? colors.green : colors.accent)

  return (
    <div
      style={{
        background: theme === "light" ? colors.bg2 : colors.border,
        borderRadius: 999,
        height: 6,
        overflow: "hidden",
        width: "100%",
      }}
    >
      <div
        style={{
          height: "100%",
          borderRadius: 999,
          background: barColor,
          width: `${percentage}%`,
          transition: "width 0.3s ease",
        }}
      />
    </div>
  )
}
