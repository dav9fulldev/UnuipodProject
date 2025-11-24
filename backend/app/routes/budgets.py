from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
from ..models.database import get_db
from ..models.budget import Budget, CategoryEnum
from pydantic import BaseModel

router = APIRouter(prefix="/budgets", tags=["budgets"])


class BudgetCreate(BaseModel):
    category: CategoryEnum
    monthly_limit: float


class BudgetUpdate(BaseModel):
    monthly_limit: Optional[float] = None
    current_spent: Optional[float] = None


class BudgetResponse(BaseModel):
    id: int
    user_id: int
    category: CategoryEnum
    monthly_limit: float
    current_spent: float
    remaining: float = 0.0
    usage_percentage: float = 0.0
    period_start: Optional[datetime] = None

    class Config:
        from_attributes = True

    @classmethod
    def from_orm_with_stats(cls, budget: Budget):
        remaining = budget.monthly_limit - budget.current_spent
        percentage = (budget.current_spent / budget.monthly_limit * 100) if budget.monthly_limit > 0 else 0
        return cls(
            id=budget.id,
            user_id=budget.user_id,
            category=budget.category,
            monthly_limit=budget.monthly_limit,
            current_spent=budget.current_spent,
            remaining=round(remaining, 2),
            usage_percentage=round(percentage, 2),
            period_start=budget.period_start
        )


@router.post("/", response_model=BudgetResponse)
def create_budget(
    budget: BudgetCreate,
    user_id: int = Query(default=1),
    db: Session = Depends(get_db)
):
    """Créer un nouveau budget pour une catégorie"""
    # Vérifier si un budget existe déjà pour cette catégorie
    existing = db.query(Budget).filter(
        Budget.user_id == user_id,
        Budget.category == budget.category
    ).first()

    if existing:
        raise HTTPException(
            status_code=400,
            detail=f"Un budget existe déjà pour la catégorie {budget.category.value}"
        )

    new_budget = Budget(
        user_id=user_id,
        category=budget.category,
        monthly_limit=budget.monthly_limit
    )
    db.add(new_budget)
    db.commit()
    db.refresh(new_budget)

    return BudgetResponse.from_orm_with_stats(new_budget)


@router.get("/", response_model=List[BudgetResponse])
def get_budgets(
    user_id: int = Query(default=1),
    db: Session = Depends(get_db)
):
    """Récupérer tous les budgets d'un utilisateur"""
    budgets = db.query(Budget).filter(Budget.user_id == user_id).all()
    return [BudgetResponse.from_orm_with_stats(b) for b in budgets]


@router.get("/summary")
def get_budgets_summary(
    user_id: int = Query(default=1),
    db: Session = Depends(get_db)
):
    """Obtenir un résumé global des budgets"""
    budgets = db.query(Budget).filter(Budget.user_id == user_id).all()

    total_limit = sum(b.monthly_limit for b in budgets)
    total_spent = sum(b.current_spent for b in budgets)
    total_remaining = total_limit - total_spent

    return {
        "total_monthly_limit": total_limit,
        "total_spent": total_spent,
        "total_remaining": total_remaining,
        "overall_usage_percentage": round((total_spent / total_limit * 100) if total_limit > 0 else 0, 2),
        "budget_count": len(budgets)
    }


@router.get("/{budget_id}", response_model=BudgetResponse)
def get_budget(budget_id: int, db: Session = Depends(get_db)):
    """Récupérer un budget par son ID"""
    budget = db.query(Budget).filter(Budget.id == budget_id).first()
    if not budget:
        raise HTTPException(status_code=404, detail="Budget non trouvé")

    return BudgetResponse.from_orm_with_stats(budget)


@router.put("/{budget_id}", response_model=BudgetResponse)
def update_budget(
    budget_id: int,
    budget_update: BudgetUpdate,
    db: Session = Depends(get_db)
):
    """Mettre à jour un budget"""
    budget = db.query(Budget).filter(Budget.id == budget_id).first()
    if not budget:
        raise HTTPException(status_code=404, detail="Budget non trouvé")

    update_data = budget_update.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(budget, key, value)

    db.commit()
    db.refresh(budget)

    return BudgetResponse.from_orm_with_stats(budget)


@router.delete("/{budget_id}")
def delete_budget(budget_id: int, db: Session = Depends(get_db)):
    """Supprimer un budget"""
    budget = db.query(Budget).filter(Budget.id == budget_id).first()
    if not budget:
        raise HTTPException(status_code=404, detail="Budget non trouvé")

    db.delete(budget)
    db.commit()

    return {"message": "Budget supprimé avec succès"}


@router.post("/reset")
def reset_budgets(
    user_id: int = Query(default=1),
    db: Session = Depends(get_db)
):
    """Réinitialiser les dépenses de tous les budgets (nouveau mois)"""
    budgets = db.query(Budget).filter(Budget.user_id == user_id).all()

    for budget in budgets:
        budget.current_spent = 0.0
        budget.period_start = datetime.utcnow()

    db.commit()

    return {"message": f"{len(budgets)} budgets réinitialisés"}