import { useQuery } from "@tanstack/react-query"
import { getShoppingLists } from "@/lib/api"
import { useAppStore } from "@/store"

export function useShoppingLists() {
  const jwt = useAppStore(state => state.jwt)
  const _hasHydrated = useAppStore(state => state._hasHydrated)

  const query = useQuery({
    queryKey: ["shoppingLists"],
    queryFn: async () => {
      const response = await getShoppingLists()
      return { lists: response.data || [] }
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
    error: query.error ? (query.error as { message?: string }).message || "Failed to fetch shopping lists" : null,
    refetch: query.refetch,
  }
}