import { useQuery } from "@tanstack/react-query"
import { getTransactions } from "@/lib/api"
import { useAppStore } from "@/store"

export function useTransactions(params?: {
  limit?: number
  offset?: number
  source?: string
  month?: string
}) {
  const jwt = useAppStore(state => state.jwt)

  const queryKey = ["transactions", params?.limit, params?.offset, params?.source, params?.month]

  return useQuery({
    queryKey,
    queryFn: async () => {
      const response = await getTransactions(params)
      const raw = response.data
      const list = Array.isArray(raw) ? raw : (raw?.transactions ?? [])
      return {
        transactions: list.map((tx: { id?: number; created_at?: string; [k: string]: unknown }) => {
          const rawType = (tx as any).transaction_type
          const type = String(rawType ?? "").toLowerCase()
          const amt = Math.abs(Number((tx as any).amount || 0))

          return {
            ...tx,
            id: String(tx.id ?? Math.random()),
            date: tx.created_at ?? (tx as any).date ?? new Date().toISOString(),
            amount: type === "income" ? amt : -amt,
          }
        }),
      }
    },
    enabled: !!jwt,
    staleTime: 30_000,
    refetchOnMount: true,
    refetchInterval: 60_000,
    gcTime: 5 * 60_000,
  })
}