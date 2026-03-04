"use client"
import { useState } from "react"
import TopBar from "@/components/layout/TopBar"
import WalletCard from "@/components/wallet/WalletCard"
import SendSheet from "@/components/wallet/SendSheet"
import DepositSheet from "@/components/wallet/DepositSheet"
import SaveSheet from "@/components/wallet/SaveSheet"
import WithdrawSheet from "@/components/wallet/WithdrawSheet"
import { useTransactions } from "@/hooks/useTransactions"
import TransactionList from "@/components/transactions/TransactionList"

export default function WalletPage() {
  const [activeSheet, setActiveSheet] = useState<string | null>(null)
  const { data, isLoading } = useTransactions({ limit: 10, source: "onchain" })

  return (
    <div>
      <TopBar title="Wallet" showAddress />
      <div style={{ paddingTop: 20 }}>
        <WalletCard
          onSend={() => setActiveSheet("send")}
          onDeposit={() => setActiveSheet("deposit")}
          onSave={() => setActiveSheet("save")}
          onWithdraw={() => setActiveSheet("withdraw")}
        />

        <div style={{ padding: "0 20px 20px" }}>
          <div
            style={{
              fontFamily: "Syne, sans-serif",
              fontWeight: 700,
              fontSize: 16,
              marginBottom: 12,
            }}
          >
            Recent Transactions
          </div>
          <TransactionList
            transactions={data?.transactions || []}
            loading={isLoading}
          />
        </div>
      </div>

      <SendSheet
        isOpen={activeSheet === "send"}
        onClose={() => setActiveSheet(null)}
      />
      <DepositSheet
        isOpen={activeSheet === "deposit"}
        onClose={() => setActiveSheet(null)}
      />
      <SaveSheet
        isOpen={activeSheet === "save"}
        onClose={() => setActiveSheet(null)}
      />
      <WithdrawSheet
        isOpen={activeSheet === "withdraw"}
        onClose={() => setActiveSheet(null)}
      />
    </div>
  )
}
