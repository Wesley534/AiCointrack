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
    staleTime: 60000,
    gcTime: 5 * 60000,
    refetchOnMount: true,
    refetchInterval: 60000,
  })

  return {
    data: query.data,
    isLoading: query.isPending && query.fetchStatus === "fetching",
    isFetching: query.isFetching,
    error: query.error,
    refetch: query.refetch,
  }
}