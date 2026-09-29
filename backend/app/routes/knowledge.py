from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from app.database import get_db
from app.schemas.knowledge import KnowledgeEntryResponse, KnowledgeListResponse
from app.services.knowledge_service import KnowledgeService

router = APIRouter(prefix="/knowledge", tags=["Knowledge Base"])

@router.get("", response_model=KnowledgeListResponse)
def get_all_knowledge(db: Session = Depends(get_db)):
    """Retrieve all cyber safety knowledge topics."""
    items = KnowledgeService.get_all(db)
    return {
        "total": len(items),
        "items": items
    }

@router.get("/search", response_model=KnowledgeListResponse)
def search_knowledge(
    q: str = Query(..., min_length=1, description="Search term (e.g. OTP, UPI, phishing)"),
    db: Session = Depends(get_db)
):
    """Search knowledge topics by title, keywords, category, or description."""
    items = KnowledgeService.search(db, q)
    return {
        "total": len(items),
        "items": items
    }

@router.get("/category/{category}", response_model=KnowledgeListResponse)
def get_knowledge_by_category(category: str, db: Session = Depends(get_db)):
    """Filter knowledge topics by category."""
    items = KnowledgeService.get_by_category(db, category)
    return {
        "total": len(items),
        "items": items
    }

@router.get("/{entry_id}", response_model=KnowledgeEntryResponse)
def get_knowledge_by_id(entry_id: str, db: Session = Depends(get_db)):
    """Retrieve a specific knowledge topic by ID."""
    entry = KnowledgeService.get_by_id(db, entry_id)
    if not entry:
        raise HTTPException(status_code=404, detail="Knowledge topic not found")
    return entry
