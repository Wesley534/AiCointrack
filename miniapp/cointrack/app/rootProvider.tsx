"use client";
import { ReactNode, useState } from "react";
import { base } from "wagmi/chains";
import { WagmiProvider, createConfig, http } from "wagmi";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { OnchainKitProvider } from "@coinbase/onchainkit";
import BottomNav from "@/components/layout/BottomNav";
import ThemeWrapper from "@/components/ThemeWrapper";
import "@coinbase/onchainkit/styles.css";

const wagmiConfig = createConfig({
  chains: [base],
  transports: { [base.id]: http() }
});

export function RootProvider({ children }: { children: ReactNode }) {
  const [queryClient] = useState(() => new QueryClient({
    defaultOptions: {
      queries: {
        // Don't override per-hook staleTime — set a reasonable default
        // so tabs don't unnecessarily refetch every single time
        staleTime: 60000,
        gcTime: 5 * 60000,
        // Don't retry on auth failures — this causes the delayed crash
        retry: false,
        // Always refetch when window regains focus or component mounts
        refetchOnMount: true,
        refetchOnWindowFocus: true,
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