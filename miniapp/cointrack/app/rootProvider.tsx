"use client";
import { ReactNode, useState } from "react";
import { base } from "wagmi/chains";
import { WagmiProvider, createConfig, http } from "wagmi";
import { coinbaseWallet } from "wagmi/connectors";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import BottomNav from "@/components/layout/BottomNav";
import ThemeWrapper from "@/components/ThemeWrapper";

const wagmiConfig = createConfig({
  chains: [base],
  transports: { [base.id]: http() },
  connectors: [
    coinbaseWallet({
      appName: "CoinTrack",
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
