"use client"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"
import BottomSheet from "@/components/ui/BottomSheet"
import { useAccount } from "wagmi"

interface DepositSheetProps {
  isOpen: boolean
  onClose: () => void
}

export default function DepositSheet({ isOpen, onClose }: DepositSheetProps) {
  const { theme } = useAppStore()
  const { address } = useAccount()
  const colors = theme === "light" ? lightTheme : darkTheme

  const copyAddress = () => {
    if (address) {
      navigator.clipboard.writeText(address)
      // Could add a toast notification here
    }
  }

  return (
    <BottomSheet isOpen={isOpen} onClose={onClose} title="Deposit USDC">
      <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
        <div style={{ textAlign: "center", color: colors.mid, fontSize: 14 }}>
          Send USDC on Base to your wallet address:
        </div>

        <div
          style={{
            background: theme === "light" ? colors.bg2 : colors.card,
            border: `1.5px solid ${colors.border}`,
            borderRadius: 12,
            padding: 16,
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            gap: 12,
          }}
        >
          <div
            style={{
              fontFamily: "monospace",
              fontSize: 13,
              color: colors.text,
              wordBreak: "break-all",
              textAlign: "center",
            }}
          >
            {address}
          </div>
          <button
            onClick={copyAddress}
            style={{
              background: colors.accent,
              color: "#fff",
              border: "none",
              borderRadius: 8,
              padding: "8px 16px",
              fontSize: 12,
              fontWeight: 700,
              cursor: "pointer",
              fontFamily: "Syne, sans-serif",
            }}
          >
            📋 Copy Address
          </button>
        </div>

        <div
          style={{
            background: theme === "light" ? colors.bg3 : colors.card,
            border: `1px solid ${colors.border}`,
            borderRadius: 12,
            padding: 16,
          }}
        >
          <div
            style={{
              fontSize: 12,
              color: colors.mid,
              lineHeight: 1.5,
            }}
          >
            <strong style={{ color: colors.text }}>⚠️ Important:</strong>
            <br />
            • Only send USDC on Base network
            <br />
            • Sending other tokens or using wrong network will result in loss of funds
            <br />• Transactions typically confirm in under 2 seconds
          </div>
        </div>
      </div>
    </BottomSheet>
  )
}
