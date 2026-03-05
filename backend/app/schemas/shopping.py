from pydantic import BaseModel
from typing import List, Optional

class ShoppingItemBase(BaseModel):
    name: str
    qty: int
    price: float

class ShoppingItemCreate(ShoppingItemBase):
    pass

class ShoppingItemResponse(ShoppingItemBase):
    id: int
    list_id: int

    class Config:
        from_attributes = True

class ShoppingListBase(BaseModel):
    name: str
    budget: float
    status: Optional[str] = "green"

class ShoppingListCreate(ShoppingListBase):
    pass

class ShoppingListResponse(ShoppingListBase):
    id: int
    user_id: int
    items: List[ShoppingItemResponse] = []

    class Config:
        from_attributes = True
