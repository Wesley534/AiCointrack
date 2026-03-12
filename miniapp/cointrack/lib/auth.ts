import { SiweMessage } from "siwe"
import { getNonce, walletLogin } from "./api"

export async function authenticateWallet(
  address: string,
  chainId: number,
  signMessageAsync: (args: { message: string }) => Promise<string>
): Promise<string> {
  console.log("[Auth] Starting wallet authentication", { address, chainId })
  
  // Prefetch nonce from backend (Base docs: avoid popup blockers, enables server-side nonce tracking)
  let nonce: string
  try {
    console.log("[Auth] Fetching nonce from backend...")
    nonce = await getNonce()
    console.log("[Auth] Nonce fetched successfully:", nonce.substring(0, 10) + "...")
  } catch (error) {
    console.error("[Auth] Failed to fetch nonce from backend:", error)
    nonce = Math.random().toString(36).slice(2) + Date.now().toString(36)
    console.log("[Auth] Using fallback nonce:", nonce.substring(0, 10) + "...")
  }

  const message = new SiweMessage({
    domain: typeof window !== "undefined" ? window.location.host : "aicointrack-nu.vercel.app",
    address,
    statement: "Sign in to Cointrack",
    uri: typeof window !== "undefined" ? window.location.origin : "https://aicointrack-nu.vercel.app",
    version: "1",
    chainId,
    nonce,
  })

  console.log("[Auth] SIWE message created successfully")
  const messageString = message.prepareMessage()
  console.log("[Auth] Message prepared for signing, length:", messageString.length)
  
  const signature = await signMessageAsync({ message: messageString })
  console.log("[Auth] Message signed successfully, signature length:", signature.length)

  console.log("[Auth] Sending wallet login request to backend...")
  const response = await walletLogin(address, signature, messageString)
  console.log("[Auth] Wallet login response received:", response.status || response.data?.status)
  
  const jwt = response.data?.jwt ?? response.data?.accessToken
  if (!jwt) {
    console.error("[Auth] No JWT in response. Response data:", response.data)
    throw new Error(response.data?.detail ?? "No token in response")
  }

  console.log("[Auth] JWT token extracted successfully")
  if (typeof window !== "undefined") {
    localStorage.setItem("pocketpal_jwt", jwt)
    console.log("[Auth] JWT stored in localStorage")
  }
  
  console.log("[Auth] Wallet authentication completed successfully")
  return jwt
}
