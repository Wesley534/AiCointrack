"use client"
import { useState } from "react"
import { useConfig } from "wagmi"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"
import BottomSheet from "@/components/ui/BottomSheet"
import AmountInput from "@/components/ui/AmountInput"
import { sendUsdc } from "@/lib/wagmi"
import { recordOnchainTx } from "@/lib/api"

interface SendSheetProps {
  isOpen: boolean
  onClose: () => void
}

export default function SendSheet({ isOpen, onClose }: SendSheetProps) {
  const { theme } = useAppStore()
  const colors = theme === "light" ? lightTheme : darkTheme
  const config = useConfig()

  const [recipient, setRecipient] = useState("")
  const [amount, setAmount] = useState("")
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState("")

  const handleSend = async () => {
    if (!recipient || !amount) {
      setError("Please fill in all fields")
      return
    }

    setLoading(true)
    setError("")

    try {
      // Convert amount to USDC if needed
      const usdcAmount = parseFloat(amount)
      
      // Send USDC
      const txHash = await sendUsdc(config, recipient, usdcAmount)
      
      // Record transaction in backend
      await recordOnchainTx({
        tx_hash: txHash,
        amount_usdc: usdcAmount,
        recipient,
        note: "Sent via miniapp",
      })

      // Reset and close
      setRecipient("")
      setAmount("")
      onClose()
    } catch (err) {
      setError(err instanceof Error ? err.message : "Transaction failed")
    } finally {
      setLoading(false)
    }
  }

  return (
    <BottomSheet isOpen={isOpen} onClose={onClose} title="Send USDC">
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
            Recipient Address
          </div>
          <input
            type="text"
            value={recipient}
            onChange={e => setRecipient(e.target.value)}
            placeholder="0x..."
            style={{
              background: theme === "light" ? colors.bg2 : colors.card,
              border: `1.5px solid ${colors.border}`,
              borderRadius: 12,
              padding: "12px 16px",
              color: colors.text,
              fontFamily: "monospace",
              fontSize: 13,
              width: "100%",
              outline: "none",
            }}
          />
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
          onClick={handleSend}
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
          {loading ? "Sending..." : "Send"}
        </button>
      </div>
    </BottomSheet>
  )
}
