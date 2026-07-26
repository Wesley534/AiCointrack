from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models.shopping import ShoppingList, ShoppingItem
from app.models.user import User
from app.schemas.shopping import ShoppingListCreate, ShoppingListResponse, ShoppingItemCreate, ShoppingItemUpdate, ShoppingItemResponse
from app.core.deps import get_current_user_jwt

router = APIRouter()

import logging
logger = logging.getLogger(__name__)

@router.post("", response_model=ShoppingListResponse)
def create_shopping_list(list_in: ShoppingListCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user_jwt)):
    logger.info(f"===> HIT create_shopping_list POST. Data: {list_in.dict()}, User: {current_user.id}")
    try:
        s_list = ShoppingList(**list_in.dict(), user_id=current_user.id)
        db.add(s_list)
        db.commit()
        db.refresh(s_list)
        logger.info(f"===> Successfully created ShoppingList id={s_list.id}")
        return s_list
    except Exception as e:
        logger.error(f"===> Error creating shopping list: {str(e)}", exc_info=True)
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.get("", response_model=List[ShoppingListResponse])
def get_shopping_lists(db: Session = Depends(get_db), current_user: User = Depends(get_current_user_jwt)):
    return db.query(ShoppingList).filter(ShoppingList.user_id == current_user.id).all()

@router.get("/{list_id}")
def get_shopping_list(list_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user_jwt)):
    s_list = db.query(ShoppingList).filter(ShoppingList.user_id == current_user.id, ShoppingList.id == list_id).first()
    if not s_list:
        raise HTTPException(status_code=404, detail="Shopping list not found")
    
    total = sum(item.price * item.qty for item in s_list.items)
    items_list = [{"id": item.id, "name": item.name, "qty": item.qty, "price": item.price} for item in s_list.items]
    
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


@router.put("/{list_id}/items/{item_id}", response_model=ShoppingItemResponse)
def update_shopping_item(list_id: int, item_id: int, item_in: ShoppingItemUpdate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user_jwt)):
    s_list = db.query(ShoppingList).filter(ShoppingList.user_id == current_user.id, ShoppingList.id == list_id).first()
    if not s_list:
        raise HTTPException(status_code=404, detail="Shopping list not found")
    
    s_item = db.query(ShoppingItem).filter(ShoppingItem.id == item_id, ShoppingItem.list_id == list_id).first()
    if not s_item:
        raise HTTPException(status_code=404, detail="Shopping item not found")
    
    update_data = item_in.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(s_item, key, value)
    
    db.commit()
    db.refresh(s_item)
    return s_item
