"use client"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"
import { formatKes, formatDate } from "@/lib/format"
import ProgressBar from "@/components/ui/ProgressBar"

interface GoalCardProps {
  goal: {
    id: string
    name: string
    icon: string
    target_amount: number
    current_amount: number
    deadline: string
  }
  onContribute?: () => void
}

export default function GoalCard({ goal, onContribute }: GoalCardProps) {
  const { theme } = useAppStore()
  const colors = theme === "light" ? lightTheme : darkTheme

  const percentage = (goal.current_amount / goal.target_amount) * 100
  const remaining = goal.target_amount - goal.current_amount

  return (
    <div
      style={{
        background: colors.card,
        border: `1px solid ${colors.border}`,
        borderRadius: 16,
        padding: 16,
      }}
    >
      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 12 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <span style={{ fontSize: 32 }}>{goal.icon}</span>
          <div>
            <div
              style={{
                fontSize: 16,
                fontWeight: 600,
                color: colors.text,
                marginBottom: 2,
              }}
            >
              {goal.name}
            </div>
            <div style={{ fontSize: 11, color: colors.muted }}>
              Target: {formatDate(goal.deadline)}
            </div>
          </div>
        </div>
      </div>

      <div style={{ marginBottom: 12 }}>
        <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 6 }}>
          <div style={{ fontSize: 13, color: colors.mid }}>Progress</div>
          <div
            style={{
              fontFamily: "Syne, sans-serif",
              fontWeight: 700,
              fontSize: 14,
              color: colors.text,
            }}
          >
            {formatKes(goal.current_amount)} / {formatKes(goal.target_amount)}
          </div>
        </div>
        <ProgressBar
          current={goal.current_amount}
          total={goal.target_amount}
          color={theme === "light" ? colors.green : colors.accent}
        />
      </div>

      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <div style={{ fontSize: 13, color: colors.muted }}>
          {percentage >= 100 ? "🎉 Goal reached!" : `${formatKes(remaining)} to go`}
        </div>
        {onContribute && percentage < 100 && (
          <button
            onClick={onContribute}
            style={{
              background: theme === "light" ? colors.green : colors.accent,
              color: theme === "light" ? "#fff" : "#000",
              border: "none",
              borderRadius: 8,
              padding: "6px 12px",
              fontSize: 12,
              fontWeight: 700,
              cursor: "pointer",
              fontFamily: "Syne, sans-serif",
            }}
          >
            + Add
          </button>
        )}
      </div>
    </div>
  )
}
