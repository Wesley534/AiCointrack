from sqlalchemy import Column, Integer, String, Float, ForeignKey
from sqlalchemy.orm import relationship
from app.db.base import Base

class ShoppingList(Base):
    __tablename__ = "shopping_lists"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    name = Column(String(255))
    budget = Column(Float, default=0.0)
    status = Column(String(50), default='green')  # green / yellow / red

    items = relationship("ShoppingItem", back_populates="shopping_list", cascade="all, delete-orphan")

class ShoppingItem(Base):
    __tablename__ = "shopping_items"

    id = Column(Integer, primary_key=True, index=True)
    list_id = Column(Integer, ForeignKey("shopping_lists.id"))
    name = Column(String(255))
    qty = Column(Integer, default=1)
    price = Column(Float, default=0.0)

    shopping_list = relationship("ShoppingList", back_populates="items")
