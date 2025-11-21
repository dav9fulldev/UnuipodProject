# 🐳 Démarrage avec Docker

## Commandes rapides

### Démarrer tous les services
```powershell
cd backend
docker-compose up -d
```

### Vérifier les logs
```powershell
# Logs du backend
docker-compose logs -f backend

# Logs de PostgreSQL
docker-compose logs -f postgres
```

### Arrêter les services
```powershell
docker-compose down
```

### Redémarrer après modifications
```powershell
docker-compose restart backend
```

### Reconstruire après modification de requirements.txt
```powershell
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

## Services disponibles

- **Backend API** : http://localhost:8000
- **Documentation API** : http://localhost:8000/docs
- **PostgreSQL** : localhost:5433 (port 5433 au lieu de 5432)

## Connexion à PostgreSQL

```powershell
# Depuis Docker
docker exec -it gertonargent_postgres psql -U postgres -d gertonargent

# Depuis un client local (port 5433)
psql -h localhost -p 5433 -U postgres -d gertonargent
```

## Commandes utiles

### Voir les containers actifs
```powershell
docker ps
```

### Entrer dans le container backend
```powershell
docker exec -it gertonargent_backend bash
```

### Voir l'utilisation des ressources
```powershell
docker stats
```

### Nettoyer complètement (ATTENTION : supprime les données)
```powershell
docker-compose down -v  # Supprime aussi les volumes
```

## Migrations de base de données

Les tables seront créées automatiquement au démarrage du backend grâce à SQLAlchemy.

Pour vérifier :
```powershell
docker exec -it gertonargent_postgres psql -U postgres -d gertonargent -c "\d users"
```

## Résolution de problèmes

### Le port 5433 est déjà utilisé
Modifier dans `docker-compose.yml` :
```yaml
ports:
  - "5434:5432"  # Utiliser un autre port
```

### Erreur de build
```powershell
docker-compose down
docker system prune -f
docker-compose build --no-cache
docker-compose up -d
```

### Backend ne démarre pas
```powershell
# Voir les logs détaillés
docker-compose logs backend

# Redémarrer
docker-compose restart backend
```
