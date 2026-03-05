from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class TransactionBase(BaseModel):
    amount: float
    description: str
    source: str  # mpesa, bank, cash, onchain
    currency: str = "KES"
    category: Optional[str] = None
    transaction_type: str = "expense"  # expense or income


class TransactionCreate(TransactionBase):
    pass


class OffchainTransactionCreate(BaseModel):
    """For MPESA, cash, and bank transactions"""
    amount: float
    description: str
    source: str  # mpesa, bank, cash
    category: Optional[str] = None
    transaction_type: str = "expense"
    reference_number: Optional[str] = None  # MPESA ref, receipt number, etc.
    currency: str = "KES"


class OnchainTransactionCreate(BaseModel):
    """For blockchain transactions"""
    amount: float
    description: Optional[str] = None
    tx_hash: str
    recipient: Optional[str] = None
    category: Optional[str] = None
    transaction_type: str = "expense"
    currency: str = "USDC"


class TransactionResponse(TransactionBase):
    id: int
    tx_hash: Optional[str] = None
    recipient: Optional[str] = None
    reference_number: Optional[str] = None
    is_verified: bool = False
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

