from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from ..models.database import get_db
from ..models.budget import Budget
from ..services.ai_engine import AIEngine
from pydantic import BaseModel

router = APIRouter(prefix="/ai", tags=["ai"])
ai_engine = AIEngine()

class TransactionAnalysis(BaseModel):
    amount: float
    category: str
    user_id: int = 1

@router.post("/analyze")
def analyze_transaction(data: TransactionAnalysis, db: Session = Depends(get_db)):
    budget = db.query(Budget).filter(
        Budget.user_id == data.user_id,
        Budget.category == data.category
    ).first()
    
    if not budget:
        return {
            "error": "Aucun budget défini pour cette catégorie",
            "score": 5,
            "recommendation": "Créez d'abord un budget pour cette catégorie."
        }
    
    budget_remaining = budget.monthly_limit - budget.current_spent
    
    result = ai_engine.calculate_score(
        amount=data.amount,
        category=data.category,
        budget_remaining=budget_remaining,
        monthly_spent=budget.current_spent,
        monthly_limit=budget.monthly_limit
    )
    
    return result