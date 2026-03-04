"use client"
import { useState } from "react"
import TopBar from "@/components/layout/TopBar"
import TransactionList from "@/components/transactions/TransactionList"
import AddTransactionSheet from "@/components/transactions/AddTransactionSheet"
import { useTransactions } from "@/hooks/useTransactions"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"

export default function TransactionsPage() {
  const { theme } = useAppStore()
  const colors = theme === "light" ? lightTheme : darkTheme
  const [showAddSheet, setShowAddSheet] = useState(false)
  const { data, isLoading, refetch } = useTransactions({ limit: 50 })

  return (
    <div>
      <TopBar title="Transactions" />
      <div style={{ paddingTop: 20 }}>
        <div style={{ padding: "0 20px 16px", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div
            style={{
              fontFamily: "Syne, sans-serif",
              fontWeight: 700,
              fontSize: 16,
            }}
          >
            All Transactions
          </div>
          <button
            onClick={() => setShowAddSheet(true)}
            style={{
              background: theme === "light" ? colors.green : colors.accent,
              color: theme === "light" ? "#fff" : "#000",
              border: "none",
              borderRadius: 12,
              padding: "10px 16px",
              fontSize: 13,
              fontWeight: 700,
              cursor: "pointer",
              fontFamily: "Syne, sans-serif",
              display: "flex",
              alignItems: "center",
              gap: 6,
            }}
          >
            <span style={{ fontSize: 16 }}>+</span> Add
          </button>
        </div>

        <TransactionList
          transactions={data?.transactions || []}
          loading={isLoading}
        />
      </div>

      <AddTransactionSheet
        isOpen={showAddSheet}
        onClose={() => setShowAddSheet(false)}
        onSuccess={() => refetch()}
      />
    </div>
  )
}
