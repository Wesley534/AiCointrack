from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models.savings import SavingsGoal
from app.models.user import User
from app.schemas.savings import SavingsGoalCreate, SavingsGoalResponse
from app.core.deps import get_current_user_jwt
from pydantic import BaseModel

router = APIRouter()

class ContributeRequest(BaseModel):
    amount_usdc: float
    tx_hash: str

@router.post("", response_model=SavingsGoalResponse)
def create_goal(goal_in: SavingsGoalCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user_jwt)):
    goal = SavingsGoal(**goal_in.dict(), user_id=current_user.id)
    db.add(goal)
    db.commit()
    db.refresh(goal)
    return goal

@router.get("", response_model=List[SavingsGoalResponse])
def get_goals(db: Session = Depends(get_db), current_user: User = Depends(get_current_user_jwt)):
    return db.query(SavingsGoal).filter(SavingsGoal.user_id == current_user.id).all()

@router.post("/{goal_id}/contribute")
def contribute_goal(goal_id: int, req: ContributeRequest, db: Session = Depends(get_db), current_user: User = Depends(get_current_user_jwt)):
    goal = db.query(SavingsGoal).filter(SavingsGoal.user_id == current_user.id, SavingsGoal.id == goal_id).first()
    if not goal:
        raise HTTPException(status_code=404, detail="Goal not found")
        
    goal.saved += req.amount_usdc
    db.commit()
    return {"message": "Contribution successful", "goal": {"id": goal.id, "saved": goal.saved}}
