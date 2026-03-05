from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models.budget import Budget
from app.models.user import User
from app.schemas.budget import BudgetCreate, BudgetResponse
from app.core.deps import get_current_user_jwt
from pydantic import BaseModel

router = APIRouter()

class BudgetUpdate(BaseModel):
    label: str = None
    planned: float = None
    actual: float = None
    tag: str = None
    kind: str = None
    month: str = None

@router.post("/", response_model=BudgetResponse)
def create_budget(budget_in: BudgetCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user_jwt)):
    budget = Budget(**budget_in.dict(), user_id=current_user.id)
    db.add(budget)
    db.commit()
    db.refresh(budget)
    return budget

@router.get("/", response_model=List[BudgetResponse])
def get_budgets(db: Session = Depends(get_db), current_user: User = Depends(get_current_user_jwt)):
    return db.query(Budget).filter(Budget.user_id == current_user.id).all()

@router.get("/current", response_model=List[BudgetResponse])
def get_current_budget(db: Session = Depends(get_db), current_user: User = Depends(get_current_user_jwt)):
    # Simply returning budgets. Real implementation would filter by the current month.
    return db.query(Budget).filter(Budget.user_id == current_user.id).all()

@router.put("/{budget_id}", response_model=BudgetResponse)
def update_budget(budget_id: int, budget_in: BudgetUpdate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user_jwt)):
    budget = db.query(Budget).filter(Budget.id == budget_id, Budget.user_id == current_user.id).first()
    if not budget:
        raise HTTPException(status_code=404, detail="Budget not found")
    
    update_data = budget_in.dict(exclude_unset=True)
    for field, value in update_data.items():
        if value is not None:
            setattr(budget, field, value)
    
    db.add(budget)
    db.commit()
    db.refresh(budget)
    return budget

@router.get("/category/{category_label}")
def get_category_detail(category_label: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user_jwt)):
    budget = db.query(Budget).filter(
        Budget.user_id == current_user.id,
        Budget.label == category_label
    ).first()
    if not budget:
        return {"category": category_label, "planned": 0, "actual": 0, "overBy": 0}
    
    return {
        "category": budget.label,
        "planned": budget.planned,
        "actual": budget.actual,
        "overBy": max(0, budget.actual - budget.planned)
    }
