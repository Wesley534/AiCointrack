"""
Privy service for creating embedded wallets for email/password users.
Uses Privy REST API: create user with email + ethereum wallet.
"""
import logging
from typing import Optional, Tuple

import httpx

from app.core.config import settings

logger = logging.getLogger(__name__)

PRIVY_API = "https://auth.privy.io/api/v1"


def create_user_with_wallet(email: str) -> Tuple[str, str]:
    """
    Create a Privy user with email + embedded Ethereum wallet.
    Returns (privy_user_id, wallet_address).
    Raises Exception on failure.
    """
    if not settings.PRIVY_APP_ID or not settings.PRIVY_APP_SECRET:
        raise ValueError("PRIVY_APP_ID and PRIVY_APP_SECRET must be set")

    payload = {
        "linked_accounts": [{"type": "email", "address": email}],
        "wallets": [{"chain_type": "ethereum"}],
    }

    auth = (settings.PRIVY_APP_ID, settings.PRIVY_APP_SECRET)
    headers = {
        "privy-app-id": settings.PRIVY_APP_ID,
        "Content-Type": "application/json",
    }

    with httpx.Client(timeout=15.0) as client:
        resp = client.post(
            f"{PRIVY_API}/users",
            json=payload,
            auth=auth,
            headers=headers,
        )
        resp.raise_for_status()
        data = resp.json()

    privy_id = data.get("id")
    if not privy_id:
        raise ValueError("Privy response missing user id")

    wallet_address = None
    for acc in data.get("linked_accounts", []):
        t = acc.get("type", "")
        addr = acc.get("address")
        if not addr or not isinstance(addr, str) or not addr.startswith("0x"):
            continue
        if t in ("ethereum_embedded_wallet", "embedded_wallet", "ethereum", "wallet"):
            wallet_address = addr
            break
        if t == "wallet" and acc.get("chain_type") == "ethereum":
            wallet_address = addr
            break
    if not wallet_address and data.get("linked_accounts"):
        for acc in data["linked_accounts"]:
            addr = acc.get("address")
            if addr and str(addr).startswith("0x") and len(str(addr)) == 42:
                wallet_address = str(addr)
                break

    if not wallet_address:
        raise ValueError("Privy user created but no wallet address in response")

    return privy_id, wallet_address.lower()
