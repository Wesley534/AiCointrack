"use client";

import { useEffect, useRef, useState, Suspense } from "react";
import { useConnect, useAccount, useSignMessage } from "wagmi";
import { useSearchParams } from "next/navigation";
import { SiweMessage } from "siwe";
import { getNonce } from "@/lib/api";

function AuthFlow() {
  const searchParams = useSearchParams();
  const redirectScheme = searchParams.get("redirect") || "aicointrack";
  
  const { connectors, connectAsync } = useConnect();
  const { isConnected, address, chainId } = useAccount();
  const { signMessageAsync } = useSignMessage();
  
  const [error, setError] = useState<string | null>(null);
  const [status, setStatus] = useState("Initializing...");
  const hasStarted = useRef(false);

  useEffect(() => {
    // Avoid double firing
    if (hasStarted.current) return;
    hasStarted.current = true;

    async function doAuth() {
      try {
        setStatus("Connecting to Coinbase Wallet...");
        // 1. Connect
        let currentAddress = address;
        let currentChainId = chainId;
        if (!isConnected || !address) {
          const coinbaseConnector = connectors.find((c) => c.id === "coinbaseWalletSDK");
          if (!coinbaseConnector) throw new Error("Coinbase Wallet connector not found");
          
          const result = await connectAsync({ connector: coinbaseConnector });
          currentAddress = result.accounts[0];
          currentChainId = result.chainId;
        }

        setStatus("Requesting signature...");
        
        // 2. Build SIWE message
        let nonce: string;
        try {
          nonce = await getNonce();
        } catch {
          nonce = Math.random().toString(36).slice(2) + Date.now().toString(36);
        }

        const messageObj = new SiweMessage({
          domain: typeof window !== "undefined" ? window.location.host : "aicointrack-nu.vercel.app",
          address: currentAddress as string,
          statement: "Sign in to AiCoinTrack",
          uri: typeof window !== "undefined" ? window.location.origin : "https://aicointrack-nu.vercel.app",
          version: "1",
          chainId: currentChainId || 8453,
          nonce,
        });

        const messageString = messageObj.prepareMessage();
        
        // 3. Sign message
        const signature = await signMessageAsync({ message: messageString });

        setStatus("Redirecting to app...");
        
        // 4. Redirect via deep link
        const deepLink = `${redirectScheme}://login?address=${currentAddress}&message=${encodeURIComponent(
          messageString
        )}&signature=${signature}`;
        
        window.location.replace(deepLink);
      } catch (err: unknown) {
        console.error("Flutter auth error:", err);
        const msg = err instanceof Error ? err.message : (err as { message?: string })?.message || "Authentication failed. Please try again.";
        if (msg.toLowerCase().includes("user rejected")) {
           setStatus("User rejected request. Please close the browser to return to the app.");
        } else {
           setError(msg);
        }
      }
    }

    doAuth();
  }, [connectAsync, connectors, isConnected, address, chainId, signMessageAsync, redirectScheme]);

  return (
    <div style={{
      display: "flex", alignItems: "center", justifyContent: "center",
      height: "100vh", flexDirection: "column", gap: 16,
      background: "#0A0A0A", padding: 32, textAlign: "center", color: "#FFF"
    }}>
      <div style={{
        width: 48, height: 48, borderRadius: 14,
        background: `linear-gradient(135deg, #0052FF, #0033B3)`,
        display: "flex", alignItems: "center", justifyContent: "center", fontSize: 24
      }}>
        💰
      </div>
      
      {error ? (
        <>
          <div style={{ color: "#EF4444", fontSize: 14, marginBottom: 16 }}>{error}</div>
          <button
            onClick={() => {
              setError(null);
              hasStarted.current = false;
              setStatus("Initializing...");
            }}
            style={{
              padding: "16px 32px", borderRadius: 14, border: "none",
              background: "#0052FF", color: "#fff", fontWeight: 700,
              fontSize: 16, fontFamily: "Syne, sans-serif", cursor: "pointer",
              width: "100%", maxWidth: 300
            }}
          >
            Retry Connection
          </button>
        </>
      ) : (
        <div style={{ fontSize: 16, color: "#888" }}>{status}</div>
      )}
    </div>
  );
}

export default function FlutterLoginPage() {
  return (
    <Suspense fallback={<div style={{ background: "#0A0A0A", height: "100vh", display: "flex", justifyContent: "center", alignItems: "center", color: "#FFF" }}>Loading...</div>}>
      <AuthFlow />
    </Suspense>
  );
}
