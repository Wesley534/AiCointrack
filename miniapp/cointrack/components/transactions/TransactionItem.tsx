"use client"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"
import { formatKes, formatRelativeDate } from "@/lib/format"
import Pill from "@/components/ui/Pill"

interface TransactionItemProps {
  transaction: {
    id: string
    description: string
    amount: number
    category?: string | { name: string }
    date: string
    source: string
    onchain_hash?: string
  }
}

export default function TransactionItem({ transaction }: TransactionItemProps) {
  const { theme } = useAppStore()
  const colors = theme === "light" ? lightTheme : darkTheme

  const isExpense = transaction.amount < 0

  return (
    <div
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
          {transaction.description}
        </div>
        <div style={{ display: "flex", gap: 8, alignItems: "center", flexWrap: "wrap" }}>
          {transaction.category && (
            <Pill variant="default">{typeof transaction.category === 'string' ? transaction.category : transaction.category.name}</Pill>
          )}
          <Pill variant={transaction.source === "manual" ? "indigo" : "default"}>
            {transaction.source}
          </Pill>
          <span style={{ fontSize: 11, color: colors.muted }}>
            {formatRelativeDate(transaction.date)}
          </span>
        </div>
        {transaction.onchain_hash && (
          <a
            href={`https://sepolia.basescan.org/search?q=${transaction.onchain_hash}`}
            target="_blank"
            rel="noopener noreferrer"
            style={{
              display: "inline-flex",
              alignItems: "center",
              gap: 4,
              fontSize: 10,
              color: colors.positive,
              textDecoration: "none",
              marginTop: 4,
            }}
          >
            <span>✓</span>
            <span>Verified on-chain</span>
          </a>
        )}
      </div>
      <div
        style={{
          fontFamily: "Syne, sans-serif",
          fontWeight: 700,
          fontSize: 15,
          color: isExpense 
            ? colors.red 
            : colors.positive,
          marginLeft: 12,
        }}
      >
        {isExpense ? "-" : "+"}
        {formatKes(Math.abs(transaction.amount))}
      </div>
    </div>
  )
}
