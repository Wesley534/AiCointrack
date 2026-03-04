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
      return response.data
    },
    staleTime: 30000, // 30 seconds
  })
}
