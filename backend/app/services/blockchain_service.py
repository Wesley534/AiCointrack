from typing import Optional


class BlockchainService:
    def __init__(self, base_rpc_url: str):
        self.base_rpc_url = base_rpc_url

    def get_transaction_status(self, tx_hash: str) -> Optional[str]:
        # Placeholder for on-chain lookup on Base L2.
        # Implement actual RPC call logic here.
        return None

