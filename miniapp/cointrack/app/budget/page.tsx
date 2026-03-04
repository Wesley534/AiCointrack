"use client"
import TopBar from "@/components/layout/TopBar"
import BudgetSummaryBar from "@/components/budget/BudgetSummaryBar"
import CategoryCard from "@/components/budget/CategoryCard"
import { useBudget } from "@/hooks/useBudget"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"

export default function BudgetPage() {
  const { data, isLoading } = useBudget()
  const { theme } = useAppStore()
  const colors = theme === "light" ? lightTheme : darkTheme

  if (isLoading) {
    return (
      <div>
        <TopBar title="Budget" />
        <div style={{ padding: 20, textAlign: "center", color: colors.muted }}>
          Loading budget...
        </div>
      </div>
    )
  }

  const budget = data?.budget || {}
  const categories = data?.categories || []

  // Mock data if no real data
  const mockCategories = [
    { name: "Food & Dining", icon: "🍽️", spent: 15000, budget: 20000, type: "need" as const },
    { name: "Transport", icon: "🚗", spent: 8000, budget: 10000, type: "need" as const },
    { name: "Shopping", icon: "🛍️", spent: 12000, budget: 15000, type: "want" as const },
    { name: "Entertainment", icon: "🎬", spent: 5000, budget: 8000, type: "want" as const },
    { name: "Savings", icon: "💰", spent: 10000, budget: 15000, type: "save" as const },
  ]

  const displayCategories = categories.length > 0 ? categories : mockCategories

  return (
    <div>
      <TopBar title="Budget" />
      <div style={{ paddingTop: 20 }}>
        <BudgetSummaryBar
          spent={budget.total_spent || 50000}
          budget={budget.total_budget || 68000}
          currency="KES"
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
            Categories
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
            {displayCategories.map((cat: any, idx: number) => (
              <CategoryCard key={idx} category={cat} />
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
