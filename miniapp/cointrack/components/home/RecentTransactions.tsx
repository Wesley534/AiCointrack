"use client"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"
import { useTransactions } from "@/hooks/useTransactions"
import { formatKes, formatRelativeDate } from "@/lib/format"
import Pill from "@/components/ui/Pill"

interface Transaction {
  id: string
  description: string
  amount: number
  category: string | { name: string }
  date: string
  source: string
}

export default function RecentTransactions() {
  const { theme } = useAppStore()
  const { data, isLoading } = useTransactions({ limit: 5 })
  const colors = theme === "light" ? lightTheme : darkTheme

  if (isLoading) {
    return (
      <div style={{ padding: "0 20px" }}>
        <div
          style={{
            fontFamily: "Syne, sans-serif",
            fontWeight: 700,
            fontSize: 16,
            color: colors.text,
            marginBottom: 12,
          }}
        >
          Recent Activity
        </div>
        <div style={{ color: colors.muted, fontSize: 14 }}>Loading...</div>
      </div>
    )
  }

  const transactions = data?.transactions || []

  return (
    <div style={{ padding: "0 20px" }}>
      <div
        style={{
          fontFamily: "Syne, sans-serif",
          fontWeight: 700,
          fontSize: 16,
          color: colors.text,
          marginBottom: 12,
        }}
      >
        Recent Activity
      </div>
      {transactions.length === 0 ? (
        <div
          style={{
            textAlign: "center",
            padding: 32,
            color: colors.muted,
            fontSize: 14,
          }}
        >
          No transactions yet
        </div>
      ) : (
        <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
          {transactions.map((tx: Transaction) => (
            <div
              key={tx.id}
              style={{
                background: colors.card,
                border: `1px solid ${colors.border}`,
                borderRadius: 12,
                padding: 12,
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
              }}
            >
              <div style={{ flex: 1 }}>
                <div
                  style={{
                    fontSize: 14,
                    fontWeight: 600,
                    color: colors.text,
                    marginBottom: 4,
                  }}
                >
                  {tx.description}
                </div>
                <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
                  <Pill variant="default">{typeof tx.category === 'string' ? tx.category : tx.category?.name || "Uncategorized"}</Pill>
                  <span style={{ fontSize: 11, color: colors.muted }}>
                    {formatRelativeDate(tx.date)}
                  </span>
                </div>
              </div>
              <div
                style={{
                  fontFamily: "Syne, sans-serif",
                  fontWeight: 700,
                  fontSize: 15,
                  color: tx.amount < 0 ? colors.red : colors.green,
                }}
              >
                {tx.amount < 0 ? "-" : "+"}
                {formatKes(Math.abs(tx.amount))}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
