# 🗣️ Sika Voice Commands Reference

## Commandes Supportées

### 1. Ajouter une Dépense

**Intent:** `add_expense`

**Variations vocales:**
```
"ajoute dépense 5000 transport"
"enregistre 10000 en repas"
"ajouter 2500 taxi"
"enregistrer une dépense de 15000 pour le carburant"
"dépense 3000 restaurants"
"créer une dépense 1000 dans shopping"
```

**Extraction:**
- **Montant:** Nombres avec ou sans "mille"/"k"
  - `"5000"` → 5000
  - `"10k"` → 10000
  - `"15 mille"` → 15000
  - `"2.5k"` → 2500 (si supporté)
  
- **Catégorie:** Mots-clés après "en"/"de"/"pour"/"à"
  - Catégories valides (cf. backend):
    - `transport` (taxi, voiture, bus)
    - `carburant` (essence, gazole)
    - `repas` (restaurants, nourriture, food)
    - `shopping` (courses, vêtements)
    - `services` (coiffure, lavage)
    - `loisirs` (cinéma, jeux)
    - `autre` (par défaut)

**Exemple complet:**
```
Utilisateur: "Sika"
Sika TTS: "Oui David ?"
Utilisateur: "ajoute une dépense de 5000 FCFA en transport"
Sika STT: [capture la voix]
Sika Parse: {
  "intention": "add_expense",
  "amount": 5000,
  "category": "transport",
  "description": "ajoute une dépense de 5000 FCFA en transport",
  "date": "2024-01-15T10:30:00",
  "source": "sika_voice"
}
Sika TTS: "Très bien David, j'ai enregistré 5000 FCFA en transport."
```

---

## Catégories de Dépenses

### Mapping des Mots-Clés

| Catégorie | Mots-clés associés |
|-----------|-------------------|
| **transport** | taxi, transport, deplacement, trajet, voiture, trotro, car, moto, motos, uber, bolt |
| **carburant** | carburant, essence, gazole, diesel, fuel |
| **repas** | repas, manger, restaurants, restaurant, food, bouffe, dejeuner, diner, petit-dejeuner, sandwich, pizza, burger |
| **shopping** | shopping, courses, shopping, clothes, vetements, habits, magasin, marche |
| **services** | coiffure, coiffeur, barbier, salon, massage, lavage, nettoyage, blanchisserie |
| **loisirs** | loisirs, cinema, film, jeux, jeu, divertissement, sport, gym, bar, club, karaoke |
| **sante** | sante, pharmacie, medicament, medecin, hopital, consultation |
| **autre** | (défaut) |

### Exemple de Parsing:

```kotlin
// Input: "enregistre 3000 chez le coiffeur"
// Output: category = "services"

// Input: "ajoute 7000 au cinema"
// Output: category = "loisirs"

// Input: "dépense 2500 pour l'essence"
// Output: category = "carburant"
```

---

## Non-Commandes (Ignorées)

Les phrases suivantes seront ignorées ou mèneront à une redirection:

```
"Bonjour Sika"          → Aucune intention reconnue
"Quel temps fait-il?"   → not_implemented (trop complexe)
"Rappel demain"         → not_implemented (reminders non supportées)
"Quel est mon solde?"   → not_implemented (read_balance)
"Conseil budgétaire"    → not_implemented (AI consultation)
```

---

## Cas Limites & Robustesse

### 1. Montants Non Numériques

**Entrée:**
```
"ajoute dépense cinq mille transport"
"enregistre dix-mille repas"
```

**Comportement:**
- Texte numérique passé au backend pour conversion
- Ou si non supporté: Sika demandera confirmation
- Format supporté: chiffres arabes uniquement (0-9)

**Solution recommandée:**
```
"ajoute 5000 transport"  ✅ Reconnu
"ajoute cinq mille"      ❌ Non reconnu
```

### 2. Montants Avec Pluriel

```
"5000 francs"  → extracte 5000
"10k euros"    → extracte 10000 (devises mixtes ignorées)
```

### 3. Catégories Partielles

```
"ajoute 5000 tran"       → Pas d'extraction (trop court)
"ajoute 5000 transportss" → Pas d'extraction (typo)
"ajoute 5000 en t"       → Pas d'extraction (une lettre)
```

**Solution:**
```
"ajoute 5000 transport"  ✅ Fonctione
```

### 4. Montants Limites

```
"ajoute 50 repas"        → Valide (MIN_AMOUNT = 100 peut être ajusté)
"ajoute 999999999 taxi"  → Rejeté (MAX_AMOUNT = 1000000)
```

### 5. Absence de Catégorie

```
"ajoute 5000"            → category = "autre"
"dépense 3000"           → category = "autre"
```

---

## Paramètres de Détection

Pour ajuster la reconnaissance, cf. `SikaConfig.kt`:

```kotlin
// Sensibilité du wake-word (loudness)
LOUDNESS_THRESHOLD = 3500          // ↑ moins sensible, ↓ plus sensible

// Temps d'écoute pour STT
STT_SILENCE_TIMEOUT_MS = 2000      // Délai avant fin d'enregistrement
STT_MAX_DURATION_SEC = 10          // Durée maximale de capture

// Montants limites
MIN_AMOUNT = 100                   // Montant minimum
MAX_AMOUNT = 1000000               // Montant maximum
```

---

## Flux de Parsing Détaillé

```
Input Voice: "ajoute 5000 transport"
                    ↓
[SpeechRecognizer] → STT Result
                    ↓
[parseCommand()] → Regex matching
                    ├→ Match PATTERN_ADD_EXPENSE → Intention: add_expense
                    ├→ Match PATTERN_AMOUNT → amount = 5000
                    └→ Match PATTERN_CATEGORY → category = "transport"
                    ↓
[handleAddExpense()]
                    ├→ Valider montant (100 ≤ 5000 ≤ 1000000) ✅
                    ├→ Mapper catégorie ("transport" exists) ✅
                    ├→ Créer JSON transaction
                    ├→ Sauvegarder en SharedPreferences
                    ├→ Émettre MethodChannel event
                    └→ TTS confirmation
                    ↓
Output: Transaction saved & confirmed
```

---

## Format JSON Sauvegardé

```json
{
  "amount": 5000,
  "category": "transport",
  "description": "ajoute une dépense de 5000 transport",
  "date": "2024-01-15T10:30:00Z",
  "source": "sika_voice",
  "status": "pending"
}
```

---

## Commandes Futures (TODO)

```
// Balance inquiry
"Quel est mon solde?"
"Combien j'ai dépensé cette semaine?"
"Affiche le budget transport"

// Reminders
"Rappel dans 30 minutes"
"Alert dépense limite repas"

// AI consultation
"Conseil budgétaire"
"Améliore mon budget"

// Multi-language
"Add expense 5000 food"  (Anglais)
"Ajouter 3000 nourriture" (Français)
```

---

## Troubleshooting Commandes

### "Sika ne reconnaît pas ma commande"

**Checklist:**
1. ✅ Parler clairement et en français
2. ✅ Vérifier que le STT est activé dans `SikaWakeWordServiceV2`
3. ✅ Consulter les logs:
   ```bash
   adb logcat | grep "STT result"
   ```
4. ✅ Tester avec des mots-clés exacts:
   ```
   ✅ "ajoute 5000 transport"
   ❌ "je dois enregistrer 5000 pour mon transport"
   ```

### "Le montant n'est pas reconnu"

**Checklist:**
1. ✅ Utiliser des chiffres (5000, pas "cinq mille")
2. ✅ Montant entre 100 et 1000000 FCFA
3. ✅ Vérifier les logs:
   ```bash
   adb logcat | grep "Parsed.*amount"
   ```

### "La catégorie est mauvaise"

**Checklist:**
1. ✅ Utiliser les mots-clés corrects (cf. tableau Mapping)
2. ✅ Exemple: "transport" pas "taxi" seul
3. ✅ La catégorie par défaut est "autre"

---

**Questions?** Consultez `SikaWakeWordServiceV2.kt` fonction `parseCommand()` 🎙️
