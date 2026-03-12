import type { ReactNode } from "react";
import type { Metadata } from "next";
import { LoginProvider } from "./loginProvider";

export const metadata: Metadata = {
  title: "Sign in · AiCoinTrack",
  description: "Connect your Base smart wallet to sign in to AiCoinTrack.",
};

export default function LoginLayout({ children }: { children: ReactNode }) {
  return (
    <LoginProvider>
      {children}
    </LoginProvider>
  );
}

