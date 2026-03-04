"use client"
import { useState } from "react"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"
import BottomSheet from "@/components/ui/BottomSheet"
import AmountInput from "@/components/ui/AmountInput"
import { initiateWithdrawal, getWithdrawDestinations } from "@/lib/api"
import { useQuery } from "@tanstack/react-query"

interface WithdrawSheetProps {
  isOpen: boolean
  onClose: () => void
}

export default function WithdrawSheet({ isOpen, onClose }: WithdrawSheetProps) {
  const { theme } = useAppStore()
  const colors = theme === "light" ? lightTheme : darkTheme

  const [amount, setAmount] = useState("")
  const [destinationType, setDestinationType] = useState<"mpesa" | "bank">("mpesa")
  const [destinationId, setDestinationId] = useState("")
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState("")

  const { data: destinations } = useQuery({
    queryKey: ["withdraw-destinations"],
    queryFn: async () => {
      const response = await getWithdrawDestinations()
      return response.data
    },
  })

  const handleWithdraw = async () => {
    if (!amount || !destinationId) {
      setError("Please fill in all fields")
      return
    }

    setLoading(true)
    setError("")

    try {
      const usdcAmount = parseFloat(amount)
      
      await initiateWithdrawal({
        amount_usdc: usdcAmount,
        destination_type: destinationType,
        destination_id: destinationId,
      })

      // Reset and close
      setAmount("")
      setDestinationId("")
      onClose()
    } catch (err: any) {
      setError(err.message || "Withdrawal failed")
    } finally {
      setLoading(false)
    }
  }

  const filteredDestinations = destinations?.filter(
    (d: any) => d.type === destinationType
  ) || []

  return (
    <BottomSheet isOpen={isOpen} onClose={onClose} title="Withdraw to KES">
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
            Withdraw To
          </div>
          <div style={{ display: "flex", gap: 8 }}>
            <button
              onClick={() => setDestinationType("mpesa")}
              style={{
                flex: 1,
                background: destinationType === "mpesa" 
                  ? (theme === "light" ? colors.green : colors.accent)
                  : (theme === "light" ? colors.bg2 : colors.card),
                color: destinationType === "mpesa"
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
              M-Pesa
            </button>
            <button
              onClick={() => setDestinationType("bank")}
              style={{
                flex: 1,
                background: destinationType === "bank" 
                  ? (theme === "light" ? colors.green : colors.accent)
                  : (theme === "light" ? colors.bg2 : colors.card),
                color: destinationType === "bank"
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
              Bank
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
            Destination
          </div>
          <select
            value={destinationId}
            onChange={e => setDestinationId(e.target.value)}
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
            <option value="">Select destination...</option>
            {filteredDestinations.map((dest: any) => (
              <option key={dest.id} value={dest.id}>
                {dest.label}
              </option>
            ))}
          </select>
        </div>

        <AmountInput
          value={amount}
          onChange={setAmount}
          label="Amount"
        />

        {error && (
          <div style={{ color: colors.red, fontSize: 13, textAlign: "center" }}>
            {error}
          </div>
        )}

        <button
          onClick={handleWithdraw}
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
          {loading ? "Processing..." : "Withdraw"}
        </button>
      </div>
    </BottomSheet>
  )
}
