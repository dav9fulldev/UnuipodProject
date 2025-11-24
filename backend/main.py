from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.models.database import engine, Base
from app.routes import auth, budgets, transactions, goals, ai

# Créer toutes les tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="GèrTonArgent API",
    description="Backend pour l'assistant financier intelligent - Gestion budgétaire avec IA",
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Configuration CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Inclure tous les routeurs
app.include_router(auth.router)
app.include_router(budgets.router)
app.include_router(transactions.router)
app.include_router(goals.router)
app.include_router(ai.router)

@app.get("/")
def read_root():
    return {
        "message": "Bienvenue sur l'API GèrTonArgent",
        "version": "2.0.0",
        "status": "running"
    }

@app.get("/health")
def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)