from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import desc
from typing import List, Optional
from datetime import datetime, timedelta
from ..models.database import get_db
from ..models.budget import Budget, CategoryEnum
from ..models.transaction import Transaction
from ..models.goal import Goal
from ..services.ai_engine import AIEngine
from pydantic import BaseModel

router = APIRouter(prefix="/ai", tags=["ai"])
ai_engine = AIEngine()


class TransactionAnalysis(BaseModel):
    amount: float
    category: str
    description: Optional[str] = None


class VoiceQuery(BaseModel):
    query: str


@router.post("/analyze")
def analyze_transaction(
    data: TransactionAnalysis,
    user_id: int = Query(default=1),
    db: Session = Depends(get_db)
):
    """Analyser une transaction avant de la valider"""
    budget = db.query(Budget).filter(
        Budget.user_id == user_id,
        Budget.category == data.category
    ).first()

    if not budget:
        return {
            "approved": True,
            "score": 5,
            "color": "orange",
            "recommendation": "Aucun budget défini pour cette catégorie. Créez un budget pour un meilleur suivi.",
            "budget_info": None
        }

    budget_remaining = budget.monthly_limit - budget.current_spent

    result = ai_engine.calculate_score(
        amount=data.amount,
        category=data.category,
        budget_remaining=budget_remaining,
        monthly_spent=budget.current_spent,
        monthly_limit=budget.monthly_limit
    )

    # Ajouter des informations sur les objectifs impactés
    goals = db.query(Goal).filter(
        Goal.user_id == user_id,
        Goal.is_completed == False
    ).all()

    goals_impact = []
    for goal in goals:
        remaining_to_goal = goal.target_amount - goal.current_amount
        if data.amount > remaining_to_goal * 0.1:  # Si la dépense représente + de 10% de l'objectif restant
            goals_impact.append({
                "name": goal.name,
                "impact_percentage": round(data.amount / remaining_to_goal * 100, 1)
            })

    return {
        "approved": result["score"] > 3,
        "score": result["score"],
        "color": result["color"],
        "recommendation": result["recommendation"],
        "budget_info": {
            "category": data.category,
            "monthly_limit": budget.monthly_limit,
            "current_spent": budget.current_spent,
            "remaining": budget_remaining,
            "usage_percentage": result["budget_percentage"],
            "transaction_percentage": result["transaction_percentage"]
        },
        "goals_impact": goals_impact
    }


@router.post("/recommend")
def get_recommendations(
    user_id: int = Query(default=1),
    db: Session = Depends(get_db)
):
    """Obtenir des recommandations personnalisées basées sur les habitudes de dépenses"""
    budgets = db.query(Budget).filter(Budget.user_id == user_id).all()
    transactions = db.query(Transaction).filter(
        Transaction.user_id == user_id
    ).order_by(desc(Transaction.created_at)).limit(50).all()

    recommendations = []

    # Analyser les budgets
    for budget in budgets:
        usage = (budget.current_spent / budget.monthly_limit * 100) if budget.monthly_limit > 0 else 0

        if usage > 90:
            recommendations.append({
                "type": "warning",
                "category": budget.category.value,
                "message": f"Attention ! Votre budget {budget.category.value} est utilisé à {usage:.0f}%. Limitez vos dépenses dans cette catégorie.",
                "priority": "high"
            })
        elif usage > 70:
            recommendations.append({
                "type": "caution",
                "category": budget.category.value,
                "message": f"Votre budget {budget.category.value} est à {usage:.0f}%. Pensez à ralentir vos dépenses.",
                "priority": "medium"
            })
        elif usage < 30:
            recommendations.append({
                "type": "tip",
                "category": budget.category.value,
                "message": f"Bien joué ! Vous n'avez utilisé que {usage:.0f}% de votre budget {budget.category.value}. Continuez ainsi !",
                "priority": "low"
            })

    # Analyser les tendances de dépenses
    if transactions:
        total_spent = sum(t.amount for t in transactions if t.transaction_type == "expense")
        avg_transaction = total_spent / len([t for t in transactions if t.transaction_type == "expense"]) if transactions else 0

        if avg_transaction > 50000:  # Si moyenne > 50,000 FCFA
            recommendations.append({
                "type": "insight",
                "category": "general",
                "message": f"Vos transactions moyennes sont de {avg_transaction:,.0f} FCFA. Essayez de diviser vos achats importants.",
                "priority": "medium"
            })

    # Vérifier les objectifs
    goals = db.query(Goal).filter(
        Goal.user_id == user_id,
        Goal.is_completed == False
    ).all()

    for goal in goals:
        progress = (goal.current_amount / goal.target_amount * 100) if goal.target_amount > 0 else 0
        if progress < 25 and goal.target_date:
            days_left = (goal.target_date - datetime.utcnow()).days
            if days_left < 90:
                recommendations.append({
                    "type": "goal_alert",
                    "category": "epargne",
                    "message": f"Votre objectif '{goal.name}' n'est qu'à {progress:.0f}% et il reste {days_left} jours. Augmentez vos versements !",
                    "priority": "high"
                })

    return {
        "recommendations": sorted(recommendations, key=lambda x: {"high": 0, "medium": 1, "low": 2}.get(x["priority"], 3)),
        "total_recommendations": len(recommendations)
    }


@router.post("/predict")
def predict_end_of_month(
    user_id: int = Query(default=1),
    db: Session = Depends(get_db)
):
    """Prédire la situation financière en fin de mois"""
    budgets = db.query(Budget).filter(Budget.user_id == user_id).all()
    transactions = db.query(Transaction).filter(
        Transaction.user_id == user_id,
        Transaction.transaction_type == "expense"
    ).all()

    # Calculer les jours écoulés et restants dans le mois
    today = datetime.utcnow()
    days_in_month = 30
    days_elapsed = today.day
    days_remaining = days_in_month - days_elapsed

    predictions = []
    total_predicted_overspend = 0

    for budget in budgets:
        # Calculer le taux de dépense journalier
        daily_rate = budget.current_spent / days_elapsed if days_elapsed > 0 else 0
        predicted_total = budget.current_spent + (daily_rate * days_remaining)
        predicted_overspend = max(0, predicted_total - budget.monthly_limit)

        status = "on_track"
        if predicted_total > budget.monthly_limit:
            status = "will_exceed"
            total_predicted_overspend += predicted_overspend
        elif predicted_total > budget.monthly_limit * 0.9:
            status = "at_risk"

        predictions.append({
            "category": budget.category.value,
            "current_spent": budget.current_spent,
            "monthly_limit": budget.monthly_limit,
            "predicted_total": round(predicted_total, 2),
            "predicted_overspend": round(predicted_overspend, 2),
            "daily_rate": round(daily_rate, 2),
            "status": status
        })

    # Calcul global
    total_limit = sum(b.monthly_limit for b in budgets)
    total_spent = sum(b.current_spent for b in budgets)
    total_predicted = sum(p["predicted_total"] for p in predictions)

    return {
        "days_elapsed": days_elapsed,
        "days_remaining": days_remaining,
        "summary": {
            "total_budget": total_limit,
            "total_spent": total_spent,
            "total_predicted": round(total_predicted, 2),
            "predicted_overspend": round(total_predicted_overspend, 2),
            "overall_status": "critical" if total_predicted_overspend > 0 else "healthy"
        },
        "by_category": predictions,
        "advice": ai_engine.generate_monthly_advice(
            total_spent, total_limit, days_remaining, total_predicted_overspend
        )
    }


@router.post("/voice")
def process_voice_query(
    data: VoiceQuery,
    user_id: int = Query(default=1),
    db: Session = Depends(get_db)
):
    """Traiter une requête vocale de l'utilisateur"""
    query = data.query.lower()

    # Récupérer le contexte financier
    budgets = db.query(Budget).filter(Budget.user_id == user_id).all()
    goals = db.query(Goal).filter(Goal.user_id == user_id, Goal.is_completed == False).all()

    total_budget = sum(b.monthly_limit for b in budgets)
    total_spent = sum(b.current_spent for b in budgets)
    remaining = total_budget - total_spent

    # Analyser la requête
    response = ai_engine.process_voice_query(
        query=query,
        total_budget=total_budget,
        total_spent=total_spent,
        remaining=remaining,
        budgets=budgets,
        goals=goals
    )

    return {
        "query": data.query,
        "response": response,
        "context": {
            "total_budget": total_budget,
            "total_spent": total_spent,
            "remaining": remaining
        }
    }


# ==================== SIKA ASSISTANT ====================

class SikaQuery(BaseModel):
    query: str


class SikaConfirmTransaction(BaseModel):
    amount: float
    category: str
    description: Optional[str] = "Dépense via Sika"


@router.post("/sika")
def sika_chat(
    data: SikaQuery,
    user_id: int = Query(default=1),
    db: Session = Depends(get_db)
):
    """
    Endpoint principal de Sika - l'assistant vocal intelligent

    Retourne:
    - message: La réponse de Sika
    - intent: L'intention détectée (expense_past, expense_future, balance, advice, greeting)
    - can_add_transaction: Si l'utilisateur peut confirmer une transaction
    - suggested_transaction: Détails de la transaction suggérée (si applicable)
    """
    # Récupérer le contexte financier
    budgets = db.query(Budget).filter(Budget.user_id == user_id).all()
    goals = db.query(Goal).filter(Goal.user_id == user_id, Goal.is_completed == False).all()

    total_budget = sum(b.monthly_limit for b in budgets)
    total_spent = sum(b.current_spent for b in budgets)

    # Utiliser le moteur Sika
    result = ai_engine.sika_process_query(
        query=data.query,
        budgets=budgets,
        goals=goals,
        total_budget=total_budget,
        total_spent=total_spent
    )

    return {
        "query": data.query,
        "message": result["message"],
        "intent": result["intent"],
        "can_add_transaction": result["can_add_transaction"],
        "suggested_transaction": result["suggested_transaction"],
        "context": {
            "total_budget": total_budget,
            "total_spent": total_spent,
            "remaining": total_budget - total_spent
        }
    }


@router.post("/sika/confirm")
def sika_confirm_transaction(
    data: SikaConfirmTransaction,
    user_id: int = Query(default=1),
    db: Session = Depends(get_db)
):
    """
    Confirmer et enregistrer une transaction suggérée par Sika
    """
    from ..models.transaction import Transaction

    # Valider la catégorie
    try:
        category = CategoryEnum(data.category)
    except ValueError:
        category = CategoryEnum.autre

    # Créer la transaction
    new_transaction = Transaction(
        user_id=user_id,
        amount=data.amount,
        category=category,
        description=data.description or "Dépense via Sika",
        transaction_type="expense",
        was_approved=True
    )
    db.add(new_transaction)

    # Mettre à jour le budget correspondant
    budget = db.query(Budget).filter(
        Budget.user_id == user_id,
        Budget.category == category
    ).first()

    if budget:
        budget.current_spent += data.amount

    db.commit()
    db.refresh(new_transaction)

    return {
        "success": True,
        "message": f"✅ J'ai enregistré ta dépense de {data.amount:,.0f} FCFA dans {data.category}.",
        "transaction_id": new_transaction.id,
        "new_budget_spent": budget.current_spent if budget else None
    }
