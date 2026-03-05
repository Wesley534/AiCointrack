import { useQuery } from "@tanstack/react-query"
import { getGoals } from "@/lib/api"
import { useAppStore } from "@/store"

export function useGoals() {
  const jwt = useAppStore(state => state.jwt)

  const query = useQuery({
    queryKey: ["goals"],
    queryFn: async () => {
      const response = await getGoals()
      return response.data
    },
    enabled: !!jwt,
    staleTime: 0,
    refetchOnMount: true,
    refetchInterval: 15000,
  })

  return {
    data: query.data,
    isLoading: query.isLoading,
    error: query.error,
    refetch: query.refetch,
  }
}