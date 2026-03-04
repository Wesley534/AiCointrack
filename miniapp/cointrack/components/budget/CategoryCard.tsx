"use client"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"
import { formatKes } from "@/lib/format"
import ProgressBar from "@/components/ui/ProgressBar"
import Pill from "@/components/ui/Pill"

interface CategoryCardProps {
  category: {
    name: string
    icon: string
    spent: number
    budget: number
    type: "need" | "want" | "save"
  }
}

export default function CategoryCard({ category }: CategoryCardProps) {
  const { theme } = useAppStore()
  const colors = theme === "light" ? lightTheme : darkTheme

  const percentage = (category.spent / category.budget) * 100
  const remaining = category.budget - category.spent

  const typeColors = {
    need: theme === "light" ? colors.indigo : darkTheme.purple,
    want: theme === "light" ? colors.amber : darkTheme.warning,
    save: theme === "light" ? colors.green : colors.accent,
  }

  return (
    <div
      style={{
        background: colors.card,
        border: `1px solid ${colors.border}`,
        borderRadius: 14,
        padding: 16,
      }}
    >
      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 12 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <span style={{ fontSize: 24 }}>{category.icon}</span>
          <div>
            <div
              style={{
                fontSize: 15,
                fontWeight: 600,
                color: colors.text,
                marginBottom: 2,
              }}
            >
              {category.name}
            </div>
            <Pill
              variant={
                category.type === "need" ? "indigo" :
                category.type === "want" ? "warn" : "green"
              }
            >
              {category.type}
            </Pill>
          </div>
        </div>
        <div style={{ textAlign: "right" }}>
          <div
            style={{
              fontFamily: "Syne, sans-serif",
              fontWeight: 700,
              fontSize: 16,
              color: colors.text,
            }}
          >
            {formatKes(category.spent)}
          </div>
          <div style={{ fontSize: 11, color: colors.muted }}>
            of {formatKes(category.budget)}
          </div>
        </div>
      </div>

      <ProgressBar
        current={category.spent}
        total={category.budget}
        color={typeColors[category.type]}
      />

      <div
        style={{
          marginTop: 8,
          fontSize: 11,
          color: remaining < 0 ? colors.red : colors.muted,
          textAlign: "right",
        }}
      >
        {remaining < 0 ? `Over by ${formatKes(Math.abs(remaining))}` : `${formatKes(remaining)} left`}
      </div>
    </div>
  )
}
