from typing import Optional
from web3 import Web3
import logging

logger = logging.getLogger(__name__)

class BlockchainService:
    def __init__(self, base_rpc_url: str):
        self.base_rpc_url = base_rpc_url
        self.w3 = Web3(Web3.HTTPProvider(self.base_rpc_url))

    def get_transaction_status(self, tx_hash: str) -> Optional[str]:
        try:
            tx_receipt = self.w3.eth.get_transaction_receipt(tx_hash)
            if tx_receipt:
                return "completed" if tx_receipt.status == 1 else "failed"
            return None
        except Exception as e:
            logger.error(f"Error fetching tx status: {e}")
            return None

    def verify_transaction(self, tx_hash: str, expected_recipient: str, expected_amount_usdc: float) -> bool:
        """
        Verify the onchain transaction.
        Checks that it was successful (status == 1) and that the token/amount transferred matches.
        """
        try:
            tx_receipt = self.w3.eth.get_transaction_receipt(tx_hash)
            if not tx_receipt or tx_receipt.status != 1:
                return False

            tx = self.w3.eth.get_transaction(tx_hash)
            input_data = tx.input.hex() if isinstance(tx.input, bytes) else tx.input
            
            # Simple ERC20 transfer signature verification
            # transfer(address,uint256) -> 0xa9059cbb
            if not input_data.startswith("0xa9059cbb") and not input_data.startswith("a9059cbb"):
                return False
                
            stripped_input = input_data.replace("0x", "")
            
            recipient = "0x" + stripped_input[8:72][-40:]
            if recipient.lower() != expected_recipient.lower():
                return False
                
            amount_hex = stripped_input[72:136]
            amount = int(amount_hex, 16)
            
            # USDC has 6 decimals
            expected_amount_wei = int(expected_amount_usdc * (10 ** 6))
            if amount != expected_amount_wei:
                return False
                
            return True
        except Exception as e:
            logger.error(f"Failed to verify transaction {tx_hash}: {e}")
            return False

