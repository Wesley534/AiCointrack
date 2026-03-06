import { useQuery } from "@tanstack/react-query"
import { getCurrentBudget } from "@/lib/api"
import { useAppStore } from "@/store"

export function useBudget() {
  const jwt = useAppStore(state => state.jwt)

  const query = useQuery({
    queryKey: ["budget"],
    queryFn: async () => {
      const response = await getCurrentBudget()
      return response.data
    },
    enabled: !!jwt,
    staleTime: 30_000,
    refetchOnMount: true,
    refetchInterval: 60_000,
    gcTime: 5 * 60_000,
  })

  return {
    data: query.data,
    isLoading: query.isLoading,
    isFetching: query.isFetching,
    error: query.error,
    refetch: query.refetch,
  }
}