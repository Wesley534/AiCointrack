from pydantic import BaseModel
from typing import Optional

class WalletBalanceBase(BaseModel):
    currency: str
    balance: float

class WalletBalanceCreate(WalletBalanceBase):
    pass

class WalletBalanceResponse(WalletBalanceBase):
    id: int
    user_id: int

    class Config:
        from_attributes = True
