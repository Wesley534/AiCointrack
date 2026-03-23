"use client"
import { useState } from "react"
import TopBar from "@/components/layout/TopBar"
import WalletCard from "@/components/wallet/WalletCard"
import AIInsightCard from "./AIInsightCard"
import RecentTransactions from "./RecentTransactions"
import SendSheet from "@/components/wallet/SendSheet"
import DepositSheet from "@/components/wallet/DepositSheet"
import SaveSheet from "@/components/wallet/SaveSheet"
import WithdrawSheet from "@/components/wallet/WithdrawSheet"

export default function HomeTab() {
  const [activeSheet, setActiveSheet] = useState<string | null>(null)

  return (
    <div>
      <TopBar title="AiCointrack" showAddress />
      <div style={{ paddingTop: 20 }}>
        <WalletCard
          onSend={() => setActiveSheet("send")}
          onDeposit={() => setActiveSheet("deposit")}
          onSave={() => setActiveSheet("save")}
          onWithdraw={() => setActiveSheet("withdraw")}
        />
        <AIInsightCard
          insight="You're spending 15% less on dining this month! Keep it up to reach your savings goal faster."
          type="success"
        />
        <RecentTransactions />
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
