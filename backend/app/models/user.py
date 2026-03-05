from datetime import datetime

from sqlalchemy import Boolean, Column, DateTime, Integer, String, JSON

from app.db.base import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=True)  # nullable for wallet-only users
    hashed_password = Column(String(255), nullable=True)  # Optional for Firebase/wallet users
    full_name = Column(String(255), nullable=True)
    firebase_uid = Column(String(255), unique=True, index=True, nullable=True)
    display_name = Column(String(255), nullable=True)
    photo_url = Column(String(500), nullable=True)
    # Wallet — may or may not exist at registration
    wallet_address = Column(String(42), unique=True, index=True, nullable=True)  # 0x + 40 hex
    wallet_created_by_system = Column(Boolean, default=False, nullable=True)
    privy_user_id = Column(String(128), unique=True, index=True, nullable=True)  # did:privy:xxx — for export
    wallet_type = Column(String(32), nullable=True)  # "privy_managed", "linked", etc.
    # Which providers this user has linked: ["google", "email", "wallet"]
    auth_providers = Column(JSON, nullable=True, default=list)  # ["google"], ["email"], ["wallet"], etc.
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

