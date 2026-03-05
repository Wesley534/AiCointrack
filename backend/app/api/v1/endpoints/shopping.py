from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models.shopping import ShoppingList, ShoppingItem
from app.models.user import User
from app.schemas.shopping import ShoppingListCreate, ShoppingListResponse, ShoppingItemCreate, ShoppingItemResponse
from app.core.deps import get_current_user_jwt

router = APIRouter()

@router.post("/", response_model=ShoppingListResponse)
def create_shopping_list(list_in: ShoppingListCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user_jwt)):
    s_list = ShoppingList(**list_in.dict(), user_id=current_user.id)
    db.add(s_list)
    db.commit()
    db.refresh(s_list)
    return s_list

@router.get("/", response_model=List[ShoppingListResponse])
def get_shopping_lists(db: Session = Depends(get_db), current_user: User = Depends(get_current_user_jwt)):
    return db.query(ShoppingList).filter(ShoppingList.user_id == current_user.id).all()

@router.get("/{list_id}")
def get_shopping_list(list_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user_jwt)):
    s_list = db.query(ShoppingList).filter(ShoppingList.user_id == current_user.id, ShoppingList.id == list_id).first()
    if not s_list:
        raise HTTPException(status_code=404, detail="Shopping list not found")
    
    total = sum(item.price * item.qty for item in s_list.items)
    items_list = [{"name": item.name, "qty": item.qty, "price": item.price} for item in s_list.items]
    
    return {
        "title": s_list.name,
        "total": total,
        "remaining": s_list.budget - total,
        "items": items_list
    }

@router.post("/{list_id}/items", response_model=ShoppingItemResponse)
def add_shopping_item(list_id: int, item_in: ShoppingItemCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user_jwt)):
    s_list = db.query(ShoppingList).filter(ShoppingList.user_id == current_user.id, ShoppingList.id == list_id).first()
    if not s_list:
        raise HTTPException(status_code=404, detail="Shopping list not found")
        
    s_item = ShoppingItem(**item_in.dict(), list_id=list_id)
    db.add(s_item)
    db.commit()
    db.refresh(s_item)
    return s_item
