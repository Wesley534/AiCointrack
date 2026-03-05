from pydantic import BaseModel
from typing import Optional

class SavingsGoalBase(BaseModel):
    name: str
    saved: float
    target: float
    monthly: float

class SavingsGoalCreate(SavingsGoalBase):
    pass

class SavingsGoalResponse(SavingsGoalBase):
    id: int
    user_id: int

    class Config:
        from_attributes = True
