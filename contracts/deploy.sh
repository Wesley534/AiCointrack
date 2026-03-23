#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)/.."
# Directory containing this script (contracts/)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Contract source file under contracts/src
CONTRACT_SRC="$SCRIPT_DIR/src/HashStore.sol"
# Path for frontend deployment info (repo_root/miniapp/...)
OUT_PATH="$ROOT_DIR/miniapp/cointrack/lib/deployment.json"

ENV_FILE="$ROOT_DIR/backend/.env"
# If a backend .env exists, source it so variables like DEPLOYER_PRIVATE_KEY are available.
if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  set -a
  # Use a subshell-safe source; ignore if file contains non-shell-friendly constructs
  # (the project's .env is plain KEY=VALUE so this should be fine)
  . "$ENV_FILE"
  set +a
fi

if [ -z "${DEPLOYER_PRIVATE_KEY:-}" ]; then
  echo "ERROR: DEPLOYER_PRIVATE_KEY not set in environment (backend/.env)."
  echo "Export it or add to backend/.env before running this script."
  exit 1
fi

if [ -z "${BASE_SEPOLIA_RPC:-}" ]; then
  echo "ERROR: BASE_SEPOLIA_RPC not set in environment."
  echo "Set BASE_SEPOLIA_RPC (e.g. https://sepolia.base.org) and retry."
  exit 1
fi

echo "Building contracts with forge..."
forge build

echo "Deploying HashStore to Base Sepolia via forge..."

# Build the forge create command into an array (safe quoting)
CMD=(forge create "${CONTRACT_SRC}:HashStore" --rpc-url "$BASE_SEPOLIA_RPC" --private-key "$DEPLOYER_PRIVATE_KEY")
echo "Running: ${CMD[*]}"

# Run the command and tee output to a temp file for debugging
OUTFILE=$(mktemp /tmp/forge_deploy.XXXXXX)
"${CMD[@]}" 2>&1 | tee "$OUTFILE"
OUTPUT=$(cat "$OUTFILE")

# Parse the last 0x...40 address from output
ADDR=$(grep -Eo '0x[a-fA-F0-9]{40}' "$OUTFILE" | tail -n1 || true)

if [ -z "$ADDR" ]; then
  echo "\nFailed to parse deployed address from forge output. Full output below:\n"
  sed -n '1,200p' "$OUTFILE"
  echo "\nIf the command failed, try running the printed command manually to see errors."
  rm -f "$OUTFILE"
  exit 1
fi

echo "Deployed HashStore at: $ADDR"
rm -f "$OUTFILE"

DEPLOYMENT_JSON=$(cat <<JSON
{
  "network": "baseSepolia",
  "chainId": 84532,
  "address": "$ADDR",
  "deployedAt": "$(date --utc +%Y-%m-%dT%H:%M:%SZ)",
  "deployer": ""
}
JSON
)

mkdir -p "$(dirname "$OUT_PATH")"
echo "$DEPLOYMENT_JSON" > "$OUT_PATH"
echo "Wrote deployment info to: $OUT_PATH"

echo "Done."
