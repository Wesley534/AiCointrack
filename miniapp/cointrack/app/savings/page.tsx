"use client"
import { useState } from "react"
import TopBar from "@/components/layout/TopBar"
import TotalSavedCard from "@/components/savings/TotalSavedCard"
import GoalCard from "@/components/savings/GoalCard"
import CreateGoalSheet from "@/components/savings/CreateGoalSheet"
import ContributeSheet from "@/components/savings/ContributeSheet"
import { useGoals } from "@/hooks/useGoals"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"

interface Goal {
  id: string
  name: string
  icon?: string
  target_amount?: number
  target: number
  current_amount?: number
  saved: number
  deadline?: string
}

export default function SavingsPage() {
  const { data, isLoading, refetch } = useGoals()
  const { theme } = useAppStore()
  const colors = theme === "light" ? lightTheme : darkTheme
  const [showCreateGoal, setShowCreateGoal] = useState(false)
  const [selectedGoal, setSelectedGoal] = useState<Goal | null>(null)

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

  // Normalize goal data structure from backend
  const displayGoals = goals.map((goal: { id: string; name: string; icon?: string; target?: number; target_amount?: number; saved?: number; current_amount?: number; deadline?: string }) => ({
    ...goal,
    target_amount: goal.target,
    current_amount: goal.saved,
    target: goal.target || goal.target_amount || 0,
    saved: goal.saved || goal.current_amount || 0,
  }))
  
  const totalSaved = displayGoals.reduce((sum: number, goal: Goal) => sum + (goal.saved || 0), 0)

  return (
    <div>
      <TopBar title="Savings Goals" />
      <div style={{ paddingTop: 20, paddingBottom: 100 }}>
        <TotalSavedCard
          totalSaved={totalSaved}
          totalGoals={displayGoals.length}
        />

        <div style={{ padding: "0 20px" }}>
          <div
            style={{
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center",
              marginBottom: 12,
            }}
          >
            <div
              style={{
                fontFamily: "Syne, sans-serif",
                fontWeight: 700,
                fontSize: 16,
              }}
            >
              Your Goals
            </div>
            <button
              onClick={() => setShowCreateGoal(true)}
              style={{
                background: colors.accent,
                color: "#fff",
                border: "none",
                borderRadius: 8,
                padding: "8px 16px",
                fontFamily: "Syne, sans-serif",
                fontWeight: 600,
                fontSize: 14,
                cursor: "pointer",
              }}
            >
              + New Goal
            </button>
          </div>

          {displayGoals.length === 0 ? (
            <div
              style={{
                textAlign: "center",
                padding: 40,
                color: colors.muted,
              }}
            >
              No goals yet. Create one to start saving!
            </div>
          ) : (
            <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
              {displayGoals.map((goal: Goal) => (
                <GoalCard
                  key={goal.id}
                  goal={goal}
                  onContribute={() => setSelectedGoal(goal)}
                />
              ))}
            </div>
          )}
        </div>
      </div>

      <CreateGoalSheet
        isOpen={showCreateGoal}
        onClose={() => setShowCreateGoal(false)}
        onSuccess={refetch}
      />

      <ContributeSheet
        isOpen={!!selectedGoal}
        onClose={() => setSelectedGoal(null)}
        goal={selectedGoal}
        onSuccess={() => {
          refetch()
          setSelectedGoal(null)
        }}
      />
    </div>
  )
}
