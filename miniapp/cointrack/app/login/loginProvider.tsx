"use client";
import { ReactNode, useState } from "react";
import { base } from "wagmi/chains";
import { WagmiProvider, createConfig, http } from "wagmi";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { OnchainKitProvider } from "@coinbase/onchainkit";
import "@coinbase/onchainkit/styles.css";

const wagmiConfig = createConfig({
    chains: [base],
    transports: { [base.id]: http() },
});

/**
 * Minimal provider for the /login route.
 * Key difference from RootProvider:
 *   - preference: "smartWalletOnly" — forces Base smart wallet / passkey flow
 *   - No BottomNav, no ThemeWrapper, no SafeArea
 */
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
                >
                    {children}
                </OnchainKitProvider>
            </QueryClientProvider>
        </WagmiProvider>
    );
}
