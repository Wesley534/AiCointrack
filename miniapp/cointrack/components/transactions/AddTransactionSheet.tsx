"use client"
import { useState } from "react"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"
import BottomSheet from "@/components/ui/BottomSheet"
import AmountInput from "@/components/ui/AmountInput"
import { recordOffchainTx } from "@/lib/api"

interface AddTransactionSheetProps {
  isOpen: boolean
  onClose: () => void
  onSuccess?: () => void
}

export default function AddTransactionSheet({ isOpen, onClose, onSuccess }: AddTransactionSheetProps) {
  const { theme } = useAppStore()
  const colors = theme === "light" ? lightTheme : darkTheme

  const [description, setDescription] = useState("")
  const [amount, setAmount] = useState("")
  const [category, setCategory] = useState("")
  const [type, setType] = useState<"expense" | "income">("expense")
  const [source, setSource] = useState<"mpesa" | "bank" | "cash">("mpesa")
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState("")

  const categories = [
    { id: "food", name: "Food & Dining", icon: "🍽️" },
    { id: "transport", name: "Transport", icon: "🚗" },
    { id: "shopping", name: "Shopping", icon: "🛍️" },
    { id: "bills", name: "Bills", icon: "📄" },
    { id: "entertainment", name: "Entertainment", icon: "🎬" },
    { id: "income", name: "Income", icon: "💰" },
  ]

  const handleSubmit = async () => {
    if (!description || !amount || !category) {
      setError("Please fill in all fields")
      return
    }

    setLoading(true)
    setError("")

    try {
      const numAmount = parseFloat(amount)

      await recordOffchainTx({
        amount: numAmount,
        description,
        source,
        category,
        currency: "KES",
        transaction_type: type,
      })

      // Reset and close
      setDescription("")
      setAmount("")
      setCategory("")
      setType("expense")
      setSource("mpesa")
      onSuccess?.()
      onClose()
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to add transaction")
    } finally {
      setLoading(false)
    }
  }

  return (
    <BottomSheet isOpen={isOpen} onClose={onClose} title="Add Transaction">
      <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
        <div>
          <div
            style={{
              fontSize: 11,
              color: colors.mid,
              marginBottom: 6,
              fontFamily: "Syne, sans-serif",
              fontWeight: 700,
              letterSpacing: "0.05em",
              textTransform: "uppercase",
            }}
          >
            Type
          </div>
          <div style={{ display: "flex", gap: 8 }}>
            <button
              onClick={() => setType("expense")}
              style={{
                flex: 1,
                background: type === "expense" 
                  ? colors.red
                  : (theme === "light" ? colors.bg2 : colors.card),
                color: type === "expense" ? "#fff" : colors.mid,
                border: `1.5px solid ${colors.border}`,
                borderRadius: 10,
                padding: "10px 16px",
                cursor: "pointer",
                fontSize: 13,
                fontWeight: 600,
              }}
            >
              Expense
            </button>
            <button
              onClick={() => setType("income")}
              style={{
                flex: 1,
                background: type === "income" 
                  ? (theme === "light" ? colors.green : colors.accent)
                  : (theme === "light" ? colors.bg2 : colors.card),
                color: type === "income"
                  ? (theme === "light" ? "#fff" : "#000")
                  : colors.mid,
                border: `1.5px solid ${colors.border}`,
                borderRadius: 10,
                padding: "10px 16px",
                cursor: "pointer",
                fontSize: 13,
                fontWeight: 600,
              }}
            >
              Income
            </button>
          </div>
        </div>

        <div>
          <div
            style={{
              fontSize: 11,
              color: colors.mid,
              marginBottom: 6,
              fontFamily: "Syne, sans-serif",
              fontWeight: 700,
              letterSpacing: "0.05em",
              textTransform: "uppercase",
            }}
          >
            Payment Source
          </div>
          <select
            value={source}
            onChange={e => setSource(e.target.value as "mpesa" | "bank" | "cash")}
            style={{
              background: theme === "light" ? colors.bg2 : colors.card,
              border: `1.5px solid ${colors.border}`,
              borderRadius: 12,
              padding: "12px 16px",
              color: colors.text,
              fontSize: 14,
              width: "100%",
              outline: "none",
              cursor: "pointer",
            }}
          >
            <option value="mpesa">M-Pesa</option>
            <option value="bank">Bank Transfer</option>
            <option value="cash">Cash</option>
          </select>
        </div>

        <div>
          <div
            style={{
              fontSize: 11,
              color: colors.mid,
              marginBottom: 6,
              fontFamily: "Syne, sans-serif",
              fontWeight: 700,
              letterSpacing: "0.05em",
              textTransform: "uppercase",
            }}
          >
            Description
          </div>
          <input
            type="text"
            value={description}
            onChange={e => setDescription(e.target.value)}
            placeholder="e.g., Grocery shopping"
            style={{
              background: theme === "light" ? colors.bg2 : colors.card,
              border: `1.5px solid ${colors.border}`,
              borderRadius: 12,
              padding: "12px 16px",
              color: colors.text,
              fontSize: 14,
              width: "100%",
              outline: "none",
            }}
          />
        </div>

        <div>
          <div
            style={{
              fontSize: 11,
              color: colors.mid,
              marginBottom: 6,
              fontFamily: "Syne, sans-serif",
              fontWeight: 700,
              letterSpacing: "0.05em",
              textTransform: "uppercase",
            }}
          >
            Category
          </div>
          <select
            value={category}
            onChange={e => setCategory(e.target.value)}
            style={{
              background: theme === "light" ? colors.bg2 : colors.card,
              border: `1.5px solid ${colors.border}`,
              borderRadius: 12,
              padding: "12px 16px",
              color: colors.text,
              fontSize: 14,
              width: "100%",
              outline: "none",
              cursor: "pointer",
            }}
          >
            <option value="">Select category...</option>
            {categories.map(cat => (
              <option key={cat.id} value={cat.id}>
                {cat.icon} {cat.name}
              </option>
            ))}
          </select>
        </div>

        <AmountInput
          value={amount}
          onChange={setAmount}
          label="Amount (KES)"
        />

        {error && (
          <div style={{ color: colors.red, fontSize: 13, textAlign: "center" }}>
            {error}
          </div>
        )}

        <button
          onClick={handleSubmit}
          disabled={loading}
          style={{
            background: theme === "light" ? colors.green : colors.accent,
            color: theme === "light" ? "#fff" : "#000",
            fontFamily: "Syne, sans-serif",
            fontWeight: 700,
            border: "none",
            borderRadius: 14,
            padding: "14px 28px",
            cursor: loading ? "not-allowed" : "pointer",
            fontSize: 14,
            width: "100%",
            opacity: loading ? 0.6 : 1,
          }}
        >
          {loading ? "Adding..." : "Add Transaction"}
        </button>
      </div>
    </BottomSheet>
  )
}
