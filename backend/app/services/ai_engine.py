from typing import Dict, Any
import requests
import os

class AIEngine:
    def __init__(self):
        self.gemini_api_key = os.getenv("GEMINI_API_KEY")
    
    def calculate_score(self, 
                       amount: float, 
                       category: str, 
                       budget_remaining: float,
                       monthly_spent: float,
                       monthly_limit: float) -> Dict[str, Any]:
        """
        Calcule un score de 1 à 10 pour une transaction
        """
        budget_percentage = (monthly_spent / monthly_limit) * 100 if monthly_limit > 0 else 100
        transaction_percentage = (amount / monthly_limit) * 100 if monthly_limit > 0 else 100
        
        score = 10
        
        if budget_percentage > 90:
            score -= 5
        elif budget_percentage > 75:
            score -= 3
        elif budget_percentage > 50:
            score -= 1
        
        if transaction_percentage > 20:
            score -= 2
        elif transaction_percentage > 10:
            score -= 1
        
        if budget_remaining < amount:
            score = 1
        
        score = max(1, min(10, score))
        
        if score <= 3:
            recommendation = "⛔ Attention ! Cette dépense risque de compromettre vos objectifs."
            color = "red"
        elif score <= 6:
            recommendation = "⚠️ Prudence recommandée. Votre budget est presque épuisé."
            color = "orange"
        else:
            recommendation = "✅ Cette dépense est raisonnable par rapport à votre budget."
            color = "green"
        
        return {
            "score": score,
            "recommendation": recommendation,
            "color": color,
            "budget_percentage": round(budget_percentage, 2),
            "transaction_percentage": round(transaction_percentage, 2),
            "remaining_budget": round(budget_remaining, 2)
        }
    
    def analyze_with_gemini(self, transaction_data: Dict[str, Any]) -> str:
        return "Analyse détaillée à implémenter avec Gemini API"