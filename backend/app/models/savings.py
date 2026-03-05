from sqlalchemy import Column, Integer, String, Float, ForeignKey
from app.db.base import Base

class SavingsGoal(Base):
    __tablename__ = "savings_goals"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    name = Column(String(255))
    saved = Column(Float, default=0.0)
    target = Column(Float, default=0.0)
    monthly = Column(Float, default=0.0)
