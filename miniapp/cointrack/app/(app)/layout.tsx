import type { ReactNode } from "react";
import { SafeArea } from "@coinbase/onchainkit/minikit";
import { RootProvider } from "@/app/rootProvider";

export default function AppLayout({ children }: { children: ReactNode }) {
  return (
    <RootProvider>
      <SafeArea>
        <main style={{ paddingBottom: 72, maxWidth: 390, margin: "0 auto" }}>
          {children}
        </main>
      </SafeArea>
    </RootProvider>
  );
}
