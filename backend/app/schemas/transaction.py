from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class TransactionBase(BaseModel):
    amount: float
    description: str
    source: str
    currency: str = "KES"


class TransactionCreate(TransactionBase):
    pass


class TransactionResponse(TransactionBase):
    id: int
    category: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True

