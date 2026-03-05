import { useQuery } from "@tanstack/react-query"
import { getTransactions } from "@/lib/api"

export function useTransactions(params?: {
  limit?: number
  offset?: number
  source?: string
  month?: string
}) {
  return useQuery({
    queryKey: ["transactions", params],
    queryFn: async () => {
      const response = await getTransactions(params)
      const raw = response.data
      const list = Array.isArray(raw) ? raw : (raw?.transactions ?? [])
      return {
        transactions: list.map((tx: { id?: number; created_at?: string;[k: string]: unknown }) => ({
          ...tx,
          id: String(tx.id ?? Math.random()),
          date: tx.created_at ?? tx.date ?? new Date().toISOString(),
          amount: tx.transaction_type === "income" ? Math.abs(Number(tx.amount)) : -Math.abs(Number(tx.amount)),
        })),
      }
    },
    staleTime: 0,
    refetchInterval: 15000,
  })
}
