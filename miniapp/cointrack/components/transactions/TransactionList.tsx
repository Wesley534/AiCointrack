"use client"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"
import TransactionItem from "./TransactionItem"

interface TransactionListProps {
  transactions: any[]
  loading?: boolean
}

export default function TransactionList({ transactions, loading }: TransactionListProps) {
  const { theme } = useAppStore()
  const colors = theme === "light" ? lightTheme : darkTheme

  if (loading) {
    return (
      <div style={{ padding: 20, textAlign: "center", color: colors.muted }}>
        Loading transactions...
      </div>
    )
  }

  if (transactions.length === 0) {
    return (
      <div
        style={{
          padding: 32,
          textAlign: "center",
          color: colors.muted,
        }}
      >
        <div style={{ fontSize: 48, marginBottom: 12 }}>📝</div>
        <div style={{ fontSize: 14 }}>No transactions yet</div>
      </div>
    )
  }

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 12, padding: "0 20px" }}>
      {transactions.map(tx => (
        <TransactionItem key={tx.id} transaction={tx} />
      ))}
    </div>
  )
}
