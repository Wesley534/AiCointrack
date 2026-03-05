import { useState, useEffect } from "react"
import { getShoppingLists } from "@/lib/api"

export function useShoppingLists() {
  const [data, setData] = useState<any>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchLists = async () => {
    try {
      setIsLoading(true)
      const response = await getShoppingLists()
      setData({ lists: response.data })
      setError(null)
    } catch (err: any) {
      setError(err.message || "Failed to fetch shopping lists")
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    fetchLists()
  }, [])

  return { data, isLoading, error, refetch: fetchLists }
}
