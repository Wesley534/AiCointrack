from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel

from app.db.session import get_db
from app.models.transaction import Transaction
from app.models.user import User
from app.core.deps import get_current_user_jwt
from app.schemas.transaction import TransactionCreate, TransactionResponse

router = APIRouter()

class RecordTxRequest(BaseModel):
    tx_hash: str
    amount_usdc: float
    recipient: str = None
    note: str = None
    category: str = None

class AICategorizeRequest(BaseModel):
    description: str
    amount: float

@router.post("/", response_model=TransactionResponse, status_code=status.HTTP_201_CREATED)
def create_transaction(
    tx_in: TransactionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_jwt)
):
    tx = Transaction(
        user_id=current_user.id,
        amount=tx_in.amount,
        description=tx_in.description,
        source=tx_in.source,
        currency=tx_in.currency,
    )
    db.add(tx)
    db.commit()
    db.refresh(tx)
    return tx

@router.get("/", response_model=List[TransactionResponse])
def list_transactions(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_jwt)
):
    txs = db.query(Transaction).filter(Transaction.user_id == current_user.id).all()
    return txs

@router.post("/record")
def record_onchain_tx(req: RecordTxRequest, db: Session = Depends(get_db), current_user: User = Depends(get_current_user_jwt)):
    # Here you'd interact directly with the DB, tracking an on-chain action
    tx = Transaction(
        user_id=current_user.id,
        amount=-req.amount_usdc,
        description=req.note or f"Sent to {req.recipient or 'Unknown'}",
        source="onchain",
        currency="USDC",
        tx_hash=req.tx_hash,
        category=req.category or "Transfer"
    )
    db.add(tx)
    db.commit()
    db.refresh(tx)
    return {"message": "Transaction recorded", "id": tx.id}

@router.post("/ai-categorize")
def ai_categorize(req: AICategorizeRequest, current_user: User = Depends(get_current_user_jwt)):
    # Mock AI response - in a real scenario you would call an LLM directly
    category = "Food" if "grocery" in req.description.lower() else "Entertainment"
    return {"category": category, "confidence": 0.9}
