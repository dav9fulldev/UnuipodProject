from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from ..models.database import get_db
from ..models.budget import Budget, CategoryEnum
from pydantic import BaseModel

router = APIRouter(prefix="/budgets", tags=["budgets"])

class BudgetCreate(BaseModel):
    category: CategoryEnum
    monthly_limit: float

class BudgetResponse(BaseModel):
    id: int
    category: CategoryEnum
    monthly_limit: float
    current_spent: float
    
    class Config:
        from_attributes = True

@router.post("/", response_model=BudgetResponse)
def create_budget(budget: BudgetCreate, user_id: int = 1, db: Session = Depends(get_db)):
    new_budget = Budget(
        user_id=user_id,
        category=budget.category,
        monthly_limit=budget.monthly_limit
    )
    db.add(new_budget)
    db.commit()
    db.refresh(new_budget)
    return new_budget

@router.get("/", response_model=List[BudgetResponse])
def get_budgets(user_id: int = 1, db: Session = Depends(get_db)):
    budgets = db.query(Budget).filter(Budget.user_id == user_id).all()
    return budgets

@router.get("/{budget_id}", response_model=BudgetResponse)
def get_budget(budget_id: int, db: Session = Depends(get_db)):
    budget = db.query(Budget).filter(Budget.id == budget_id).first()
    if not budget:
        raise HTTPException(status_code=404, detail="Budget non trouvé")
    return budget