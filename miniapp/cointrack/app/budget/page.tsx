"use client"
import TopBar from "@/components/layout/TopBar"
import BudgetSummaryBar from "@/components/budget/BudgetSummaryBar"
import CategoryCard from "@/components/budget/CategoryCard"
import { useBudget } from "@/hooks/useBudget"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"

interface Category {
  name: string
  icon: string
  spent: number
  budget: number
  type: "need" | "want" | "save"
}

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

  const displayCategories = categories.length > 0 ? categories : []

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
            {displayCategories.map((cat: Category, idx: number) => (
              <CategoryCard key={idx} category={cat} />
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
