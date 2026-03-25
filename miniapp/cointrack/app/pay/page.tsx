"use client"
import { useEffect, useState, Suspense } from "react"
import { useSearchParams } from "next/navigation"
import { payWithBase, getBasePaymentStatus, BasePaymentResult, BasePaymentStatus } from "@/lib/basePay"

function PayFlow() {
  const searchParams = useSearchParams()
  const amountStr = searchParams.get("amount")
  const to = searchParams.get("to")
  const redirectParams = searchParams.get("redirect")

  const [loading, setLoading] = useState(true)
  const [error, setError] = useState("")

  useEffect(() => {
    if (!amountStr || !to || !redirectParams) {
      setError("Missing parameters. Required: amount, to, redirect")
      setLoading(false)
      return
    }

    const processPayment = async () => {
      try {
        setLoading(true)
        // Call Base Pay SDK via window.base provider
        const payment = await payWithBase(amountStr, to, true) as BasePaymentResult
        
        let txHash = ""
        let isCompleted = false
        const paymentId = payment?.id
        
        // Wait for completion status
        if (paymentId) {
            const timeoutMs = 120_000
            const start = Date.now()
            let status: BasePaymentStatus | null = null
            
            while (Date.now() - start < timeoutMs) {
                status = await getBasePaymentStatus(paymentId, true)
                if (status?.status === "completed" || status?.status === "failed") {
                    break
                }
                await new Promise(r => setTimeout(r, 2000))
            }
            if (status?.status === "completed") {
                isCompleted = true
            }
            txHash = status?.transactionHash ? String(status.transactionHash) : paymentId
        }

        const statusStr = isCompleted ? "completed" : "failed"
        const redirectUrl = `${redirectParams}://pay?status=${statusStr}&id=${paymentId || ""}&txHash=${txHash || ""}`
        window.location.href = redirectUrl
      } catch (err: unknown) {
        console.error("Base Pay error:", err)
        const message = err instanceof Error ? err.message : String(err)
        setError("Payment failed or cancelled: " + message)
        const redirectUrl = `${redirectParams}://pay?status=failed&error=${encodeURIComponent(message)}`
        window.location.href = redirectUrl
      } finally {
        setLoading(false)
      }
    }

    processPayment()
  }, [amountStr, to, redirectParams])

  return (
    <div style={{ padding: 24, textAlign: "center", fontFamily: "Syne, sans-serif" }}>
      {loading ? (
        <div>
          <h2 style={{ fontSize: 24, fontWeight: "bold" }}>Processing Payment...</h2>
          <p>Please authorize the transaction in your Base/Coinbase Wallet browser.</p>
        </div>
      ) : error ? (
        <div>
          <h2 style={{ fontSize: 24, fontWeight: "bold", color: "red" }}>Error</h2>
          <p>{error}</p>
        </div>
      ) : (
        <div>
          <h2 style={{ fontSize: 24, fontWeight: "bold", color: "green" }}>Completed</h2>
          <p>Redirecting back to app...</p>
        </div>
      )}
    </div>
  )
}

export default function PayPage() {
  return (
    <Suspense fallback={<div style={{ padding: 24 }}>Loading...</div>}>
      <PayFlow />
    </Suspense>
  )
}
