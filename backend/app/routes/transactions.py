from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import desc
from typing import List, Optional
from datetime import datetime
from ..models.database import get_db
from ..models.transaction import Transaction
from ..models.budget import Budget, CategoryEnum
from ..services.ai_engine import AIEngine
from pydantic import BaseModel

router = APIRouter(prefix="/transactions", tags=["transactions"])
ai_engine = AIEngine()


class TransactionCreate(BaseModel):
    amount: float
    category: CategoryEnum
    description: Optional[str] = None
    transaction_type: str = "expense"  # expense ou income


class TransactionUpdate(BaseModel):
    amount: Optional[float] = None
    category: Optional[CategoryEnum] = None
    description: Optional[str] = None
    transaction_type: Optional[str] = None


class TransactionResponse(BaseModel):
    id: int
    user_id: int
    amount: float
    category: CategoryEnum
    description: Optional[str]
    transaction_type: str
    ai_score: Optional[float]
    ai_recommendation: Optional[str]
    was_approved: bool
    created_at: datetime

    class Config:
        from_attributes = True


@router.post("/", response_model=TransactionResponse)
def create_transaction(
    transaction: TransactionCreate,
    user_id: int = Query(default=1),
    db: Session = Depends(get_db)
):
    """Créer une nouvelle transaction et mettre à jour le budget correspondant"""

    # Analyser la transaction avec l'IA si c'est une dépense
    ai_score = None
    ai_recommendation = None

    if transaction.transaction_type == "expense":
        budget = db.query(Budget).filter(
            Budget.user_id == user_id,
            Budget.category == transaction.category
        ).first()

        if budget:
            budget_remaining = budget.monthly_limit - budget.current_spent
            result = ai_engine.calculate_score(
                amount=transaction.amount,
                category=transaction.category.value,
                budget_remaining=budget_remaining,
                monthly_spent=budget.current_spent,
                monthly_limit=budget.monthly_limit
            )
            ai_score = result["score"]
            ai_recommendation = result["recommendation"]

            # Mettre à jour le budget
            budget.current_spent += transaction.amount
            db.commit()

    # Créer la transaction
    new_transaction = Transaction(
        user_id=user_id,
        amount=transaction.amount,
        category=transaction.category,
        description=transaction.description,
        transaction_type=transaction.transaction_type,
        ai_score=ai_score,
        ai_recommendation=ai_recommendation,
        was_approved=True
    )
    db.add(new_transaction)
    db.commit()
    db.refresh(new_transaction)

    return new_transaction


@router.get("/", response_model=List[TransactionResponse])
def get_transactions(
    user_id: int = Query(default=1),
    category: Optional[CategoryEnum] = None,
    transaction_type: Optional[str] = None,
    limit: int = Query(default=50, le=100),
    offset: int = Query(default=0),
    db: Session = Depends(get_db)
):
    """Récupérer toutes les transactions d'un utilisateur avec filtres optionnels"""
    query = db.query(Transaction).filter(Transaction.user_id == user_id)

    if category:
        query = query.filter(Transaction.category == category)
    if transaction_type:
        query = query.filter(Transaction.transaction_type == transaction_type)

    transactions = query.order_by(desc(Transaction.created_at)).offset(offset).limit(limit).all()
    return transactions


@router.get("/summary")
def get_transactions_summary(
    user_id: int = Query(default=1),
    db: Session = Depends(get_db)
):
    """Obtenir un résumé des transactions (total dépenses, revenus, etc.)"""
    transactions = db.query(Transaction).filter(Transaction.user_id == user_id).all()

    total_expenses = sum(t.amount for t in transactions if t.transaction_type == "expense")
    total_income = sum(t.amount for t in transactions if t.transaction_type == "income")

    # Répartition par catégorie
    by_category = {}
    for t in transactions:
        if t.transaction_type == "expense":
            cat = t.category.value
            by_category[cat] = by_category.get(cat, 0) + t.amount

    return {
        "total_expenses": total_expenses,
        "total_income": total_income,
        "balance": total_income - total_expenses,
        "transaction_count": len(transactions),
        "by_category": by_category
    }


@router.get("/{transaction_id}", response_model=TransactionResponse)
def get_transaction(transaction_id: int, db: Session = Depends(get_db)):
    """Récupérer une transaction par son ID"""
    transaction = db.query(Transaction).filter(Transaction.id == transaction_id).first()
    if not transaction:
        raise HTTPException(status_code=404, detail="Transaction non trouvée")
    return transaction


@router.put("/{transaction_id}", response_model=TransactionResponse)
def update_transaction(
    transaction_id: int,
    transaction_update: TransactionUpdate,
    db: Session = Depends(get_db)
):
    """Mettre à jour une transaction"""
    transaction = db.query(Transaction).filter(Transaction.id == transaction_id).first()
    if not transaction:
        raise HTTPException(status_code=404, detail="Transaction non trouvée")

    # Mettre à jour les champs fournis
    update_data = transaction_update.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(transaction, key, value)

    db.commit()
    db.refresh(transaction)
    return transaction


@router.delete("/{transaction_id}")
def delete_transaction(transaction_id: int, db: Session = Depends(get_db)):
    """Supprimer une transaction"""
    transaction = db.query(Transaction).filter(Transaction.id == transaction_id).first()
    if not transaction:
        raise HTTPException(status_code=404, detail="Transaction non trouvée")

    # Si c'était une dépense, remettre le montant dans le budget
    if transaction.transaction_type == "expense":
        budget = db.query(Budget).filter(
            Budget.user_id == transaction.user_id,
            Budget.category == transaction.category
        ).first()
        if budget:
            budget.current_spent = max(0, budget.current_spent - transaction.amount)

    db.delete(transaction)
    db.commit()

    return {"message": "Transaction supprimée avec succès"}
