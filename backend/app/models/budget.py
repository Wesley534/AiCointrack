from sqlalchemy import Column, Integer, String, Float, ForeignKey
from app.db.base import Base

class Budget(Base):
    __tablename__ = "budgets"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    label = Column(String(255))
    planned = Column(Float, default=0.0)
    actual = Column(Float, default=0.0)
    tag = Column(String(50))
    kind = Column(String(50))  # need / want / save
    month = Column(String(50))  # e.g., '2024-03'
