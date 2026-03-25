#!/usr/bin/env node
/**
 * Verify SIWE signature using Viem (handles ERC-6492 for Base Account / smart wallets).
 * Usage: node verify_siwe.mjs <address> <message> <signature>
 * Exit 0 if valid, 1 if invalid.
 */
import { createPublicClient, http } from "viem";
import { baseSepolia } from "viem/chains";

const [address, message, signature] = process.argv.slice(2);
if (!address || !message || !signature) {
  process.exit(1);
}

const client = createPublicClient({ chain: baseSepolia, transport: http() });

try {
  const valid = await client.verifyMessage({ address, message, signature });
  process.exit(valid ? 0 : 1);
} catch {
  process.exit(1);
}
