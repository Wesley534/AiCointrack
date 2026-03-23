"use client"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"
import { formatUSD } from "@/lib/format"
import ProgressBar from "@/components/ui/ProgressBar"

interface GoalCardProps {
  goal: {
    id: string
    name: string
    icon?: string
    target_amount?: number
    target: number
    current_amount?: number
    saved: number
    deadline?: string
  }
  onContribute?: () => void
}

export default function GoalCard({ goal, onContribute }: GoalCardProps) {
  const { theme } = useAppStore()
  const colors = theme === "light" ? lightTheme : darkTheme

  const currentAmount = goal.saved || goal.current_amount || 0
  const targetAmount = goal.target || goal.target_amount || 0
  const percentage = targetAmount > 0 ? (currentAmount / targetAmount) * 100 : 0
  const remaining = targetAmount - currentAmount

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
          {goal.icon && <span style={{ fontSize: 32 }}>{goal.icon}</span>}
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
            {goal.deadline && (
              <div style={{ fontSize: 11, color: colors.muted }}>
                Target: {goal.deadline}
              </div>
            )}
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
            {formatUSD(currentAmount)} / {formatUSD(targetAmount)}
          </div>
        </div>
        <ProgressBar
          current={currentAmount}
          total={targetAmount}
          color={colors.accent}
        />
      </div>

      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <div style={{ fontSize: 13, color: colors.muted }}>
          {percentage >= 100 ? "🎉 Goal reached!" : `${formatUSD(remaining)} to go`}
        </div>
        {onContribute && percentage < 100 && (
          <button
            onClick={onContribute}
            style={{
              background: colors.accent,
              color: "#fff",
              border: "none",
              borderRadius: 8,
              padding: "6px 12px",
              fontSize: 12,
              fontWeight: 700,
              cursor: "pointer",
              fontFamily: "Syne, sans-serif",
            }}
          >
            Contribute
          </button>
        )}
      </div>
    </div>
  )
}
