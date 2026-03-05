"use client"
import { useState } from "react"
import BottomSheet from "@/components/ui/BottomSheet"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"
import { createBudget } from "@/lib/api"

interface CreateBudgetSheetProps {
  isOpen: boolean
  onClose: () => void
  onSuccess: () => void
}

const BUDGET_KINDS = ["need", "want", "save"]
const BUDGET_TAGS = ["Food", "Transport", "Entertainment", "Utilities", "Shopping", "Health", "Other"]

export default function CreateBudgetSheet({ isOpen, onClose, onSuccess }: CreateBudgetSheetProps) {
  const { theme } = useAppStore()
  const colors = theme === "light" ? lightTheme : darkTheme
  const [label, setLabel] = useState("")
  const [planned, setPlanned] = useState("")
  const [tag, setTag] = useState(BUDGET_TAGS[0])
  const [kind, setKind] = useState(BUDGET_KINDS[0])
  const [month, setMonth] = useState(new Date().toISOString().slice(0, 7))
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

    setLoading(true)
    setError("")

    try {
      console.log("Creating budget with:", { label, planned, tag, kind, month })
      
      await createBudget({
        label: label.trim(),
        planned: parseFloat(planned),
        tag,
        kind,
        month,
      })

      setLabel("")
      setPlanned("")
      setTag(BUDGET_TAGS[0])
      setKind(BUDGET_KINDS[0])
      setMonth(new Date().toISOString().slice(0, 7))
      onSuccess()
      onClose()
    } catch (err) {
      console.error("Error creating budget:", err)
      const error = err as { response?: { data?: { detail?: string } }; message?: string }
      setError(error.response?.data?.detail || error.message || "Failed to create budget")
    } finally {
      setLoading(false)
    }
  }

  return (
    <BottomSheet isOpen={isOpen} onClose={onClose} title="Create Budget">
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
          {loading ? "Creating..." : "Create Budget"}
        </button>
      </div>
    </BottomSheet>
  )
}
