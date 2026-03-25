"""
SIWE (Sign-In with Ethereum) verification for wallet authentication.

Supports EOA signatures via Python siwe. For Base Account (ERC-6492) smart wallets,
set VERIFY_SIWE_SCRIPT to path to scripts/verify_siwe.mjs and ensure Node + viem
are installed (cd backend/scripts && npm install).
"""
import logging
import os
import subprocess
from pathlib import Path

from siwe import SiweMessage

logger = logging.getLogger(__name__)

_SCRIPT_PATH = Path(__file__).resolve().parent.parent.parent / "scripts" / "verify_siwe.mjs"
EXPECTED_CHAIN_ID = 84532
EXPECTED_DOMAIN = "app.aicointrack.xyz"


def _verify_via_node(address: str, message: str, signature: str) -> bool:
    """Fallback: verify using Node/viem (handles ERC-6492)."""
    script = os.environ.get("VERIFY_SIWE_SCRIPT") or _SCRIPT_PATH
    if not script or not Path(script).exists():
        return False
    try:
        result = subprocess.run(
            ["node", str(script), address, message, signature],
            capture_output=True,
            timeout=10,
            cwd=Path(script).parent,
        )
        if result.returncode == 0:
            return True
        # Log stdout/stderr for debugging when Node verification fails
        try:
            stdout = result.stdout.decode('utf-8', errors='replace')
            stderr = result.stderr.decode('utf-8', errors='replace')
        except Exception:
            stdout = str(result.stdout)
            stderr = str(result.stderr)
        logger.warning(
            "Node SIWE verification returned non-zero exit. rc=%s stdout=%s stderr=%s",
            result.returncode,
            stdout,
            stderr,
        )
        return False
    except Exception as e:
        logger.warning("Node SIWE verification failed", exc_info=True)
        return False


def verify_siwe_signature(address: str, message: str, signature: str) -> bool:
    """
    Verify a SIWE signature (EOA or Base Account / ERC-6492).

    Tries Python siwe first; if it fails, tries Node/viem script for ERC-6492 support.
    """
    # Normalize address
    addr = address if address.startswith("0x") else "0x" + address
    sig = signature if signature.startswith("0x") else "0x" + signature

    try:
        siwe_msg = SiweMessage.from_message(message=message)

        # Enforce app domain + Base Sepolia before signature verification.
        if siwe_msg.domain != EXPECTED_DOMAIN:
            raise ValueError(f"Invalid domain: {siwe_msg.domain}")

        if int(siwe_msg.chain_id) != EXPECTED_CHAIN_ID:
            raise Exception("Invalid chain")

        siwe_msg.verify(sig)
        if siwe_msg.address.lower() != addr.lower():
            raise ValueError(f"Address mismatch: recovered {siwe_msg.address}, claimed {addr}")
        return True
    except Exception as e:
        logger.info("Python SIWE verify failed (%s), trying Node/viem fallback for ERC-6492", repr(e))
        if _verify_via_node(addr, message, sig):
            return True
        logger.warning("SIWE verification failed", exc_info=True)
        raise ValueError(f"Invalid signature: {e}")
