from datetime import datetime
import enum

from sqlalchemy import Column, DateTime, Enum, Float, ForeignKey, Integer, String, Boolean

from app.db.base import Base


class SourceType(enum.Enum):
    MPESA = "mpesa"
    BANK = "bank"
    CASH = "cash"
    ONCHAIN = "onchain"


class TransactionType(enum.Enum):
    EXPENSE = "expense"  # Money going out
    INCOME = "income"    # Money coming in


class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    amount = Column(Float, nullable=False)  # Always positive
    currency = Column(String(10), default="KES")
    description = Column(String(255))
    category = Column(String(100))
    source = Column(Enum(SourceType), nullable=False)
    transaction_type = Column(Enum(TransactionType), default=TransactionType.EXPENSE)
    
    # For onchain transactions
    tx_hash = Column(String(255), nullable=True)
    recipient = Column(String(255), nullable=True)  # For onchain sends
    
    # For offchain transactions (MPESA, cash, etc.)
    reference_number = Column(String(255), nullable=True)  # MPESA ref, receipt number, etc.
    is_verified = Column(Boolean, default=False)  # Whether transaction is verified
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

