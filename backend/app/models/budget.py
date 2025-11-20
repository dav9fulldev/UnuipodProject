from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Enum, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .database import Base
import enum

class CategoryEnum(str, enum.Enum):
    ALIMENTATION = "alimentation"
    TRANSPORT = "transport"
    LOGEMENT = "logement"
    SANTE = "sante"
    EDUCATION = "education"
    LOISIRS = "loisirs"
    EPARGNE = "epargne"
    AUTRE = "autre"

class Budget(Base):
    __tablename__ = "budgets"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    category = Column(Enum(CategoryEnum), nullable=False)
    monthly_limit = Column(Float, nullable=False)
    current_spent = Column(Float, default=0.0)
    period_start = Column(DateTime(timezone=True), server_default=func.now())
    period_end = Column(DateTime(timezone=True))

class Transaction(Base):
    __tablename__ = "transactions"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    amount = Column(Float, nullable=False)
    category = Column(Enum(CategoryEnum), nullable=False)
    description = Column(String)
    ai_score = Column(Float)
    ai_recommendation = Column(String)
    was_approved = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())