import { useQuery } from "@tanstack/react-query"
import { getCurrentBudget } from "@/lib/api"
import { useAppStore } from "@/store"

export function useBudget() {
  const jwt = useAppStore(state => state.jwt)
  const _hasHydrated = useAppStore(state => state._hasHydrated)

  const query = useQuery({
    queryKey: ["budget"],
    queryFn: async () => {
      const response = await getCurrentBudget()
      return response.data
    },
    enabled: !!jwt && _hasHydrated,
    staleTime: 30_000,
    refetchOnMount: true,
    refetchInterval: 60_000,
    gcTime: 5 * 60_000,
  })

  return {
    data: query.data,
    isLoading: query.isLoading,
    error: query.error,
    refetch: query.refetch,
  }
}