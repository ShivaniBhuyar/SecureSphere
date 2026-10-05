from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import uvicorn
import os

from app.config import settings
from app.database import engine, Base, SessionLocal
from app.services.knowledge_service import KnowledgeService
from app.routes.health import router as health_router
from app.routes.knowledge import router as knowledge_router
from app.routes.threat import router as threat_router
from app.routes.alert import router as alert_router
from app.routes.chatbot import router as chatbot_router

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Create tables and seed initial data
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        KnowledgeService.seed_initial_data(db)
    finally:
        db.close()
    yield
    # Shutdown logic if any

app = FastAPI(
    title="SecureSphere Cyber Safety API",
    description="Backend API for SecureSphere Cybersecurity Guardian Application",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS middleware for mobile and frontend access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routes under /api
app.include_router(health_router, prefix="/api")
app.include_router(knowledge_router, prefix="/api")
app.include_router(threat_router, prefix="/api")
app.include_router(alert_router, prefix="/api")
app.include_router(chatbot_router, prefix="/api")

@app.get("/")
def root():
    return {
        "service": "SecureSphere Cyber Safety API",
        "docs": "/docs",
        "health": "/api/health",
        "status": "online"
    }

if __name__ == "__main__":
    port = int(os.environ.get("PORT", settings.PORT))
    uvicorn.run("app.main:app", host=settings.HOST, port=port, reload=True)
