import { useQuery } from "@tanstack/react-query"
import { getCurrentBudget } from "@/lib/api"

export function useBudget() {
  const query = useQuery({
    queryKey: ["budget"],
    queryFn: async () => {
      const response = await getCurrentBudget()
      return response.data
    },
    staleTime: 0,
    refetchInterval: 15000,
  })

  return {
    data: query.data,
    isLoading: query.isLoading,
    error: query.error,
    refetch: query.refetch,
  }
}
