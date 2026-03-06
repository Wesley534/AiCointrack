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
  let signature: string = ""
  let finalMessage: string = messageString

  try {
    // Attempt Wagmi EOA standard signing first
    signature = await signMessageAsync({ message: messageString })
  } catch (err: unknown) {
    // Base App WebView / Farcaster SDK sometimes returns raw internal objects 
    // or rejects raw personal_sign for auth, requiring `sdk.actions.signIn`
    console.warn("Wagmi signMessageAsync failed, fallback to miniapp-sdk signIn:", err)

    // Lazy load to avoid SSR issues
    const sdk = (await import("@farcaster/miniapp-sdk")).default
    const result = await sdk.actions.signIn({ nonce })

    if (result && "signature" in result) {
      signature = result.signature
      finalMessage = result.message
    } else {
      throw new Error(`Auth Error: Native signIn failed or returned invalid object. Detail: ${JSON.stringify(result || err)}`)
    }
  }

  // Handle cases where the bridge returns an unparsed raw object directly to the signature variable
  if (typeof signature === "object" && signature !== null) {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    if ("signature" in signature) signature = (signature as any).signature
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    else if ("raw" in signature) signature = (signature as any).raw
    else {
      throw new Error(`Auth Error: Unexpected return signature object format: ${JSON.stringify(signature)}`)
    }
  }

  const response = await walletLogin(address, signature, finalMessage)
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
