from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.alert import (
    AlertCreateRequest,
    AlertResponse,
    AlertListResponse,
    AlertActionResponse,
)
from app.services.alert_service import AlertService

router = APIRouter(prefix="/alerts", tags=["Alerts & Notifications"])

@router.post("", response_model=AlertResponse, status_code=201)
def create_alert(req: AlertCreateRequest, db: Session = Depends(get_db)):
    """
    Create a new security alert from a threat detection result.
    Applies automatic deduplication to avoid repetitive alert storms.
    """
    if not req.threatType or not req.reason:
        raise HTTPException(
            status_code=400, detail="threatType and reason are required"
        )
    alert = AlertService.create_alert(db=db, req=req)
    return AlertResponse(**alert.to_dict())

@router.get("", response_model=AlertListResponse)
def get_alerts(
    unread_only: bool = Query(False, description="Filter for unread alerts only"),
    limit: int = Query(50, ge=1, le=100, description="Max alerts to return"),
    db: Session = Depends(get_db),
):
    """
    Retrieve security alerts history, ordered by newest first.
    """
    return AlertService.get_alerts(db=db, unread_only=unread_only, limit=limit)

@router.get("/unread-count")
def get_unread_count(db: Session = Depends(get_db)):
    """
    Get the current count of unread security alerts.
    """
    count = AlertService.get_unread_count(db)
    return {"unreadCount": count}

@router.patch("/{alert_id}/read", response_model=AlertResponse)
def mark_alert_as_read(alert_id: str, db: Session = Depends(get_db)):
    """
    Mark an individual security alert as read.
    """
    alert = AlertService.mark_as_read(db=db, alert_id=alert_id)
    if not alert:
        raise HTTPException(status_code=404, detail="Alert not found")
    return AlertResponse(**alert.to_dict())

@router.post("/mark-all-read", response_model=AlertActionResponse)
def mark_all_alerts_read(db: Session = Depends(get_db)):
    """
    Mark all unread security alerts as read.
    """
    count = AlertService.mark_all_read(db)
    return AlertActionResponse(
        success=True,
        message=f"Marked {count} alerts as read",
        affectedCount=count,
    )
