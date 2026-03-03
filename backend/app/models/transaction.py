from datetime import datetime
import enum

from sqlalchemy import Column, DateTime, Enum, Float, ForeignKey, Integer, String

from app.db.base import Base


class SourceType(enum.Enum):
    MPESA = "mpesa"
    BANK = "bank"
    ONCHAIN = "onchain"


class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    amount = Column(Float, nullable=False)
    currency = Column(String(10), default="KES")
    description = Column(String(255))
    category = Column(String(100))
    source = Column(Enum(SourceType))
    tx_hash = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

