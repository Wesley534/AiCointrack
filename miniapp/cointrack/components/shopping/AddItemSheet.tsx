"use client"
import { useState } from "react"
import BottomSheet from "@/components/ui/BottomSheet"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"
import { addShoppingItem } from "@/lib/api"

interface AddItemSheetProps {
  isOpen: boolean
  onClose: () => void
  listId: number
  onSuccess: () => void
}

export default function AddItemSheet({ isOpen, onClose, listId, onSuccess }: AddItemSheetProps) {
  const { theme } = useAppStore()
  const colors = theme === "light" ? lightTheme : darkTheme
  const [name, setName] = useState("")
  const [qty, setQty] = useState("1")
  const [price, setPrice] = useState("")
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState("")

  const handleSubmit = async () => {
    if (!name.trim()) {
      setError("Please enter an item name")
      return
    }
    if (!qty || parseInt(qty) <= 0) {
      setError("Please enter a valid quantity")
      return
    }
    if (!price || parseFloat(price) <= 0) {
      setError("Please enter a valid price")
      return
    }

    setLoading(true)
    setError("")

    try {
      await addShoppingItem(listId, {
        name: name.trim(),
        qty: parseInt(qty),
        price: parseFloat(price),
      })
      setName("")
      setQty("1")
      setPrice("")
      onSuccess()
      onClose()
    } catch (err) {
      const error = err as { response?: { data?: { detail?: string } } }
      setError(error.response?.data?.detail || "Failed to add item")
    } finally {
      setLoading(false)
    }
  }

  return (
    <BottomSheet isOpen={isOpen} onClose={onClose} title="Add Item">
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
            Item Name
          </label>
          <input
            type="text"
            value={name}
            onChange={e => setName(e.target.value)}
            placeholder="e.g., Milk, Bread, etc."
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
              Quantity
            </label>
            <input
              type="number"
              value={qty}
              onChange={e => setQty(e.target.value)}
              min="1"
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
              Price ($)
            </label>
            <input
              type="number"
              value={price}
              onChange={e => setPrice(e.target.value)}
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
          {loading ? "Adding..." : "Add Item"}
        </button>
      </div>
    </BottomSheet>
  )
}
