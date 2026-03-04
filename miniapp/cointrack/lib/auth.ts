import { SiweMessage } from "siwe"
import { walletLogin } from "./api"

export async function authenticateWallet(
  address: string,
  chainId: number,
  signMessageAsync: (args: { message: string }) => Promise<string>
) {
  // Build the SIWE message
  const message = new SiweMessage({
    domain: window.location.host,
    address,
    statement: "Sign in to Cointrack",
    uri: window.location.origin,
    version: "1",
    chainId,
    nonce: Math.random().toString(36).slice(2)
  })

  const messageString = message.prepareMessage()

  // User signs it with their Base wallet
  const signature = await signMessageAsync({ message: messageString })

  // Send to backend for verification
  const response = await walletLogin(address, signature, messageString)
  const { jwt } = response.data

  // Store JWT for API calls
  localStorage.setItem("pocketpal_jwt", jwt)

  return jwt
}
