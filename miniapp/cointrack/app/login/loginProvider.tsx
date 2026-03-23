"use client";
import { ReactNode, useState } from "react";
import { baseSepolia } from "wagmi/chains";
import { WagmiProvider, createConfig, http } from "wagmi";
import { Attribution } from "@/lib/attribution";
import { coinbaseWallet } from "wagmi/connectors";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";

const DATA_SUFFIX: { value: `0x${string}` } = {
  value: Attribution.toDataSuffix({ codes: ["bc_x888kh8t"] }) as `0x${string}`,
};

const wagmiConfig = createConfig({
  chains: [baseSepolia],
  transports: { [baseSepolia.id]: http() },
  dataSuffix: DATA_SUFFIX,
  connectors: [
    coinbaseWallet({
      appName: "AiCoinTrack",
      preference: "smartWalletOnly",
    }),
  ],
});

export function LoginProvider({ children }: { children: ReactNode }) {
  const [queryClient] = useState(() => new QueryClient({
    defaultOptions: { queries: { retry: false, staleTime: 30_000 } },
  }));

  return (
    <WagmiProvider config={wagmiConfig}>
      <QueryClientProvider client={queryClient}>
        {children}
      </QueryClientProvider>
    </WagmiProvider>
  );
}
