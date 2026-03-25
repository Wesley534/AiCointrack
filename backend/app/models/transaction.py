from datetime import datetime
import enum

from sqlalchemy import Column, DateTime, Enum, Float, ForeignKey, Integer, String, Boolean

from app.db.base import Base


class SourceType(enum.Enum):
    """Values are lowercase for VARCHAR storage and backward compatibility with existing rows."""
    MPESA = "mpesa"
    BANK = "bank"
    CASH = "cash"
    ONCHAIN = "onchain"


class TransactionType(enum.Enum):
    """Values match DB enum 'transactiontype' (lowercase)."""
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
    source = Column(String(20), nullable=False)  # mpesa, bank, cash, onchain — avoid Enum/DB mismatch
    transaction_type = Column(String(20), default="expense")  # expense, income
    
    # For onchain transactions
    tx_hash = Column(String(255), nullable=True)
    recipient = Column(String(255), nullable=True)  # For onchain sends
    onchain_hash = Column(String(66), nullable=True, index=True)
    hash_store_tx = Column(String(66), nullable=True)
    fingerprint_stored_at = Column(DateTime, nullable=True)
    
    # For offchain transactions (MPESA, cash, etc.)
    reference_number = Column(String(255), nullable=True)  # MPESA ref, receipt number, etc.
    is_verified = Column(Boolean, default=False)  # Whether transaction is verified
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

