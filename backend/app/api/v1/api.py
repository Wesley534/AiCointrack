from fastapi import APIRouter

from app.api.v1.endpoints import (
    auth,
    transactions,
    budgets,
    shopping,
    savings_goals,
    wallet,
    dashboard,
)

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(transactions.router, prefix="/transactions", tags=["transactions"])
api_router.include_router(budgets.router, prefix="/budgets", tags=["budgets"])
api_router.include_router(shopping.router, prefix="/shopping-lists", tags=["shopping"])
api_router.include_router(savings_goals.router, prefix="/savings-goals", tags=["savings"])
api_router.include_router(wallet.router, prefix="/wallet", tags=["wallet"])
api_router.include_router(dashboard.router, prefix="/dashboard", tags=["dashboard"])
