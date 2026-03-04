import { useQuery } from "@tanstack/react-query"
import { getGoals } from "@/lib/api"

export function useGoals() {
  return useQuery({
    queryKey: ["goals"],
    queryFn: async () => {
      const response = await getGoals()
      return response.data
    },
    staleTime: 60000, // 1 minute
  })
}
