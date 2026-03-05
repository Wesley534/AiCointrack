import sys
import asyncio
from app.db.session import SessionLocal
from app.models.user import User
from app.core.security import create_access_token

def get_token():
    db = SessionLocal()
    user = db.query(User).first()
    if not user:
        return None
    token = create_access_token({"sub": str(user.id)})
    return token

print(get_token())
