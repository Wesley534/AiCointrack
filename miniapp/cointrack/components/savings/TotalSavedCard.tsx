"use client"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"
import { formatKes } from "@/lib/format"

interface TotalSavedCardProps {
  totalSaved: number
  totalGoals: number
}

export default function TotalSavedCard({ totalSaved, totalGoals }: TotalSavedCardProps) {
  const { theme } = useAppStore()
  const colors = theme === "light" ? lightTheme : darkTheme

  return (
    <div
      style={{
        background: `linear-gradient(135deg, ${colors.accent}, ${colors.accentDim})`,
        borderRadius: 20,
        padding: "24px 20px",
        margin: "0 20px 20px",
        color: "#fff",
      }}
    >
      <div style={{ fontSize: 14, opacity: 0.85, marginBottom: 8 }}>
        Total Saved
      </div>
      <div
        style={{
          fontFamily: "Syne, sans-serif",
          fontWeight: 800,
          fontSize: 36,
          marginBottom: 12,
        }}
      >
        {formatKes(totalSaved)}
      </div>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <div style={{ fontSize: 13, opacity: 0.85 }}>
          Across {totalGoals} {totalGoals === 1 ? "goal" : "goals"}
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
          🎯 Active
        </div>
      </div>
    </div>
  )
}
