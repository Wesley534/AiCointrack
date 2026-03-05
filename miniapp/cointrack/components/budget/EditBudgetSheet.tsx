"use client"
import { useState } from "react"
import BottomSheet from "@/components/ui/BottomSheet"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"
import { updateBudget } from "@/lib/api"

interface EditBudgetSheetProps {
  isOpen: boolean
  onClose: () => void
  budget: {
    id: number
    label?: string
    planned?: number
    actual?: number
    tag?: string
    kind?: string
    month?: string
  } | null
  onSuccess: () => void
}

const BUDGET_KINDS = ["need", "want", "save"]
const BUDGET_TAGS = ["Food", "Transport", "Entertainment", "Utilities", "Shopping", "Health", "Other"]

export default function EditBudgetSheet({ isOpen, onClose, budget, onSuccess }: EditBudgetSheetProps) {
  const { theme } = useAppStore()
  const colors = theme === "light" ? lightTheme : darkTheme
  const [label, setLabel] = useState(budget?.label || "")
  const [planned, setPlanned] = useState(budget?.planned?.toString() || "")
  const [tag, setTag] = useState(budget?.tag || BUDGET_TAGS[0])
  const [kind, setKind] = useState(budget?.kind || BUDGET_KINDS[0])
  const [month, setMonth] = useState(budget?.month || new Date().toISOString().slice(0, 7))
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState("")

  const handleSubmit = async () => {
    if (!label.trim()) {
      setError("Please enter a budget label")
      return
    }
    if (!planned || parseFloat(planned) <= 0) {
      setError("Please enter a valid amount")
      return
    }

    if (!budget) {
      setError("No budget selected")
      return
    }

    setLoading(true)
    setError("")

    try {
      console.log("Updating budget:", budget.id, { label, planned, tag, kind, month })
      
      await updateBudget(budget.id, {
        label: label.trim(),
        planned: parseFloat(planned),
        tag,
        kind,
        month,
      })

      onSuccess()
      onClose()
    } catch (err) {
      console.error("Error updating budget:", err)
      const error = err as { response?: { data?: { detail?: string } }; message?: string }
      setError(error.response?.data?.detail || error.message || "Failed to update budget")
    } finally {
      setLoading(false)
    }
  }

  if (!budget) return null

  return (
    <BottomSheet isOpen={isOpen} onClose={onClose} title="Edit Budget">
      <div style={{ padding: 20 }}>
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
            Label
          </label>
          <input
            type="text"
            value={label}
            onChange={e => setLabel(e.target.value)}
            placeholder="e.g., Monthly Groceries"
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
            Planned Amount ($)
          </label>
          <input
            type="number"
            value={planned}
            onChange={e => setPlanned(e.target.value)}
            placeholder="0.00"
            step="0.01"
            min="0"
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

        <div style={{ display: "flex", gap: 12, marginBottom: 20 }}>
          <div style={{ flex: 1 }}>
            <label
              style={{
                display: "block",
                marginBottom: 8,
                fontSize: 14,
                fontWeight: 600,
                color: colors.text,
              }}
            >
              Type
            </label>
            <select
              value={kind}
              onChange={e => setKind(e.target.value)}
              style={{
                width: "100%",
                padding: 12,
                borderRadius: 8,
                border: `1px solid ${colors.border}`,
                background: colors.bg,
                color: colors.text,
                fontSize: 16,
              }}
            >
              {BUDGET_KINDS.map(k => (
                <option key={k} value={k}>
                  {k.charAt(0).toUpperCase() + k.slice(1)}
                </option>
              ))}
            </select>
          </div>

          <div style={{ flex: 1 }}>
            <label
              style={{
                display: "block",
                marginBottom: 8,
                fontSize: 14,
                fontWeight: 600,
                color: colors.text,
              }}
            >
              Category
            </label>
            <select
              value={tag}
              onChange={e => setTag(e.target.value)}
              style={{
                width: "100%",
                padding: 12,
                borderRadius: 8,
                border: `1px solid ${colors.border}`,
                background: colors.bg,
                color: colors.text,
                fontSize: 16,
              }}
            >
              {BUDGET_TAGS.map(t => (
                <option key={t} value={t}>
                  {t}
                </option>
              ))}
            </select>
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
            Month
          </label>
          <input
            type="month"
            value={month}
            onChange={e => setMonth(e.target.value)}
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
              color: "#EF4444",
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
          {loading ? "Updating..." : "Update Budget"}
        </button>
      </div>
    </BottomSheet>
  )
}