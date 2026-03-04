"use client"
import TopBar from "@/components/layout/TopBar"
import TotalSavedCard from "@/components/savings/TotalSavedCard"
import GoalCard from "@/components/savings/GoalCard"
import { useGoals } from "@/hooks/useGoals"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"

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
  
  // Mock data if no real goals
  const mockGoals = [
    {
      id: "1",
      name: "Emergency Fund",
      icon: "🛡️",
      target_amount: 50000,
      current_amount: 30000,
      deadline: "2026-06-30",
    },
    {
      id: "2",
      name: "New Phone",
      icon: "📱",
      target_amount: 40000,
      current_amount: 15000,
      deadline: "2026-05-15",
    },
    {
      id: "3",
      name: "Vacation",
      icon: "✈️",
      target_amount: 80000,
      current_amount: 25000,
      deadline: "2026-12-01",
    },
  ]

  const displayGoals = goals.length > 0 ? goals : mockGoals
  const totalSaved = displayGoals.reduce((sum: number, goal: any) => sum + goal.current_amount, 0)

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
            {displayGoals.map((goal: any) => (
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
