// Lightweight local shim for Attribution.toDataSuffix
// Produces a hex-encoded data suffix from given builder codes.
export const Attribution = {
  toDataSuffix({ codes }: { codes: string[] }) {
    const payload = JSON.stringify({ codes });
    const encoder = typeof TextEncoder !== "undefined" ? new TextEncoder() : null;
    const bytes = encoder ? encoder.encode(payload) : Buffer.from(payload, "utf8");
    const hex = Array.from(bytes as Uint8Array)
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");
    return `0x${hex}`;
  },
};
