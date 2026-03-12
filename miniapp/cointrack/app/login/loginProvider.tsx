"use client";
import { ReactNode, useState } from "react";
import { base } from "wagmi/chains";
import { WagmiProvider, createConfig, http } from "wagmi";
import { coinbaseWallet } from "wagmi/connectors";
import { farcasterMiniApp } from "@farcaster/miniapp-wagmi-connector";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { OnchainKitProvider } from "@coinbase/onchainkit";
import "@coinbase/onchainkit/styles.css";

const wagmiConfig = createConfig({
  chains: [base],
  transports: { [base.id]: http() },
  connectors: [
    // Required for Base/Farcaster Mini App host wallet.
    farcasterMiniApp(),
    // Fallback for normal browser usage outside Mini App hosts.
    coinbaseWallet({
      appName: "CoinTrack",
      preference: "smartWalletOnly", // ← Coinbase only, no Phantom
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
        <OnchainKitProvider
          apiKey={process.env.NEXT_PUBLIC_ONCHAINKIT_API_KEY}
          chain={base}
          config={{
            wallet: {
              display: "modal",
              preference: "smartWalletOnly",
            },
          }}
          miniKit={{
            enabled: true,
            autoConnect: true,
            notificationProxyUrl: undefined,
          }}
        >
          {children}
        </OnchainKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
