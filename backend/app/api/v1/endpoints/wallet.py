from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models.wallet_balance import WalletBalance
from app.models.user import User
from app.core.deps import get_current_user_jwt
from pydantic import BaseModel

router = APIRouter()

class WithdrawRequest(BaseModel):
    amount_usdc: float
    destination_type: str
    destination_id: str

@router.get("/address")
def get_address(current_user: User = Depends(get_current_user_jwt)):
    return {"address": current_user.wallet_address}

@router.get("/destinations")
def get_destinations(current_user: User = Depends(get_current_user_jwt)):
    # Mocking for now as it integrates directly with DB/Services eventually
    return [
        {"id": "mpesa-1", "type": "mpesa", "label": "M-PESA (2547***)"},
        {"id": "bank-1", "type": "bank", "label": "Equity Bank (*1234)"}
    ]

@router.post("/withdraw/initiate")
def withdraw_initiate(req: WithdrawRequest, db: Session = Depends(get_db), current_user: User = Depends(get_current_user_jwt)):
    # Deduct balance or call external services here
    return {"status": "processing", "withdraw_id": "WD-1234", "amount": req.amount_usdc}

@router.get("/withdraw/{withdraw_id}/status")
def withdraw_status(withdraw_id: str, current_user: User = Depends(get_current_user_jwt)):
    return {"id": withdraw_id, "status": "completed"}

@router.get("/balance")
def get_balance(db: Session = Depends(get_db), current_user: User = Depends(get_current_user_jwt)):
    wb = db.query(WalletBalance).filter(WalletBalance.user_id == current_user.id).first()
    if not wb:
        return {"currency": "USDC", "balance": 0.0}
    return {"currency": wb.currency, "balance": wb.balance}
