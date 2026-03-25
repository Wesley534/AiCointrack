import { useQuery } from "@tanstack/react-query"
import { useAccount, useConfig } from "wagmi"
import { getUsdcBalance, formatUsdcFromWei } from "@/lib/wagmi"
import { useAppStore } from "@/store"
import { usdcToKes } from "@/lib/format"

export function useWalletBalance() {
  const { address } = useAccount()
  const config = useConfig()
  const { usdKesRate, setWalletBalance } = useAppStore()

  return useQuery({
    queryKey: ["wallet-balance", address],
    queryFn: async () => {
      if (!address) return { usdc: 0, kes: 0 }

      const balanceWei = await getUsdcBalance(config, address)
      const usdc = formatUsdcFromWei(balanceWei)
      const kes = usdcToKes(usdc, usdKesRate)

      setWalletBalance(usdc, kes, usdKesRate)

      return { usdc, kes }
    },
    // JWT not required for on-chain balance reads — enable when address is present
    enabled: !!address,
    staleTime: 60000,
    gcTime: 5 * 60000,
    refetchOnMount: true,
    refetchInterval: 30000,
  })
}