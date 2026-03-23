"use client"
import { useState } from "react"
import BottomSheet from "@/components/ui/BottomSheet"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"
import { contributeToGoal } from "@/lib/api"

interface ContributeSheetProps {
  isOpen: boolean
  onClose: () => void
  goal: {
    id: string | number
    name: string
    target?: number
    target_amount?: number
    saved?: number
    current_amount?: number
  } | null
  onSuccess: () => void
}

export default function ContributeSheet({ isOpen, onClose, goal, onSuccess }: ContributeSheetProps) {
  const { theme } = useAppStore()
  const colors = theme === "light" ? lightTheme : darkTheme
  const [amount, setAmount] = useState("")
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState("")

  const handleSubmit = async () => {
    if (!amount || parseFloat(amount) <= 0) {
      setError("Please enter a valid amount")
      return
    }

    if (!goal) {
      setError("No goal selected")
      return
    }

    setLoading(true)
    setError("")

    try {
      // In a real implementation, you'd initiate a blockchain transaction here
      // For now, we'll use a mock transaction hash
      const mockTxHash = "0x" + Math.random().toString(16).substring(2, 66)
      
      await contributeToGoal(goal.id.toString(), {
        amount_usdc: parseFloat(amount),
        tx_hash: mockTxHash,
      })
      
      setAmount("")
      onSuccess()
    } catch (err) {
      const error = err as { response?: { data?: { detail?: string } } }
      setError(error.response?.data?.detail || "Failed to contribute")
    } finally {
      setLoading(false)
    }
  }

  if (!goal) return null

  const currentAmount = goal.saved || goal.current_amount || 0
  const targetAmount = goal.target || goal.target_amount || 0
  const remaining = targetAmount - currentAmount

  return (
    <BottomSheet isOpen={isOpen} onClose={onClose} title={`Contribute to ${goal.name}`}>
      <div style={{ padding: 20 }}>
        <div
          style={{
            padding: 16,
            background: colors.card,
            borderRadius: 8,
            marginBottom: 20,
            border: `1px solid ${colors.border}`,
          }}
        >
          <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8 }}>
            <span style={{ fontSize: 14, color: colors.muted }}>Current Progress</span>
            <span style={{ fontSize: 14, fontWeight: 600, color: colors.text }}>
              ${currentAmount.toFixed(2)} / ${targetAmount.toFixed(2)}
            </span>
          </div>
          <div
            style={{
              width: "100%",
              height: 8,
              background: colors.border,
              borderRadius: 4,
              overflow: "hidden",
            }}
          >
            <div
              style={{
                height: "100%",
                width: `${targetAmount > 0 ? Math.min((currentAmount / targetAmount) * 100, 100) : 0}%`,
                background: colors.accent,
                transition: "width 0.3s",
              }}
            />
          </div>
          <div style={{ fontSize: 12, color: colors.muted, marginTop: 8 }}>
            ${remaining.toFixed(2)} remaining
          </div>
        </div>

        <div style={{ marginBottom: 20 }}>
          <label
            style={{
              display: "block",
              marginBottom: 8,
              fontSize: 14,
              fontWeight: 600,
              color: colors.text,
            }}
          >
            Contribution Amount ($)
          </label>
          <input
            type="number"
            value={amount}
            onChange={e => setAmount(e.target.value)}
            placeholder="0.00"
            step="0.01"
            min="0"
            max={remaining}
            style={{
              width: "100%",
              padding: 12,
              borderRadius: 8,
              border: `1px solid ${colors.border}`,
              background: colors.bg,
              color: colors.text,
              fontSize: 16,
            }}
          />
        </div>

        {error && (
          <div
            style={{
              padding: 12,
              borderRadius: 8,
              background: "rgba(239, 68, 68, 0.1)",
              color: colors.red,
              fontSize: 14,
              marginBottom: 20,
            }}
          >
            {error}
          </div>
        )}

        <button
          onClick={handleSubmit}
          disabled={loading}
          style={{
            width: "100%",
            padding: 16,
            borderRadius: 8,
            background: loading ? colors.muted : colors.accent,
            color: "#FFFFFF",
            border: "none",
            fontFamily: "Syne, sans-serif",
            fontWeight: 700,
            fontSize: 16,
            cursor: loading ? "not-allowed" : "pointer",
          }}
        >
          {loading ? "Contributing..." : "Contribute"}
        </button>
      </div>
    </BottomSheet>
  )
}
