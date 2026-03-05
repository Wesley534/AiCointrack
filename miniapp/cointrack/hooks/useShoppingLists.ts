import { useQuery } from "@tanstack/react-query"
import { getShoppingLists } from "@/lib/api"

export function useShoppingLists() {
  const query = useQuery({
    queryKey: ["shoppingLists"],
    queryFn: async () => {
      const response = await getShoppingLists()
      return { lists: response.data || [] }
    },
    staleTime: 0,
    refetchInterval: 15000,
  })

  return {
    data: query.data,
    isLoading: query.isLoading,
    error: query.error ? (query.error as any).message || "Failed to fetch shopping lists" : null,
    refetch: query.refetch,
  }
}
