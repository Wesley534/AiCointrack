"use client"
import { useState } from "react"
import TopBar from "@/components/layout/TopBar"
import BudgetSummaryBar from "@/components/budget/BudgetSummaryBar"
import CategoryCard from "@/components/budget/CategoryCard"
import CreateBudgetSheet from "@/components/budget/CreateBudgetSheet"
import EditBudgetSheet from "@/components/budget/EditBudgetSheet"
import { useBudget } from "@/hooks/useBudget"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"

interface Category {
  id: number
  name: string
  label: string
  icon: string
  spent: number
  actual?: number
  budget: number
  planned?: number
  type: "need" | "want" | "save"
  kind?: string
  tag?: string
  month?: string
}

interface BudgetItem {
  id?: number
  label?: string
  name?: string
  icon?: string
  actual?: number
  planned?: number
  kind?: string
  tag?: string
  month?: string
}

export default function BudgetPage() {
  const { data, isLoading, refetch } = useBudget()
  const { theme } = useAppStore()
  const colors = theme === "light" ? lightTheme : darkTheme
  const [showCreateSheet, setShowCreateSheet] = useState(false)
  const [selectedBudget, setSelectedBudget] = useState<Category | null>(null)

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
  let categories: Category[] = data?.categories || []

  if (Array.isArray(data) && data.length > 0) {
    categories = (data as BudgetItem[]).map((item) => ({
      id: item.id || 0,
      name: item.label || item.name || "",
      label: item.label || "",
      icon: item.icon || "📊",
      spent: item.actual || 0,
      actual: item.actual || 0,
      budget: item.planned || 0,
      planned: item.planned,
      type: (item.kind || "need") as "need" | "want" | "save",
      kind: item.kind,
      tag: item.tag,
      month: item.month,
    }))
  }

  const displayCategories = categories.length > 0 ? categories : []
  const totalSpent = displayCategories.reduce((sum, cat) => sum + (cat.spent || 0), 0)
  const totalBudget = displayCategories.reduce((sum, cat) => sum + (cat.budget || 0), 0)

  return (
    <div>
      <TopBar title="Budget" />
      <div style={{ paddingTop: 20, paddingBottom: 100 }}>
        <BudgetSummaryBar
          spent={totalSpent || budget.total_spent || 50000}
          budget={totalBudget || budget.total_budget || 68000}
          currency="KES"
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
              Categories
            </div>
            <button
              onClick={() => setShowCreateSheet(true)}
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
              + New
            </button>
          </div>

          {displayCategories.length === 0 ? (
            <div
              style={{
                textAlign: "center",
                padding: 40,
                color: colors.muted,
              }}
            >
              No budgets yet. Create one to get started!
            </div>
          ) : (
            <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
              {displayCategories.map((cat, idx) => (
                <div
                  key={idx}
                  onClick={() => setSelectedBudget(cat)}
                  style={{ cursor: "pointer" }}
                >
                  <CategoryCard category={cat} />
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      <CreateBudgetSheet
        isOpen={showCreateSheet}
        onClose={() => setShowCreateSheet(false)}
        onSuccess={refetch}
      />

      <EditBudgetSheet
        isOpen={!!selectedBudget}
        onClose={() => setSelectedBudget(null)}
        budget={selectedBudget}
        onSuccess={() => {
          refetch()
          setSelectedBudget(null)
        }}
      />
    </div>
  )
}