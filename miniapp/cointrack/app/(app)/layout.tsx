import type { ReactNode } from "react";
import { RootProvider } from "@/app/rootProvider";

export default function AppLayout({ children }: { children: ReactNode }) {
  return (
    <RootProvider>
      <main style={{ paddingBottom: 72, maxWidth: 390, margin: "0 auto", minHeight: "100vh" }}>
        {children}
      </main>
    </RootProvider>
  );
}
