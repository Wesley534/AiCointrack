"use client";
import { ReactNode, useState } from "react";
import { base } from "wagmi/chains";
import { WagmiProvider, createConfig, http } from "wagmi";
import { Attribution } from "@/lib/attribution";
import { coinbaseWallet } from "wagmi/connectors";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import BottomNav from "@/components/layout/BottomNav";
import ThemeWrapper from "@/components/ThemeWrapper";

const DATA_SUFFIX: { value: `0x${string}` } = {
  value: Attribution.toDataSuffix({ codes: ["bc_x888kh8t"] }) as `0x${string}`,
};

const wagmiConfig = createConfig({
  chains: [base],
  transports: { [base.id]: http() },
  dataSuffix: DATA_SUFFIX,
  connectors: [
    coinbaseWallet({
      appName: "AiCoinTrack",
      preference: "all",
    }),
  ],
});

export function RootProvider({ children }: { children: ReactNode }) {
  const [queryClient] = useState(() => new QueryClient({
    defaultOptions: {
      queries: {
        staleTime: 0,
        gcTime: 5 * 60_000,
        retry: false,
        refetchOnMount: true,
        refetchOnWindowFocus: false,
      }
    }
  }));

  return (
    <WagmiProvider config={wagmiConfig}>
      <QueryClientProvider client={queryClient}>
        <ThemeWrapper>
          {children}
          <BottomNav />
        </ThemeWrapper>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
