"use client"
import TopBar from "@/components/layout/TopBar"
import BalanceSummary from "./BalanceSummary"
import AIInsightCard from "./AIInsightCard"
import RecentTransactions from "./RecentTransactions"

export default function HomeTab() {
  return (
    <div>
      <TopBar title="Cointrack" showAddress />
      <div style={{ paddingTop: 20 }}>
        <BalanceSummary />
        <AIInsightCard
          insight="You're spending 15% less on dining this month! Keep it up to reach your savings goal faster."
          type="success"
        />
        <RecentTransactions />
      </div>
    </div>
  )
}
