import { useQuery } from "@tanstack/react-query"
import { getCurrentBudget } from "@/lib/api"

export function useBudget() {
  return useQuery({
    queryKey: ["budget"],
    queryFn: async () => {
      const response = await getCurrentBudget()
      return response.data
    },
    staleTime: 60000, // 1 minute
  })
}
