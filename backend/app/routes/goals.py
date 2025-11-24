from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import desc
from typing import List, Optional
from datetime import datetime
from ..models.database import get_db
from ..models.goal import Goal
from pydantic import BaseModel

router = APIRouter(prefix="/goals", tags=["goals"])


class GoalCreate(BaseModel):
    name: str
    description: Optional[str] = None
    target_amount: float
    target_date: Optional[datetime] = None
    icon: str = "flag"
    color: str = "#00A86B"


class GoalUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    target_amount: Optional[float] = None
    current_amount: Optional[float] = None
    target_date: Optional[datetime] = None
    icon: Optional[str] = None
    color: Optional[str] = None
    is_completed: Optional[bool] = None


class GoalAddAmount(BaseModel):
    amount: float


class GoalResponse(BaseModel):
    id: int
    user_id: int
    name: str
    description: Optional[str]
    target_amount: float
    current_amount: float
    target_date: Optional[datetime]
    icon: str
    color: str
    is_completed: bool
    created_at: datetime
    progress_percentage: float = 0.0

    class Config:
        from_attributes = True

    @classmethod
    def from_orm_with_progress(cls, goal: Goal):
        progress = (goal.current_amount / goal.target_amount * 100) if goal.target_amount > 0 else 0
        return cls(
            id=goal.id,
            user_id=goal.user_id,
            name=goal.name,
            description=goal.description,
            target_amount=goal.target_amount,
            current_amount=goal.current_amount,
            target_date=goal.target_date,
            icon=goal.icon,
            color=goal.color,
            is_completed=goal.is_completed,
            created_at=goal.created_at,
            progress_percentage=round(progress, 2)
        )


@router.post("/", response_model=GoalResponse)
def create_goal(
    goal: GoalCreate,
    user_id: int = Query(default=1),
    db: Session = Depends(get_db)
):
    """Créer un nouvel objectif d'épargne"""
    new_goal = Goal(
        user_id=user_id,
        name=goal.name,
        description=goal.description,
        target_amount=goal.target_amount,
        target_date=goal.target_date,
        icon=goal.icon,
        color=goal.color
    )
    db.add(new_goal)
    db.commit()
    db.refresh(new_goal)

    return GoalResponse.from_orm_with_progress(new_goal)


@router.get("/", response_model=List[GoalResponse])
def get_goals(
    user_id: int = Query(default=1),
    include_completed: bool = Query(default=True),
    db: Session = Depends(get_db)
):
    """Récupérer tous les objectifs d'un utilisateur"""
    query = db.query(Goal).filter(Goal.user_id == user_id)

    if not include_completed:
        query = query.filter(Goal.is_completed == False)

    goals = query.order_by(desc(Goal.created_at)).all()

    return [GoalResponse.from_orm_with_progress(g) for g in goals]


@router.get("/summary")
def get_goals_summary(
    user_id: int = Query(default=1),
    db: Session = Depends(get_db)
):
    """Obtenir un résumé des objectifs"""
    goals = db.query(Goal).filter(Goal.user_id == user_id).all()

    total_target = sum(g.target_amount for g in goals)
    total_saved = sum(g.current_amount for g in goals)
    completed_count = sum(1 for g in goals if g.is_completed)
    in_progress_count = sum(1 for g in goals if not g.is_completed)

    return {
        "total_goals": len(goals),
        "completed": completed_count,
        "in_progress": in_progress_count,
        "total_target_amount": total_target,
        "total_saved_amount": total_saved,
        "overall_progress": round((total_saved / total_target * 100) if total_target > 0 else 0, 2)
    }


@router.get("/{goal_id}", response_model=GoalResponse)
def get_goal(goal_id: int, db: Session = Depends(get_db)):
    """Récupérer un objectif par son ID"""
    goal = db.query(Goal).filter(Goal.id == goal_id).first()
    if not goal:
        raise HTTPException(status_code=404, detail="Objectif non trouvé")

    return GoalResponse.from_orm_with_progress(goal)


@router.put("/{goal_id}", response_model=GoalResponse)
def update_goal(
    goal_id: int,
    goal_update: GoalUpdate,
    db: Session = Depends(get_db)
):
    """Mettre à jour un objectif"""
    goal = db.query(Goal).filter(Goal.id == goal_id).first()
    if not goal:
        raise HTTPException(status_code=404, detail="Objectif non trouvé")

    update_data = goal_update.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(goal, key, value)

    # Vérifier si l'objectif est atteint
    if goal.current_amount >= goal.target_amount:
        goal.is_completed = True

    db.commit()
    db.refresh(goal)

    return GoalResponse.from_orm_with_progress(goal)


@router.post("/{goal_id}/add", response_model=GoalResponse)
def add_to_goal(
    goal_id: int,
    data: GoalAddAmount,
    db: Session = Depends(get_db)
):
    """Ajouter un montant à un objectif d'épargne"""
    goal = db.query(Goal).filter(Goal.id == goal_id).first()
    if not goal:
        raise HTTPException(status_code=404, detail="Objectif non trouvé")

    goal.current_amount += data.amount

    # Vérifier si l'objectif est atteint
    if goal.current_amount >= goal.target_amount:
        goal.is_completed = True

    db.commit()
    db.refresh(goal)

    return GoalResponse.from_orm_with_progress(goal)


@router.delete("/{goal_id}")
def delete_goal(goal_id: int, db: Session = Depends(get_db)):
    """Supprimer un objectif"""
    goal = db.query(Goal).filter(Goal.id == goal_id).first()
    if not goal:
        raise HTTPException(status_code=404, detail="Objectif non trouvé")

    db.delete(goal)
    db.commit()

    return {"message": "Objectif supprimé avec succès"}
