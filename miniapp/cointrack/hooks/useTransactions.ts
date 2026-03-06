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

  // Stable key — serialize params so object identity doesn't bust the cache
  const queryKey = ["transactions", params?.limit, params?.offset, params?.source, params?.month]

  return useQuery({
    queryKey,
    queryFn: async () => {
      const response = await getTransactions(params)
      const raw = response.data
      const list = Array.isArray(raw) ? raw : (raw?.transactions ?? [])
      return {
        transactions: list.map((tx: { id?: number; created_at?: string;[k: string]: unknown }) => ({
          ...tx,
          id: String(tx.id ?? Math.random()),
          date: tx.created_at ?? tx.date ?? new Date().toISOString(),
          amount:
            tx.transaction_type === "income"
              ? Math.abs(Number(tx.amount))
              : -Math.abs(Number(tx.amount)),
        })),
      }
    },
    enabled: !!jwt,
    staleTime: 60000,
    gcTime: 5 * 60000,
    refetchOnMount: true,
    refetchInterval: 60000,
  })
}