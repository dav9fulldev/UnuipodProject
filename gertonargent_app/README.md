# 🎯 GèrTonArgent v2.0

**Application de gestion financière intelligente avec assistance IA pour l'Afrique**

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-green.svg)](https://fastapi.tiangolo.com/)
[![Python](https://img.shields.io/badge/Python-3.11+-yellow.svg)](https://www.python.org/)
[![License](https://img.shields.io/badge/License-MIT-red.svg)](LICENSE)

## 📖 Description

GèrTonArgent est une application mobile innovante de gestion financière personnelle conçue spécifiquement pour les utilisateurs africains, avec un focus sur la Côte d'Ivoire. L'application utilise l'intelligence artificielle pour analyser les transactions en temps réel et fournir des alertes contextuelles avant chaque dépense.

### 🌟 Innovation Clé

L'application fonctionne en **overlay** au-dessus des applications de Mobile Money (Wave, Orange Money, Moov Money, MTN) et intervient **avant** que l'utilisateur ne finalise une transaction pour lui rappeler :
- Le pourcentage de son budget déjà utilisé
- Ses objectifs d'épargne en cours
- Des recommandations personnalisées

## ✨ Fonctionnalités

### Phase 1 - Fonctionnalités de Base ✅
- 🔐 **Authentification sécurisée** (inscription/connexion)
- 💰 **Gestion des budgets** par catégorie
- 📊 **Suivi des transactions** (revenus/dépenses)
- 🎯 **Objectifs d'épargne** avec suivi de progression
- 📱 **Interface moderne** aux couleurs ivoiriennes

### Phase 2 - IA et Overlay (En cours 🚧)
- 🤖 **Service Overlay Android** (détection des apps Mobile Money)
- 🧠 **Assistant IA** pour analyse prédictive
- 🎤 **Assistant vocal** pour conseils en temps réel
- 📲 **Notifications intelligentes** avant chaque transaction

## 🛠️ Technologies

### Frontend (Mobile)
- **Flutter 3.0+** - Framework cross-platform
- **Riverpod** - State management
- **Dio** - HTTP client
- **Hive** - Base de données locale
- **FL Chart** - Graphiques et statistiques

### Backend (API)
- **FastAPI** - Framework Python moderne
- **PostgreSQL** - Base de données principale
- **SQLAlchemy** - ORM
- **JWT** - Authentification
- **OpenAI GPT** - Intelligence artificielle

### Services Android
- **Accessibility Service** - Détection des apps
- **Overlay Window** - Fenêtre flottante
- **Notification Service** - Alertes

## 📦 Installation

### Prérequis
- **Flutter SDK** 3.0+
- **Python** 3.11+
- **PostgreSQL** 15+
- **Docker** (optionnel)
- **Android Studio** / **VS Code**

### 1. Cloner le projet
```bash
git clone https://github.com/votre-username/gertonargent-v2.git
cd gertonargent-v2
```

### 2. Configuration Backend
```bash
cd backend

# Créer un environnement virtuel
python -m venv venv
venv\Scripts\activate  # Windows
source venv/bin/activate  # Linux/Mac

# Installer les dépendances
pip install -r requirements.txt

# Configurer PostgreSQL avec Docker
docker run --name gertonargent-db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=gertonargent_db \
  -p 5432:5432 \
  -d postgres:15

# Lancer le serveur
python main.py
```

Le backend sera accessible sur `http://localhost:8000`

### 3. Configuration Frontend
```bash
cd gertonargent_app

# Installer les dépendances Flutter
flutter pub get

# Configurer l'IP du backend
# Éditer lib/core/constants/api_constants.dart
# Remplacer par votre IP locale

# Lancer l'application
flutter run
```

## 🏗️ Architecture
```
gertonargent_v2/
├── backend/                    # API FastAPI
│   ├── app/
│   │   ├── models/            # Modèles SQLAlchemy
│   │   ├── routes/            # Endpoints API
│   │   ├── services/          # Logique métier
│   │   └── utils/             # Utilitaires
│   ├── main.py
│   └── requirements.txt
│
├── gertonargent_app/          # Application Flutter
│   ├── lib/
│   │   ├── core/              # Thème, constantes, utils
│   │   ├── data/              # Modèles et services
│   │   └── features/          # Fonctionnalités par module
│   │       ├── auth/          # Authentification
│   │       ├── budget/        # Gestion budgets
│   │       ├── transactions/  # Transactions
│   │       ├── goals/         # Objectifs
│   │       ├── dashboard/     # Tableau de bord
│   │       └── navigation/    # Navigation
│   ├── assets/                # Images, logos
│   └── pubspec.yaml
│
└── README.md
```

## 🎨 Design

L'application utilise une palette de couleurs inspirée du drapeau ivoirien :
- **Vert** (#00A86B) - Couleur principale
- **Orange** (#FF6B00) - Accents
- **Blanc** - Arrière-plan

## 📱 Screenshots

![Dashboard](screenshots/dashboard.png)
![Transactions](screenshots/transactions.png)
![Objectifs](screenshots/objectifs.png)

## 🚀 Roadmap

### Version 2.0 (En cours)
- [x] Interface de base
- [x] Authentification
- [x] Gestion budgets
- [x] Suivi transactions
- [x] Objectifs d'épargne
- [ ] Service Overlay Android
- [ ] Assistant IA vocal
- [ ] Notifications intelligentes

### Version 2.1 (Futur)
- [ ] Statistiques avancées
- [ ] Export de données (PDF, Excel)
- [ ] Mode hors ligne complet
- [ ] Synchronisation multi-appareils
- [ ] Catégories personnalisées

### Version 3.0 (Vision)
- [ ] Intégration directe Mobile Money
- [ ] Conseiller financier IA avancé
- [ ] Communauté et partage d'objectifs
- [ ] Gamification

## 🤝 Contribution

Les contributions sont les bienvenues ! Pour contribuer :

1. Fork le projet
2. Créer une branche (`git checkout -b feature/AmazingFeature`)
3. Commit les changements (`git commit -m 'Add AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 👨‍💻 Auteur

**Votre Nom**
- GitHub: [@votre-username](https://github.com/votre-username)
- LinkedIn: [Votre Profil](https://linkedin.com/in/votre-profil)
- Email: votre.email@example.com

## 🙏 Remerciements

- Communauté Flutter
- Équipe FastAPI
- Tous les contributeurs

## 📞 Support

Pour toute question ou support :
- 📧 Email: support@gertonargent.com
- 💬 Discord: [Rejoindre le serveur](https://discord.gg/votre-serveur)
- 🐛 Issues: [GitHub Issues](https://github.com/votre-username/gertonargent-v2/issues)

---

**Fait avec ❤️ pour l'Afrique**
```

Crée aussi un `LICENSE` (MIT) :
```
MIT License

Copyright (c) 2025 Votre Nom

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

Et un `.gitignore` complet :
```
# Flutter
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
build/
*.iml
*.ipr
*.iws
.idea/

# Android
android/app/google-services.json
android/key.properties
*.keystore
*.jks

# iOS
ios/Pods/
ios/.symlinks/
ios/Flutter/.last_build_id
ios/Runner/GoogleService-Info.plist

# Python Backend
backend/venv/
backend/__pycache__/
backend/*.pyc
backend/.env
backend/.pytest_cache/

# Database
*.db
*.sqlite

# IDE
.vscode/
.DS_Store

# Logs
*.log