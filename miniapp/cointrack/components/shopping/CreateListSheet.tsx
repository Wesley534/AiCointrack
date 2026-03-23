"use client"
import { useState } from "react"
import BottomSheet from "@/components/ui/BottomSheet"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"
import { createShoppingList } from "@/lib/api"

interface CreateListSheetProps {
  isOpen: boolean
  onClose: () => void
  onSuccess: () => void
}

export default function CreateListSheet({ isOpen, onClose, onSuccess }: CreateListSheetProps) {
  const { theme } = useAppStore()
  const colors = theme === "light" ? lightTheme : darkTheme
  const [name, setName] = useState("")
  const [budget, setBudget] = useState("")
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState("")

  const handleSubmit = async () => {
    if (!name.trim()) {
      setError("Please enter a list name")
      return
    }
    if (!budget || parseFloat(budget) <= 0) {
      setError("Please enter a valid budget")
      return
    }

    setLoading(true)
    setError("")

    try {
      const payload = {
        name: name.trim(),
        budget: parseFloat(budget),
      }
      console.log("Creating shopping list with payload:", payload)
      
      const response = await createShoppingList(payload)
      console.log("Shopping list created:", response)
      
      setName("")
      setBudget("")
      onSuccess()
      onClose()
    } catch (err) {
      console.error("Error creating shopping list:", err)
      const error = err as { response?: { data?: { detail?: string } }; message?: string }
      setError(error.response?.data?.detail || error.message || "Failed to create list")
    } finally {
      setLoading(false)
    }
  }

  return (
    <BottomSheet isOpen={isOpen} onClose={onClose} title="Create Shopping List">
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
            List Name
          </label>
          <input
            type="text"
            value={name}
            onChange={e => setName(e.target.value)}
            placeholder="e.g., Weekly Groceries"
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
            Budget ($)
          </label>
          <input
            type="number"
            value={budget}
            onChange={e => setBudget(e.target.value)}
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
          {loading ? "Creating..." : "Create List"}
        </button>
      </div>
    </BottomSheet>
  )
}
