from pydantic import BaseModel
from typing import Optional

class BudgetBase(BaseModel):
    label: str
    planned: float
    actual: Optional[float] = 0.0
    tag: str
    kind: str
    month: str

class BudgetCreate(BudgetBase):
    pass

class BudgetResponse(BudgetBase):
    id: int
    user_id: int

    class Config:
        from_attributes = True
