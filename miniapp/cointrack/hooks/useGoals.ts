import { useQuery } from "@tanstack/react-query"
import { getGoals } from "@/lib/api"

export function useGoals() {
  const query = useQuery({
    queryKey: ["goals"],
    queryFn: async () => {
      const response = await getGoals()
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
