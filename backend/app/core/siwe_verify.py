"""
SIWE (Sign-In with Ethereum) verification for wallet authentication.
"""
import logging

from siwe import SiweMessage

logger = logging.getLogger(__name__)


def verify_siwe_signature(address: str, message: str, signature: str) -> bool:
    """
    Verify a SIWE signature.
    
    Args:
        address: The claimed signer address (0x-prefixed)
        message: The full SIWE message string that was signed
        signature: Hex-encoded signature (with or without 0x prefix)
        
    Returns:
        True if valid
        
    Raises:
        ValueError: If verification fails
    """
    try:
        siwe_msg = SiweMessage.from_message(message=message)
        siwe_msg.verify(signature)
        if siwe_msg.address.lower() != address.lower():
            raise ValueError(f"Address mismatch: recovered {siwe_msg.address}, claimed {address}")
        return True
    except Exception as e:
        logger.warning(f"SIWE verification failed: {e}")
        raise ValueError(f"Invalid signature: {e}")
