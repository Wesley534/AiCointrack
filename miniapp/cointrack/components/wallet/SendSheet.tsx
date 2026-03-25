"use client"
import { useState } from "react"
import { useQueryClient } from "@tanstack/react-query"
import { ethers } from "ethers"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"
import BottomSheet from "@/components/ui/BottomSheet"
import AmountInput from "@/components/ui/AmountInput"
import { recordOnchainTx, recordOffchainTx } from "@/lib/api"

interface SendSheetProps {
  isOpen: boolean
  onClose: () => void
}

type TransactionMode = "onchain" | "offchain"

const BASE_SEPOLIA_CHAIN_ID = BigInt(84532)
const USDC_ADDRESS = "0x036CbD53842c5426634e7929541eC2318f3dCF7e"
const USDC_ABI = [
  "function transfer(address to, uint256 amount) returns (bool)",
  "function decimals() view returns (uint8)",
]

export default function SendSheet({ isOpen, onClose }: SendSheetProps) {
  const { theme } = useAppStore()
  const colors = theme === "light" ? lightTheme : darkTheme
  const queryClient = useQueryClient()

  const [mode, setMode] = useState<TransactionMode>("onchain")
  const [recipient, setRecipient] = useState("")
  const [amount, setAmount] = useState("")
  const [description, setDescription] = useState("")
  const [offchainSource, setOffchainSource] = useState<"mpesa" | "bank" | "cash">("mpesa")
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState("")
  const [successHash, setSuccessHash] = useState("")
  const [step, setStep] = useState<"idle" | "confirm" | "sending" | "waiting">("idle")

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
    setSuccessHash("")
    setStep("idle")

    try {
      const txAmount = parseFloat(amount)
      if (Number.isNaN(txAmount) || txAmount <= 0) {
        throw new Error("Enter a valid amount")
      }

      if (mode === "onchain") {
        if (!ethers.isAddress(recipient)) {
          throw new Error("Enter a valid recipient address")
        }

        const provider = (window as Window & { ethereum?: unknown }).ethereum
        if (!provider) {
          throw new Error("Base Wallet not found")
        }

        const ethersProvider = new ethers.BrowserProvider(provider as ethers.Eip1193Provider)
        const signer = await ethersProvider.getSigner()

        const network = await ethersProvider.getNetwork()
        if (network.chainId !== BASE_SEPOLIA_CHAIN_ID) {
          throw new Error("Switch to Base Sepolia")
        }

        const usdc = new ethers.Contract(USDC_ADDRESS, USDC_ABI, signer)
        const value = ethers.parseUnits(amount, 6)

        setStep("confirm")
        const tx = await usdc.transfer(recipient, value)
        setStep("sending")

        setStep("waiting")
        const receipt = await tx.wait()
        const txHash = receipt?.hash

        if (!txHash) {
          throw new Error("Transaction confirmed but hash was unavailable")
        }

        await recordOnchainTx({
          tx_hash: txHash,
          amount_usdc: txAmount,
          recipient,
          currency: "USDC",
          description: description || "Sent via miniapp",
          category: "Transfer",
          transaction_type: "expense",
        })

        await queryClient.invalidateQueries({ queryKey: ["wallet-balance"] })
        await queryClient.invalidateQueries({ queryKey: ["transactions"] })

        setRecipient("")
        setAmount("")
        setDescription("")
        setSuccessHash(txHash)
      } else {
        await recordOffchainTx({
          amount: txAmount,
          description: description || `Sent via ${offchainSource}`,
          source: offchainSource,
          category: "Transfer",
          currency: "KES",
          transaction_type: "expense",
        })

        // Reset and close for offchain flow
        setRecipient("")
        setAmount("")
        setDescription("")
        onClose()
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : "Transaction failed")
    } finally {
      setLoading(false)
      setStep("idle")
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
          <div style={{ color: colors.muted, fontSize: 12, textAlign: "center" }}>
            {step === "confirm" && "Confirm in Base Wallet..."}
            {step === "sending" && "Sending USDC..."}
            {step === "waiting" && "Waiting for confirmation..."}
          </div>
        )}

        {successHash && (
          <div
            style={{
              background: theme === "light" ? colors.accentBg : colors.card,
              border: `1px solid ${colors.border}`,
              borderRadius: 10,
              padding: 12,
              textAlign: "center",
              fontSize: 13,
            }}
          >
            <div style={{ marginBottom: 6, color: colors.text }}>USDC sent successfully.</div>
            <a
              href={`https://sepolia.basescan.org/tx/${successHash}`}
              target="_blank"
              rel="noreferrer"
              style={{ color: colors.accent, fontWeight: 700, textDecoration: "underline" }}
            >
              View on BaseScan
            </a>
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
