from typing import Dict, Any, List, Optional
import os
import re


# Mapping des catégories en français vers l'enum
CATEGORY_KEYWORDS = {
    "alimentation": ["manger", "nourriture", "repas", "restaurant", "courses", "alimentation", "bouffe", "déjeuner", "dîner", "petit-déjeuner"],
    "transport": ["transport", "taxi", "uber", "bus", "essence", "carburant", "voiture", "moto", "déplacement", "trajet"],
    "logement": ["loyer", "logement", "maison", "appartement", "électricité", "eau", "facture"],
    "sante": ["santé", "médecin", "pharmacie", "médicament", "hôpital", "consultation", "ordonnance"],
    "education": ["école", "formation", "cours", "livre", "études", "éducation", "scolarité"],
    "loisirs": ["loisirs", "divertissement", "cinéma", "sortie", "jeux", "sport", "abonnement", "netflix"],
    "epargne": ["épargne", "économie", "investissement", "placement"],
    "vetements": ["vêtements", "habits", "chaussures", "mode", "shopping"],
    "communication": ["téléphone", "internet", "forfait", "crédit", "communication", "data"],
    "autre": ["autre", "divers", "cadeau", "don"]
}


class AIEngine:
    def __init__(self):
        self.gemini_api_key = os.getenv("GEMINI_API_KEY")

    def calculate_score(
        self,
        amount: float,
        category: str,
        budget_remaining: float,
        monthly_spent: float,
        monthly_limit: float
    ) -> Dict[str, Any]:
        """
        Calcule un score de 1 à 10 pour une transaction
        """
        budget_percentage = (monthly_spent / monthly_limit) * 100 if monthly_limit > 0 else 100
        transaction_percentage = (amount / monthly_limit) * 100 if monthly_limit > 0 else 100

        score = 10

        # Pénalité selon le pourcentage du budget utilisé
        if budget_percentage > 90:
            score -= 5
        elif budget_percentage > 75:
            score -= 3
        elif budget_percentage > 50:
            score -= 1

        # Pénalité selon le poids de la transaction
        if transaction_percentage > 20:
            score -= 2
        elif transaction_percentage > 10:
            score -= 1

        # Transaction impossible si budget insuffisant
        if budget_remaining < amount:
            score = 1

        score = max(1, min(10, score))

        if score <= 3:
            recommendation = "⛔ Attention ! Cette dépense risque de compromettre vos objectifs financiers."
            color = "red"
        elif score <= 6:
            recommendation = "⚠️ Prudence recommandée. Votre budget est presque épuisé pour cette catégorie."
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

    def generate_monthly_advice(
        self,
        total_spent: float,
        total_limit: float,
        days_remaining: int,
        predicted_overspend: float
    ) -> str:
        """Générer un conseil pour la fin de mois"""
        if predicted_overspend > 0:
            daily_reduction = predicted_overspend / days_remaining if days_remaining > 0 else predicted_overspend
            return (
                f"⚠️ À ce rythme, vous dépasserez votre budget de {predicted_overspend:,.0f} FCFA. "
                f"Réduisez vos dépenses de {daily_reduction:,.0f} FCFA par jour pour rester dans les limites."
            )

        usage = (total_spent / total_limit * 100) if total_limit > 0 else 0
        remaining = total_limit - total_spent

        if usage < 50:
            return (
                f"🎉 Excellent ! Vous avez encore {remaining:,.0f} FCFA disponibles. "
                f"Continuez ainsi et pensez à épargner le surplus !"
            )
        elif usage < 75:
            return (
                f"👍 Vous êtes sur la bonne voie. Il vous reste {remaining:,.0f} FCFA "
                f"pour les {days_remaining} prochains jours."
            )
        else:
            daily_budget = remaining / days_remaining if days_remaining > 0 else 0
            return (
                f"⚡ Attention ! Limitez vos dépenses à {daily_budget:,.0f} FCFA par jour "
                f"pour ne pas dépasser votre budget."
            )

    def process_voice_query(
        self,
        query: str,
        total_budget: float,
        total_spent: float,
        remaining: float,
        budgets: List,
        goals: List
    ) -> str:
        """Traiter une requête vocale et générer une réponse contextuelle"""
        query_lower = query.lower()

        # Détecter l'intention
        if any(word in query_lower for word in ["combien", "reste", "disponible", "solde"]):
            return self._handle_balance_query(remaining, total_budget, total_spent)

        if any(word in query_lower for word in ["acheter", "dépenser", "payer", "puis-je"]):
            return self._handle_purchase_query(query_lower, remaining, budgets)

        if any(word in query_lower for word in ["objectif", "épargne", "économie"]):
            return self._handle_goals_query(goals)

        if any(word in query_lower for word in ["budget", "catégorie"]):
            return self._handle_budget_query(budgets)

        if any(word in query_lower for word in ["conseil", "recommandation", "aide"]):
            return self._handle_advice_query(total_spent, total_budget, remaining)

        # Réponse par défaut
        return (
            f"Je suis votre assistant financier GèrTonArgent ! "
            f"Vous avez actuellement {remaining:,.0f} FCFA disponibles sur un budget total de {total_budget:,.0f} FCFA. "
            f"Demandez-moi si vous pouvez faire un achat, consultez vos objectifs, ou demandez des conseils !"
        )

    def _handle_balance_query(self, remaining: float, total_budget: float, total_spent: float) -> str:
        """Gérer les questions sur le solde"""
        usage = (total_spent / total_budget * 100) if total_budget > 0 else 0
        return (
            f"📊 Il vous reste {remaining:,.0f} FCFA sur votre budget mensuel. "
            f"Vous avez dépensé {total_spent:,.0f} FCFA soit {usage:.0f}% de votre budget."
        )

    def _handle_purchase_query(self, query: str, remaining: float, budgets: List) -> str:
        """Gérer les questions sur les achats potentiels"""
        # Essayer d'extraire un montant de la requête
        amounts = re.findall(r'(\d+[\s,.]?\d*)', query.replace(' ', ''))
        if amounts:
            try:
                amount = float(amounts[0].replace(',', '.').replace(' ', ''))
                if amount <= remaining:
                    percentage = (amount / remaining * 100)
                    return (
                        f"✅ Oui, vous pouvez dépenser {amount:,.0f} FCFA. "
                        f"Cela représente {percentage:.0f}% de votre budget restant. "
                        f"Après cet achat, il vous restera {remaining - amount:,.0f} FCFA."
                    )
                else:
                    return (
                        f"⚠️ Attention ! Vous voulez dépenser {amount:,.0f} FCFA mais "
                        f"il ne vous reste que {remaining:,.0f} FCFA. "
                        f"Je vous conseille de reporter cet achat ou de trouver une alternative moins chère."
                    )
            except ValueError:
                pass

        return (
            f"💰 Pour savoir si vous pouvez faire un achat, dites-moi le montant ! "
            f"Il vous reste actuellement {remaining:,.0f} FCFA disponibles."
        )

    def _handle_goals_query(self, goals: List) -> str:
        """Gérer les questions sur les objectifs"""
        if not goals:
            return "🎯 Vous n'avez pas encore d'objectifs d'épargne. Créez-en un pour commencer à économiser !"

        active_goals = [g for g in goals if not g.is_completed]
        if not active_goals:
            return "🏆 Félicitations ! Tous vos objectifs sont atteints ! Créez-en de nouveaux !"

        response = "🎯 Vos objectifs en cours :\n"
        for goal in active_goals[:3]:  # Max 3 objectifs
            progress = (goal.current_amount / goal.target_amount * 100) if goal.target_amount > 0 else 0
            remaining = goal.target_amount - goal.current_amount
            response += (
                f"\n• {goal.name}: {progress:.0f}% atteint "
                f"({goal.current_amount:,.0f} / {goal.target_amount:,.0f} FCFA)"
            )

        return response

    def _handle_budget_query(self, budgets: List) -> str:
        """Gérer les questions sur les budgets"""
        if not budgets:
            return "📝 Vous n'avez pas encore de budgets configurés. Créez vos budgets par catégorie !"

        response = "📊 État de vos budgets :\n"
        for budget in budgets:
            usage = (budget.current_spent / budget.monthly_limit * 100) if budget.monthly_limit > 0 else 0
            remaining = budget.monthly_limit - budget.current_spent
            status = "✅" if usage < 70 else "⚠️" if usage < 90 else "🔴"
            response += (
                f"\n{status} {budget.category.value.capitalize()}: "
                f"{budget.current_spent:,.0f} / {budget.monthly_limit:,.0f} FCFA ({usage:.0f}%)"
            )

        return response

    def _handle_advice_query(self, total_spent: float, total_budget: float, remaining: float) -> str:
        """Gérer les demandes de conseils"""
        usage = (total_spent / total_budget * 100) if total_budget > 0 else 0

        if usage < 50:
            return (
                "💡 Conseil : Vous gérez très bien votre budget ! "
                "Profitez-en pour augmenter votre épargne. "
                "Chaque petit montant économisé vous rapproche de vos objectifs."
            )
        elif usage < 75:
            return (
                "💡 Conseil : Vous êtes sur la bonne voie. "
                "Identifiez vos dépenses non essentielles et essayez de les réduire. "
                "Pensez à la règle 50/30/20 : 50% besoins, 30% envies, 20% épargne."
            )
        else:
            return (
                "💡 Conseil : Votre budget est serré. "
                "Priorisez les dépenses essentielles (alimentation, transport, logement). "
                "Évitez les achats impulsifs et attendez 24h avant tout achat non urgent."
            )

    def analyze_with_gemini(self, transaction_data: Dict[str, Any]) -> str:
        """Analyse détaillée avec Gemini API (à implémenter)"""
        return "Analyse détaillée à implémenter avec Gemini API"

    # ==================== SIKA ASSISTANT ====================

    def detect_category(self, text: str) -> Optional[str]:
        """Détecter la catégorie à partir du texte"""
        text_lower = text.lower()
        for category, keywords in CATEGORY_KEYWORDS.items():
            if any(keyword in text_lower for keyword in keywords):
                return category
        return None

    def extract_amount(self, text: str) -> Optional[float]:
        """Extraire le montant d'un texte"""
        # Patterns pour les montants: "5000", "5 000", "5000 francs", "5k", etc.
        patterns = [
            r'(\d+[\s]?\d*)\s*(?:francs?|fcfa|f|cfa)',
            r'(\d+)k\b',  # 5k = 5000
            r'(\d+[\s]?\d*)\s*(?:euros?|€)',
            r'(\d+[\s.,]?\d*)',
        ]

        text_lower = text.lower()

        for pattern in patterns:
            matches = re.findall(pattern, text_lower)
            if matches:
                try:
                    amount_str = matches[0].replace(' ', '').replace(',', '.')
                    amount = float(amount_str)
                    # Si "k" était dans le pattern original
                    if 'k' in text_lower and amount < 1000:
                        amount *= 1000
                    return amount
                except ValueError:
                    continue
        return None

    def sika_process_query(
        self,
        query: str,
        budgets: List,
        goals: List,
        total_budget: float,
        total_spent: float
    ) -> Dict[str, Any]:
        """
        Traiter une requête pour Sika et retourner une réponse structurée

        Returns:
            {
                "message": str,           # Message de Sika
                "intent": str,            # intention détectée
                "can_add_transaction": bool,  # Si on peut proposer d'ajouter une transaction
                "suggested_transaction": {    # Transaction suggérée (si applicable)
                    "amount": float,
                    "category": str,
                    "description": str,
                    "recommendation_score": int
                }
            }
        """
        query_lower = query.lower()
        remaining = total_budget - total_spent

        # Extraire les informations de la requête
        amount = self.extract_amount(query)
        category = self.detect_category(query)

        # Détecter l'intention
        is_expense_query = any(word in query_lower for word in [
            "acheter", "dépenser", "payer", "prendre", "commander",
            "je veux", "je voudrais", "puis-je", "est-ce que je peux",
            "j'ai dépensé", "j'ai payé", "j'ai acheté", "j'ai pris"
        ])

        is_past_expense = any(word in query_lower for word in [
            "j'ai dépensé", "j'ai payé", "j'ai acheté", "j'ai pris",
            "je viens de", "j'ai fait"
        ])

        is_balance_query = any(word in query_lower for word in [
            "combien", "reste", "disponible", "solde", "budget"
        ])

        is_advice_query = any(word in query_lower for word in [
            "conseil", "aide", "recommandation", "que faire"
        ])

        # Traiter selon l'intention
        if is_expense_query and amount:
            return self._sika_handle_expense(
                amount, category, remaining, budgets, is_past_expense, query
            )
        elif is_balance_query:
            return self._sika_handle_balance(remaining, total_budget, total_spent, budgets)
        elif is_advice_query:
            return self._sika_handle_advice(total_spent, total_budget, remaining, budgets, goals)
        else:
            # Réponse par défaut de Sika
            return {
                "message": (
                    f"👋 Salut, je suis Sika, ton assistant financier ! "
                    f"Tu as {remaining:,.0f} FCFA disponibles. "
                    f"Dis-moi si tu veux faire une dépense ou demande-moi un conseil !"
                ),
                "intent": "greeting",
                "can_add_transaction": False,
                "suggested_transaction": None
            }

    def _sika_handle_expense(
        self,
        amount: float,
        category: Optional[str],
        remaining: float,
        budgets: List,
        is_past: bool,
        original_query: str
    ) -> Dict[str, Any]:
        """Gérer une requête de dépense"""

        # Catégorie par défaut si non détectée
        if not category:
            category = "autre"

        # Trouver le budget correspondant
        budget = next((b for b in budgets if b.category.value == category), None)
        budget_remaining = (budget.monthly_limit - budget.current_spent) if budget else remaining

        # Calculer le score
        if budget:
            score_data = self.calculate_score(
                amount=amount,
                category=category,
                budget_remaining=budget_remaining,
                monthly_spent=budget.current_spent,
                monthly_limit=budget.monthly_limit
            )
            score = score_data["score"]
        else:
            score = 7 if amount <= remaining * 0.3 else 5 if amount <= remaining else 2

        # Générer le message de Sika
        if is_past:
            # Dépense déjà effectuée
            if score >= 7:
                message = (
                    f"✅ D'accord ! {amount:,.0f} FCFA pour {category}. "
                    f"C'est raisonnable. Tu veux que je l'ajoute à tes dépenses ?"
                )
            elif score >= 4:
                message = (
                    f"⚠️ {amount:,.0f} FCFA pour {category}, noté ! "
                    f"Attention, ton budget {category} est à surveiller. "
                    f"Tu veux que je l'enregistre ?"
                )
            else:
                message = (
                    f"😬 Aïe ! {amount:,.0f} FCFA c'est beaucoup pour {category}. "
                    f"Ton budget est serré. Je l'ajoute quand même ?"
                )

            return {
                "message": message,
                "intent": "expense_past",
                "can_add_transaction": True,
                "suggested_transaction": {
                    "amount": amount,
                    "category": category,
                    "description": f"Dépense via Sika",
                    "recommendation_score": score,
                    "type": "expense"
                }
            }
        else:
            # Dépense future - donner un conseil
            if amount > remaining:
                message = (
                    f"🚫 Stop ! Tu veux dépenser {amount:,.0f} FCFA mais "
                    f"tu n'as que {remaining:,.0f} FCFA disponibles. "
                    f"Je te conseille d'attendre ou de trouver moins cher."
                )
                can_add = False
            elif score >= 7:
                message = (
                    f"✅ Oui, tu peux dépenser {amount:,.0f} FCFA pour {category} ! "
                    f"C'est dans ton budget. Il te restera {remaining - amount:,.0f} FCFA après."
                )
                can_add = True
            elif score >= 4:
                message = (
                    f"🤔 Hmm, {amount:,.0f} FCFA pour {category}... "
                    f"C'est possible mais ça va impacter ton budget. "
                    f"Tu es sûr(e) d'en avoir vraiment besoin ?"
                )
                can_add = True
            else:
                message = (
                    f"⚠️ Je te déconseille cette dépense de {amount:,.0f} FCFA. "
                    f"Ton budget {category} est presque épuisé. "
                    f"Essaie de reporter cet achat si possible."
                )
                can_add = True

            return {
                "message": message,
                "intent": "expense_future",
                "can_add_transaction": can_add,
                "suggested_transaction": {
                    "amount": amount,
                    "category": category,
                    "description": f"Dépense via Sika",
                    "recommendation_score": score,
                    "type": "expense"
                } if can_add else None
            }

    def _sika_handle_balance(
        self,
        remaining: float,
        total_budget: float,
        total_spent: float,
        budgets: List
    ) -> Dict[str, Any]:
        """Gérer une requête de solde"""
        usage = (total_spent / total_budget * 100) if total_budget > 0 else 0

        if usage < 50:
            emoji = "🎉"
            comment = "Tu gères super bien !"
        elif usage < 75:
            emoji = "👍"
            comment = "Tu es sur la bonne voie."
        else:
            emoji = "⚡"
            comment = "Attention, sois prudent(e) !"

        message = (
            f"{emoji} Il te reste {remaining:,.0f} FCFA sur ton budget de {total_budget:,.0f} FCFA. "
            f"Tu as dépensé {usage:.0f}%. {comment}"
        )

        return {
            "message": message,
            "intent": "balance",
            "can_add_transaction": False,
            "suggested_transaction": None
        }

    def _sika_handle_advice(
        self,
        total_spent: float,
        total_budget: float,
        remaining: float,
        budgets: List,
        goals: List
    ) -> Dict[str, Any]:
        """Générer un conseil personnalisé"""
        usage = (total_spent / total_budget * 100) if total_budget > 0 else 0

        # Trouver le budget le plus consommé
        worst_budget = None
        worst_usage = 0
        for b in budgets:
            b_usage = (b.current_spent / b.monthly_limit * 100) if b.monthly_limit > 0 else 0
            if b_usage > worst_usage:
                worst_usage = b_usage
                worst_budget = b

        if worst_budget and worst_usage > 80:
            advice = (
                f"💡 Conseil : Ton budget {worst_budget.category.value} est à {worst_usage:.0f}% ! "
                f"Limite tes dépenses dans cette catégorie pour le reste du mois."
            )
        elif usage < 50:
            advice = (
                f"💡 Bravo ! Tu gères bien ton argent. "
                f"Profites-en pour mettre de côté pour tes objectifs !"
            )
        elif usage < 75:
            advice = (
                f"💡 Tu t'en sors bien ! Continue comme ça. "
                f"Évite les achats impulsifs pour finir le mois sereinement."
            )
        else:
            daily_budget = remaining / 10  # Approximation 10 jours restants
            advice = (
                f"💡 Ton budget est serré. Limite-toi à {daily_budget:,.0f} FCFA par jour "
                f"et priorise les dépenses essentielles."
            )

        return {
            "message": advice,
            "intent": "advice",
            "can_add_transaction": False,
            "suggested_transaction": None
        }
