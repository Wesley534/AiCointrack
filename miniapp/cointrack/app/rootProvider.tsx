"use client";
import { ReactNode, useState } from "react";
import { base } from "wagmi/chains";
import { WagmiProvider, createConfig, http } from "wagmi";
import { injected } from "wagmi/connectors";
import { farcasterMiniApp } from "@farcaster/miniapp-wagmi-connector";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { OnchainKitProvider } from "@coinbase/onchainkit";
import BottomNav from "@/components/layout/BottomNav";
import ThemeWrapper from "@/components/ThemeWrapper";
import "@coinbase/onchainkit/styles.css";

const wagmiConfig = createConfig({
  chains: [base],
  connectors: [farcasterMiniApp(), injected()],
  transports: { [base.id]: http() }
});

export function RootProvider({ children }: { children: ReactNode }) {
  const [queryClient] = useState(() => new QueryClient({
    defaultOptions: {
      queries: {
        // Global staleTime: 0 means data is always stale unless hooks override
        // This ensures initial fetches always fire; hooks set staleTime: 30_000
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
        <OnchainKitProvider
          apiKey={process.env.NEXT_PUBLIC_ONCHAINKIT_API_KEY}
          chain={base}
          config={{
            appearance: {
              mode: "auto",
            },
            wallet: {
              display: "modal",
              preference: "all",
            },
          }}
          miniKit={{
            enabled: true,
            autoConnect: true,
            notificationProxyUrl: undefined,
          }}
        >
          <ThemeWrapper>
            {children}
            <BottomNav />
          </ThemeWrapper>
        </OnchainKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}