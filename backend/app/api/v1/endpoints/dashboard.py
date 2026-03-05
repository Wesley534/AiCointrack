from typing import List, Dict, Any
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models.budget import Budget
from app.models.wallet_balance import WalletBalance
from app.models.transaction import Transaction
from app.models.user import User
from app.core.deps import get_current_user_jwt

router = APIRouter()

@router.get("/summary")
@router.get("/miniapp")
def get_dashboard_summary(db: Session = Depends(get_db), current_user: User = Depends(get_current_user_jwt)):
    # Calculate values from DB
    budgets = db.query(Budget).filter(Budget.user_id == current_user.id).all()
    total_planned = sum(b.planned for b in budgets)
    total_actual = sum(b.actual for b in budgets)
    variance = total_planned - total_actual
    
    wb = db.query(WalletBalance).filter(WalletBalance.user_id == current_user.id).first()
    free_to_spend = wb.balance if wb else 0.0
    
    # Calculate month progress (mocking for current day logic)
    import datetime
    today = datetime.date.today()
    import calendar
    days_in_month = calendar.monthrange(today.year, today.month)[1]
    month_progress = today.day / days_in_month
    
    return {
        "freeToSpend": free_to_spend,
        "variance": variance,
        "monthProgress": month_progress
    }

@router.get("/closeout")
def get_closeout_summary(db: Session = Depends(get_db), current_user: User = Depends(get_current_user_jwt)):
    txs = db.query(Transaction).filter(Transaction.user_id == current_user.id).all()
    income = sum(tx.amount for tx in txs if tx.amount > 0)
    expenses = sum(abs(tx.amount) for tx in txs if tx.amount < 0)
    saved = 0.0 # From savings goals if added
    surplus = income - expenses
    
    return {
        "metrics": [
            {"label": "Income", "value": f"Ksh {income:,.0f}", "color": "green"},
            {"label": "Expenses", "value": f"Ksh {expenses:,.0f}", "color": "red"},
            {"label": "Saved", "value": f"Ksh {saved:,.0f}", "color": "green"},
            {"label": "Surplus", "value": f"Ksh {surplus:,.0f}", "color": "orange"}
        ],
        "categoryDiffs": []
    }

@router.get("/settings")
def get_settings(db: Session = Depends(get_db), current_user: User = Depends(get_current_user_jwt)):
    return {
        "userName": current_user.display_name or current_user.full_name or "User",
        "email": current_user.email or "",
        "walletLabel": f"{current_user.wallet_address[:6]}…{current_user.wallet_address[-4:]} · Base" if current_user.wallet_address else "No Wallet",
        "toggles": [
            {"label": "Auto-logging (Notifications)", "enabled": True},
            {"label": "Email Parsing", "enabled": True},
            {"label": "Blockchain Sync (Base)", "enabled": True},
            {"label": "AI Categorization", "enabled": True},
            {"label": "Strict Budget Mode", "enabled": False},
            {"label": "AI Insights Feed", "enabled": True}
        ]
    }
