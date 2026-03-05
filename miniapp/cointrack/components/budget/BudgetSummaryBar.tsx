"use client"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"
import { formatKes } from "@/lib/format"
import ProgressBar from "@/components/ui/ProgressBar"

interface BudgetSummaryBarProps {
  spent: number
  budget: number
  currency?: "KES" | "USDC"
}

export default function BudgetSummaryBar({ spent, budget, currency = "KES" }: BudgetSummaryBarProps) {
  const { theme } = useAppStore()
  const colors = theme === "light" ? lightTheme : darkTheme

  const remaining = budget - spent
  const percentage = budget > 0 ? (spent / budget) * 100 : 0

  const getStatusColor = () => {
    if (percentage >= 90) return colors.red
    if (percentage >= 75) return theme === "light" ? colors.amber : darkTheme.warning
    return theme === "light" ? colors.green : colors.accent
  }

  return (
    <div
      style={{
        background: colors.card,
        border: `1px solid ${colors.border}`,
        borderRadius: 16,
        padding: 20,
        margin: "0 20px 20px",
      }}
    >
      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 12 }}>
        <div>
          <div style={{ fontSize: 13, color: colors.mid, marginBottom: 4 }}>
            Spent this month
          </div>
          <div
            style={{
              fontFamily: "Syne, sans-serif",
              fontWeight: 700,
              fontSize: 24,
              color: colors.text,
            }}
          >
            {currency === "KES" ? formatKes(spent) : `$${spent.toFixed(2)}`}
          </div>
        </div>
        <div style={{ textAlign: "right" }}>
          <div style={{ fontSize: 13, color: colors.mid, marginBottom: 4 }}>
            Remaining
          </div>
          <div
            style={{
              fontFamily: "Syne, sans-serif",
              fontWeight: 700,
              fontSize: 24,
              color: getStatusColor(),
            }}
          >
            {currency === "KES" ? formatKes(remaining) : `$${remaining.toFixed(2)}`}
          </div>
        </div>
      </div>

      <ProgressBar current={spent} total={budget} color={getStatusColor()} />

      <div
        style={{
          marginTop: 8,
          fontSize: 12,
          color: colors.muted,
          textAlign: "center",
        }}
      >
        {percentage.toFixed(0)}% of budget used
      </div>
    </div>
  )
}
