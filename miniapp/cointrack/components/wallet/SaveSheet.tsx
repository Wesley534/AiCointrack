"use client"
import { useState } from "react"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"
import BottomSheet from "@/components/ui/BottomSheet"
import AmountInput from "@/components/ui/AmountInput"
import { useGoals } from "@/hooks/useGoals"
import { contributeToGoal, recordOnchainTx } from "@/lib/api"

interface Goal {
  id: string
  name: string
  saved?: number
  current_amount?: number
  target?: number
  target_amount?: number
}

interface SaveSheetProps {
  isOpen: boolean
  onClose: () => void
}

export default function SaveSheet({ isOpen, onClose }: SaveSheetProps) {
  const { theme } = useAppStore()
  const colors = theme === "light" ? lightTheme : darkTheme
  const { data: goalsData, refetch } = useGoals()

  const [selectedGoal, setSelectedGoal] = useState<string>("")
  const [amount, setAmount] = useState("")
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState("")

  const goals: Goal[] = Array.isArray(goalsData) ? goalsData : (goalsData?.goals || [])

  const handleSave = async () => {
    if (!selectedGoal || !amount) {
      setError("Please select a goal and enter an amount")
      return
    }

    setLoading(true)
    setError("")

    try {
      const usdcAmount = parseFloat(amount)

      const txHash = "0x" + Math.random().toString(16).substring(2, 18)

      await contributeToGoal(selectedGoal, {
        amount_usdc: usdcAmount,
        tx_hash: txHash,
      })

      await recordOnchainTx({
        tx_hash: txHash,
        amount_usdc: usdcAmount,
        note: `Saved to goal`,
        category: "savings",
      })

      await refetch()
      setAmount("")
      setSelectedGoal("")
      onClose()
    } catch (err) {
      setError(err instanceof Error ? err.message : "Transaction failed")
    } finally {
      setLoading(false)
    }
  }

  return (
    <BottomSheet isOpen={isOpen} onClose={onClose} title="Save to Goal">
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
            Select Goal
          </div>
          <select
            value={selectedGoal}
            onChange={e => setSelectedGoal(e.target.value)}
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
            <option value="">Choose a savings goal...</option>
            {goals.map((goal: Goal) => {
              const current = goal.saved ?? goal.current_amount ?? 0
              const target = goal.target ?? goal.target_amount ?? 0
              return (
                <option key={goal.id} value={goal.id}>
                  {goal.name} - ${Number(current).toFixed(2)} / ${Number(target).toFixed(2)}
                </option>
              )
            })}
          </select>
        </div>

        <AmountInput
          value={amount}
          onChange={setAmount}
          label="Amount to Save"
        />

        {error && (
          <div style={{ color: colors.red, fontSize: 13, textAlign: "center" }}>
            {error}
          </div>
        )}

        <button
          onClick={handleSave}
          disabled={loading}
          style={{
            background: colors.accent,
            color: "#fff",
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
          {loading ? "Processing..." : "Save"}
        </button>
      </div>
    </BottomSheet>
  )
}