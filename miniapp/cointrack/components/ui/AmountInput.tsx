"use client"
import { useState } from "react"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"
import { formatKes, kesToUsdc } from "@/lib/format"

interface AmountInputProps {
  value: string
  onChange: (value: string) => void
  label?: string
  showKesEquivalent?: boolean
}

export default function AmountInput({ value, onChange, label, showKesEquivalent = true }: AmountInputProps) {
  const { theme, usdKesRate } = useAppStore()
  const colors = theme === "light" ? lightTheme : darkTheme
  const [currency, setCurrency] = useState<"USDC" | "KES">("USDC")

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const val = e.target.value
    // Allow only numbers and decimal point
    if (val === "" || /^\d*\.?\d*$/.test(val)) {
      onChange(val)
    }
  }

  const toggleCurrency = () => {
    if (value) {
      const numValue = parseFloat(value)
      if (currency === "USDC") {
        // Convert to KES
        const kesValue = numValue * usdKesRate
        onChange(kesValue.toFixed(0))
      } else {
        // Convert to USDC
        const usdcValue = kesToUsdc(numValue, usdKesRate)
        onChange(usdcValue.toFixed(2))
      }
    }
    setCurrency(currency === "USDC" ? "KES" : "USDC")
  }

  const numValue = parseFloat(value) || 0
  const equivalent = currency === "USDC" 
    ? formatKes(numValue * usdKesRate)
    : `$${kesToUsdc(numValue, usdKesRate).toFixed(2)} USDC`

  return (
    <div>
      {label && (
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
          {label}
        </div>
      )}
      <div
        style={{
          background: theme === "light" ? colors.bg2 : colors.card,
          border: `1.5px solid ${colors.border}`,
          borderRadius: 12,
          padding: "12px 16px",
          display: "flex",
          alignItems: "center",
          gap: 8,
        }}
      >
        <input
          type="text"
          inputMode="decimal"
          value={value}
          onChange={handleChange}
          placeholder="0.00"
          style={{
            background: "transparent",
            border: "none",
            outline: "none",
            flex: 1,
            fontSize: 18,
            fontWeight: 600,
            color: colors.text,
            fontFamily: "Syne, sans-serif",
          }}
        />
        <button
          onClick={toggleCurrency}
          style={{
            background: theme === "light" ? colors.green : colors.accent,
            color: theme === "light" ? "#fff" : "#000",
            border: "none",
            borderRadius: 8,
            padding: "6px 12px",
            fontSize: 12,
            fontWeight: 700,
            cursor: "pointer",
            fontFamily: "Syne, sans-serif",
          }}
        >
          {currency}
        </button>
      </div>
      {showKesEquivalent && value && (
        <div
          style={{
            marginTop: 6,
            fontSize: 12,
            color: colors.muted,
            textAlign: "right",
          }}
        >
          ≈ {equivalent}
        </div>
      )}
    </div>
  )
}
