from typing import List, Optional
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from pydantic import BaseModel

from app.db.session import get_db
from app.models.transaction import Transaction
from app.models.user import User
from app.core.deps import get_current_user_jwt
from app.schemas.transaction import (
    TransactionCreate, 
    TransactionResponse, 
    OffchainTransactionCreate,
    OnchainTransactionCreate
)

router = APIRouter()


_VALID_SOURCES = {"mpesa", "bank", "cash", "onchain"}


def _normalize_source(s: str) -> str:
    v = (s or "cash").lower()
    if v not in _VALID_SOURCES:
        raise HTTPException(status_code=400, detail=f"Invalid source: {s}. Use mpesa, bank, cash, or onchain.")
    return v


def _normalize_transaction_type(s: str) -> str:
    v = (s or "expense").lower()
    return v if v in ("expense", "income") else "expense"


class AICategorizeRequest(BaseModel):
    description: str
    amount: float

# POST routes first (more specific)
@router.post("/offchain", response_model=TransactionResponse, status_code=status.HTTP_201_CREATED)
def create_offchain_transaction(
    tx_in: OffchainTransactionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_jwt)
):
    """
    Record an offchain transaction (MPESA, cash, bank transfer, etc.)
    These are recorded in the database for tracking purposes.
    """
    tx = Transaction(
        user_id=current_user.id,
        amount=tx_in.amount,
        description=tx_in.description,
        source=_normalize_source(tx_in.source),
        currency=tx_in.currency,
        category=tx_in.category,
        transaction_type=_normalize_transaction_type(tx_in.transaction_type),
        reference_number=tx_in.reference_number,
        is_verified=False,  # Offchain transactions may need verification
    )
    db.add(tx)
    db.commit()
    db.refresh(tx)
    return tx

@router.post("/onchain", response_model=TransactionResponse, status_code=status.HTTP_201_CREATED)
def create_onchain_transaction(
    tx_in: OnchainTransactionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_jwt)
):
    """
    Record an onchain transaction (blockchain-based).
    These are stored in the database for faster retrieval and historical tracking.
    """
    tx = Transaction(
        user_id=current_user.id,
        amount=tx_in.amount,
        description=tx_in.description or f"Sent to {tx_in.recipient or 'Unknown'}",
        source="onchain",
        currency=tx_in.currency,
        category=tx_in.category or "Transfer",
        transaction_type=_normalize_transaction_type(tx_in.transaction_type),
        tx_hash=tx_in.tx_hash,
        recipient=tx_in.recipient,
        is_verified=True,  # Onchain transactions are verified by blockchain
    )
    db.add(tx)
    db.commit()
    db.refresh(tx)
    return tx

@router.post("/ai-categorize")
def ai_categorize(req: AICategorizeRequest, current_user: User = Depends(get_current_user_jwt)):
    """Mock AI response for categorizing transactions"""
    category = "Food" if "grocery" in req.description.lower() else "Entertainment"
    return {"category": category, "confidence": 0.9}

@router.post("/", response_model=TransactionResponse, status_code=status.HTTP_201_CREATED)
def create_transaction(
    tx_in: TransactionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_jwt)
):
    """Create a generic transaction (legacy endpoint)"""
    tx = Transaction(
        user_id=current_user.id,
        amount=tx_in.amount,
        description=tx_in.description,
        source=_normalize_source(tx_in.source),
        currency=tx_in.currency,
        category=tx_in.category,
        transaction_type=_normalize_transaction_type(tx_in.transaction_type),
    )
    db.add(tx)
    db.commit()
    db.refresh(tx)
    return tx

# GET routes (less specific)
@router.get("/{tx_id}", response_model=TransactionResponse)
def get_transaction(
    tx_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_jwt)
):
    """Get a specific transaction"""
    tx = db.query(Transaction).filter(
        Transaction.user_id == current_user.id,
        Transaction.id == tx_id
    ).first()
    
    if not tx:
        raise HTTPException(status_code=404, detail="Transaction not found")
    
    return tx


class FingerprintUpdate(BaseModel):
    onchain_hash: str       # bytes32 fingerprint (0x + 64 hex)
    hash_store_tx: str      # Base tx hash of the storeHash() call


@router.patch("/{tx_id}/fingerprint", response_model=TransactionResponse)
def update_fingerprint(
    tx_id: int,
    data: FingerprintUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_jwt),
):
    """
    Called by the frontend after successfully storing a hash on HashStore.sol.
    Updates the transaction record with the on-chain fingerprint.
    """
    tx = db.query(Transaction).filter(
        Transaction.id == tx_id,
        Transaction.user_id == current_user.id,
    ).first()

    if not tx:
        raise HTTPException(status_code=404, detail="Transaction not found")

    # Validate hash format
    if not data.onchain_hash.startswith("0x") or len(data.onchain_hash) != 66:
        raise HTTPException(status_code=400, detail="Invalid onchain_hash format")
    if not data.hash_store_tx.startswith("0x") or len(data.hash_store_tx) != 66:
        raise HTTPException(status_code=400, detail="Invalid hash_store_tx format")

    tx.onchain_hash = data.onchain_hash
    tx.hash_store_tx = data.hash_store_tx
    tx.fingerprint_stored_at = datetime.utcnow()
    db.commit()
    db.refresh(tx)
    return tx

@router.get("/", response_model=List[TransactionResponse])
def list_transactions(
    source: Optional[str] = Query(None),
    transaction_type: Optional[str] = Query(None),
    limit: int = Query(50),
    offset: int = Query(0),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_jwt)
):
    """List transactions with optional filtering"""
    query = db.query(Transaction).filter(Transaction.user_id == current_user.id)
    
    if source:
        v = (source or "").lower()
        if v in _VALID_SOURCES:
            query = query.filter(Transaction.source == v)
    if transaction_type:
        v = _normalize_transaction_type(transaction_type)
        query = query.filter(Transaction.transaction_type == v)
    
    txs = query.order_by(Transaction.created_at.desc()).offset(offset).limit(limit).all()
    return txs
