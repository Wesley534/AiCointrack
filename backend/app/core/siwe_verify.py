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
        return result.returncode == 0
    except Exception as e:
        logger.warning(f"Node SIWE verification failed: {e}")
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
        siwe_msg.verify(sig)
        if siwe_msg.address.lower() != addr.lower():
            raise ValueError(f"Address mismatch: recovered {siwe_msg.address}, claimed {addr}")
        return True
    except Exception as e:
        logger.info(f"Python SIWE verify failed ({e}), trying Node/viem fallback for ERC-6492")
        if _verify_via_node(addr, message, sig):
            return True
        logger.warning(f"SIWE verification failed: {e}")
        raise ValueError(f"Invalid signature: {e}")
