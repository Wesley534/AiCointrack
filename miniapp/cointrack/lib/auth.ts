import { SiweMessage } from "siwe"
import { getNonce, walletLogin } from "./api"

export async function authenticateWallet(
  address: string,
  chainId: number,
  signMessageAsync: (args: { message: string }) => Promise<string>
): Promise<string> {
  // Prefetch nonce from backend (Base docs: avoid popup blockers, enables server-side nonce tracking)
  let nonce: string
  try {
    nonce = await getNonce()
  } catch {
    nonce = Math.random().toString(36).slice(2) + Date.now().toString(36)
  }

  const message = new SiweMessage({
    domain: typeof window !== "undefined" ? window.location.host : "cointrack.xyz",
    address,
    statement: "Sign in to Cointrack",
    uri: typeof window !== "undefined" ? window.location.origin : "https://cointrack.xyz",
    version: "1",
    chainId,
    nonce,
  })

  const messageString = message.prepareMessage()
  const signature = await signMessageAsync({ message: messageString })

  const response = await walletLogin(address, signature, messageString)
  const jwt = response.data?.jwt ?? response.data?.accessToken
  if (!jwt) {
    throw new Error(response.data?.detail ?? "No token in response")
  }

  if (typeof window !== "undefined") {
    try {
      localStorage.setItem("pocketpal_jwt", jwt)
    } catch (e) {
      console.warn("localStorage setItem denied:", e)
    }
  }
  return jwt
}
