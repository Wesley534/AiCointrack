from sqlalchemy import Column, Integer, String, Float, ForeignKey
from app.db.base import Base

class WalletBalance(Base):
    __tablename__ = "wallet_balances"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    currency = Column(String(10), default="USDC")
    balance = Column(Float, default=0.0)
