"use client"
import { useRouter } from "next/navigation"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"
import { formatUSD } from "@/lib/format"

interface ShoppingListCardProps {
  list: {
    id: number
    name: string
    budget: number
    items: Array<{ name: string; qty: number; price: number }>
  }
  _onUpdate?: () => void
}

export default function ShoppingListCard({ list }: ShoppingListCardProps) {
  const router = useRouter()
  const { theme } = useAppStore()
  const colors = theme === "light" ? lightTheme : darkTheme

  const totalSpent = list.items.reduce((sum, item) => sum + (item.price * item.qty), 0)
  const remaining = list.budget - totalSpent
  const percentUsed = (totalSpent / list.budget) * 100

  const getStatusColor = () => {
    if (percentUsed >= 100) return "#EF4444"
    if (percentUsed >= 80) return "#F59E0B"
    return colors.green
  }

  return (
    <div
      onClick={() => router.push(`/shopping/${list.id}`)}
      style={{
        background: colors.card,
        borderRadius: 12,
        padding: 16,
        cursor: "pointer",
        border: `1px solid ${colors.border}`,
      }}
    >
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "start",
          marginBottom: 12,
        }}
      >
        <div>
          <div
            style={{
              fontFamily: "Syne, sans-serif",
              fontWeight: 700,
              fontSize: 16,
              color: colors.text,
              marginBottom: 4,
            }}
          >
            {list.name}
          </div>
          <div style={{ fontSize: 12, color: colors.muted }}>
            {list.items.length} {list.items.length === 1 ? "item" : "items"}
          </div>
        </div>
        <div style={{ textAlign: "right" }}>
          <div
            style={{
              fontFamily: "Syne, sans-serif",
              fontWeight: 700,
              fontSize: 14,
              color: getStatusColor(),
            }}
          >
            {formatUSD(totalSpent)}
          </div>
          <div style={{ fontSize: 12, color: colors.muted }}>
            of {formatUSD(list.budget)}
          </div>
        </div>
      </div>

      <div
        style={{
          width: "100%",
          height: 6,
          background: colors.border,
          borderRadius: 3,
          overflow: "hidden",
        }}
      >
        <div
          style={{
            height: "100%",
            width: `${Math.min(percentUsed, 100)}%`,
            background: getStatusColor(),
            transition: "width 0.3s",
          }}
        />
      </div>

      {remaining < 0 && (
        <div
          style={{
            marginTop: 8,
            fontSize: 12,
            color: "#EF4444",
            fontWeight: 600,
          }}
        >
          ⚠️ Over budget by {formatUSD(Math.abs(remaining))}
        </div>
      )}
    </div>
  )
}
