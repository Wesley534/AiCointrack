"use client";
import { ReactNode, useState } from "react";
import { baseSepolia } from "wagmi/chains";
import { WagmiProvider, createConfig, http, fallback } from "wagmi";
import { Attribution } from "@/lib/attribution";
import { coinbaseWallet } from "wagmi/connectors";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";

const DATA_SUFFIX: { value: `0x${string}` } = {
  value: Attribution.toDataSuffix({ codes: ["bc_x888kh8t"] }) as `0x${string}`,
};

const wagmiConfig = createConfig({
  chains: [baseSepolia],
  transports: {
    [baseSepolia.id]: fallback([
      http("https://sepolia.base.org"),
      http("https://base-sepolia-rpc.publicnode.com"),
      http(),
    ]),
  },
  dataSuffix: DATA_SUFFIX,
  connectors: [
    coinbaseWallet({
      appName: "AiCoinTrack",
      // Workaround: backend SIWE verification may not yet support ERC-6492
      // smart-wallet signatures reliably. Allow EOA signatures so login can
      // complete end-to-end (deep-link + backend auth).
      preference: "all",
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
