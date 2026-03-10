import type { ReactNode } from "react";
import type { Metadata } from "next";
import { LoginProvider } from "./loginProvider";

export const metadata: Metadata = {
    title: "Sign in · CoinTrack",
    description: "Connect your Base smart wallet to sign in to CoinTrack.",
};

/**
 * Nested layout for /login — rendered inside the root layout's <html>/<body>
 * BUT with its OWN LoginProvider (so we can set preference: "smartWalletOnly"
 * independently of the root RootProvider).
 *
 * The position:fixed overlay hides the BottomNav that RootProvider renders.
 */
export default function LoginLayout({ children }: { children: ReactNode }) {
    return (
        <div
            style={{
                position: "fixed",
                inset: 0,
                zIndex: 9999,
                background: "#0A0D12",
                overflowY: "auto",
            }}
        >
            <LoginProvider>{children}</LoginProvider>
        </div>
    );
}
