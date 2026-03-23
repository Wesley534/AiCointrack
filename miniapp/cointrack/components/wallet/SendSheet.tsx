"use client"
import { useState } from "react"
import { useConfig } from "wagmi"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"
import BottomSheet from "@/components/ui/BottomSheet"
import AmountInput from "@/components/ui/AmountInput"
import { recordOnchainTx, recordOffchainTx, updateTransactionFingerprint } from "@/lib/api"
import { sendUsdc, storeHashOnChain } from "@/lib/wagmi"

interface SendSheetProps {
  isOpen: boolean
  onClose: () => void
}

type TransactionMode = "onchain" | "offchain"

export default function SendSheet({ isOpen, onClose }: SendSheetProps) {
  const { theme } = useAppStore()
  const colors = theme === "light" ? lightTheme : darkTheme

  const [mode, setMode] = useState<TransactionMode>("onchain")
  const [recipient, setRecipient] = useState("")
  const [amount, setAmount] = useState("")
  const [description, setDescription] = useState("")
  const [offchainSource, setOffchainSource] = useState<"mpesa" | "bank" | "cash">("mpesa")
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState("")
  const [step, setStep] = useState<"idle"|"sending"|"storing"|"done">("idle")
  const config = useConfig()
  const { user } = useAppStore()

  const handleSend = async () => {
    if (!amount) {
      setError("Please enter an amount")
      return
    }
    if (mode === "onchain" && !recipient) {
      setError("Please enter a recipient address")
      return
    }

    setLoading(true)
    setError("")
    setStep("idle")

    try {
      if (mode === "onchain") {
        const usdcAmount = parseFloat(amount)

        // Step 1: Send real USDC on Base Sepolia
        setStep("sending")
        const txHash = await sendUsdc(config, recipient, usdcAmount)

        // Step 2: Canonical data for fingerprint
        const canonicalData = {
          amount: usdcAmount,
          currency: "USDC",
          description: description || `Sent to ${recipient.slice(0, 8)}...`,
          recipient: recipient.toLowerCase(),
          transaction_type: "expense",
          timestamp: new Date().toISOString().slice(0, 19) + "Z",
        }

        // Step 3: Record in backend DB to get tx id
        const { data: savedTx } = await recordOnchainTx({
          tx_hash: txHash,
          amount_usdc: usdcAmount,
          recipient,
          note: canonicalData.description,
          category: "Transfer",
          transaction_type: "expense",
        })

        // Step 4: Store fingerprint on HashStore contract (non-fatal)
        if (user?.id && savedTx?.id) {
          try {
            setStep("storing")
            const fingerprint = await storeHashOnChain(
              config,
              user.id,
              savedTx.id,
              canonicalData
            )
            console.log("On-chain fingerprint stored:", fingerprint)
            console.log("View on explorer: https://sepolia.basescan.org/tx/" + txHash)

            // Step 5: Update backend with the fingerprint
            await updateTransactionFingerprint(savedTx.id, fingerprint, txHash)
          } catch (hashErr) {
            console.warn("Hash storage failed (non-fatal):", hashErr)
          }
        }
      } else {
        const txAmount = parseFloat(amount)
        await recordOffchainTx({
          amount: txAmount,
          description: description || `Sent via ${offchainSource}`,
          source: offchainSource,
          category: "Transfer",
          currency: "KES",
          transaction_type: "expense",
        })
      }

      setRecipient("")
      setAmount("")
      setDescription("")
      onClose()
    } catch (err) {
      const msg = err instanceof Error ? err.message : "Transaction failed"
      if (msg.toLowerCase().includes("rejected") || msg.toLowerCase().includes("denied")) {
        setError("Transaction cancelled. Tap Send to try again.")
      } else {
        setError(msg)
      }
    } finally {
      setLoading(false)
      setStep("done")
    }
  }

  return (
    <BottomSheet isOpen={isOpen} onClose={onClose} title="Send Money">
      <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
        {/* Transaction Mode Selector */}
        <div style={{ display: "flex", gap: 8 }}>
          <button
            onClick={() => setMode("onchain")}
            style={{
              flex: 1,
              padding: "10px 16px",
              borderRadius: 8,
              border: `1.5px solid ${colors.border}`,
              background: mode === "onchain" ? colors.accent : "transparent",
              color: mode === "onchain" ? "#fff" : colors.text,
              fontFamily: "Syne, sans-serif",
              fontWeight: 600,
              fontSize: 12,
              cursor: "pointer",
              transition: "all 0.2s",
            }}
          >
            Onchain (USDC)
          </button>
          <button
            onClick={() => setMode("offchain")}
            style={{
              flex: 1,
              padding: "10px 16px",
              borderRadius: 8,
              border: `1.5px solid ${colors.border}`,
              background: mode === "offchain" ? colors.accent : "transparent",
              color: mode === "offchain" ? "#fff" : colors.text,
              fontFamily: "Syne, sans-serif",
              fontWeight: 600,
              fontSize: 12,
              cursor: "pointer",
              transition: "all 0.2s",
            }}
          >
            Offchain
          </button>
        </div>

        {/* Onchain Mode Fields */}
        {mode === "onchain" && (
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
        )}

        {/* Offchain Mode Fields */}
        {mode === "offchain" && (
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
              Payment Method
            </div>
            <select
              value={offchainSource}
              onChange={e => setOffchainSource(e.target.value as "mpesa" | "bank" | "cash")}
              style={{
                background: theme === "light" ? colors.bg2 : colors.card,
                border: `1.5px solid ${colors.border}`,
                borderRadius: 12,
                padding: "12px 16px",
                color: colors.text,
                fontFamily: "Syne, sans-serif",
                fontSize: 13,
                width: "100%",
                outline: "none",
              }}
            >
              <option value="mpesa">M-Pesa</option>
              <option value="bank">Bank Transfer</option>
              <option value="cash">Cash</option>
            </select>
          </div>
        )}

        <AmountInput
          value={amount}
          onChange={setAmount}
          label={mode === "onchain" ? "Amount (USDC)" : "Amount (KES)"}
        />

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
            Description (Optional)
          </div>
          <input
            type="text"
            value={description}
            onChange={e => setDescription(e.target.value)}
            placeholder="What is this for?"
            style={{
              background: theme === "light" ? colors.bg2 : colors.card,
              border: `1.5px solid ${colors.border}`,
              borderRadius: 12,
              padding: "12px 16px",
              color: colors.text,
              fontSize: 13,
              width: "100%",
              outline: "none",
            }}
          />
        </div>

        {error && (
          <div style={{ color: colors.red, fontSize: 13, textAlign: "center" }}>
            {error}
          </div>
        )}

        {loading && (
          <div style={{ color: colors.muted, fontSize: 12, textAlign: "center", marginBottom: 8 }}>
            {step === "sending" && "⏳ Waiting for wallet confirmation..."}
            {step === "storing" && "🔗 Storing fingerprint on Base..."}
          </div>
        )}

        <button
          onClick={handleSend}
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
          {loading ? "Processing..." : "Send"}
        </button>
      </div>
    </BottomSheet>
  )
}
