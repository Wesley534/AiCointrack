"use client"
import TopBar from "@/components/layout/TopBar"
import TotalSavedCard from "@/components/savings/TotalSavedCard"
import GoalCard from "@/components/savings/GoalCard"
import { useGoals } from "@/hooks/useGoals"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"

interface Goal {
  id: string
  name: string
  icon: string
  target_amount: number
  current_amount: number
  deadline: string
}

export default function SavingsPage() {
  const { data, isLoading } = useGoals()
  const { theme, setActiveSheet } = useAppStore()
  const colors = theme === "light" ? lightTheme : darkTheme

  if (isLoading) {
    return (
      <div>
        <TopBar title="Savings Goals" />
        <div style={{ padding: 20, textAlign: "center", color: colors.muted }}>
          Loading goals...
        </div>
      </div>
    )
  }

  const goals = data?.goals || []

  // Fetch from DB
  const displayGoals = goals.length > 0 ? goals : []
  const totalSaved = displayGoals.reduce((sum: number, goal: Goal) => sum + goal.current_amount, 0)

  return (
    <div>
      <TopBar title="Savings Goals" />
      <div style={{ paddingTop: 20 }}>
        <TotalSavedCard
          totalSaved={totalSaved}
          totalGoals={displayGoals.length}
        />

        <div style={{ padding: "0 20px" }}>
          <div
            style={{
              fontFamily: "Syne, sans-serif",
              fontWeight: 700,
              fontSize: 16,
              marginBottom: 12,
            }}
          >
            Your Goals
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
            {displayGoals.map((goal: Goal) => (
              <GoalCard
                key={goal.id}
                goal={goal}
                onContribute={() => setActiveSheet("save")}
              />
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
