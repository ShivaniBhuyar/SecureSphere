from fastapi import APIRouter, Depends, Query, HTTPException, status
from sqlalchemy.orm import Session
from typing import Optional

from app.database import get_db
from app.schemas.reports import (
    ReportSummaryResponse,
    ThreatHistoryResponse,
    DeviceScoreResponse,
    DeviceEvaluateRequest,
    TrendsResponse,
)
from app.services.reports_service import ReportsService

router = APIRouter(
    prefix="/reports",
    tags=["Reports & Analytics"],
)

@router.get("/summary", response_model=ReportSummaryResponse, status_code=status.HTTP_200_OK)
def get_report_summary(
    days: Optional[int] = Query(7, ge=0, le=365, description="Number of past days to include, or 0 for all-time"),
    db: Session = Depends(get_db),
):
    """
    Module 7: Security Report Summary Endpoint.
    Calculates aggregated cybersecurity metrics, threats detected, average risk,
    event type distributions, and overall security posture from real database records.
    """
    return ReportsService.get_summary(db=db, days=days)

@router.get("/history", response_model=ThreatHistoryResponse, status_code=status.HTTP_200_OK)
def get_threat_history(
    limit: int = Query(50, ge=1, le=100, description="Max records to return"),
    offset: int = Query(0, ge=0, description="Records offset for pagination"),
    event_type: Optional[str] = Query(None, description="Filter by event type (sms, url, app, email, device)"),
    risk_level: Optional[str] = Query(None, description="Filter by risk level (low, medium, high)"),
    db: Session = Depends(get_db),
):
    """
    Module 7: Maintain Threat History Endpoint.
    Returns newest-first historical security analysis scans from threat_analysis_logs,
    with filtering by event vector and risk severity.
    """
    # Validation
    valid_event_types = {"sms", "url", "app", "email", "device", "all"}
    if event_type and event_type.lower() not in valid_event_types:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid event_type '{event_type}'. Supported: {', '.join(valid_event_types)}",
        )

    valid_risk_levels = {"low", "medium", "high", "all"}
    if risk_level and risk_level.lower() not in valid_risk_levels:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid risk_level '{risk_level}'. Supported: {', '.join(valid_risk_levels)}",
        )

    return ReportsService.get_history(
        db=db,
        limit=limit,
        offset=offset,
        event_type=event_type,
        risk_level=risk_level,
    )

@router.get("/device-score", response_model=DeviceScoreResponse, status_code=status.HTTP_200_OK)
def get_device_security_score(db: Session = Depends(get_db)):
    """
    Module 7: Device Security Score Endpoint.
    Computes the 0-100 SecureSphere Device Security Score based on the latest
    device security scans, active system protection signals, and pending alerts.
    """
    return ReportsService.get_device_score(db=db)

@router.post("/device-score/evaluate", response_model=DeviceScoreResponse, status_code=status.HTTP_200_OK)
def evaluate_device_security_score(
    req: DeviceEvaluateRequest,
    db: Session = Depends(get_db),
):
    """
    Module 7: On-demand Device Security Score evaluation with live client metadata signals.
    """
    return ReportsService.get_device_score(db=db, override_meta=req.metadata)

@router.get("/trends", response_model=TrendsResponse, status_code=status.HTTP_200_OK)
def get_security_trends(
    days: int = Query(7, ge=3, le=60, description="Timeframe window in days (3 to 60)"),
    db: Session = Depends(get_db),
):
    """
    Module 7: Visualize Trends & Insights Endpoint.
    Returns daily time-series incident trends, category distribution, risk levels,
    and automated cybersecurity insights derived from real historical scans.
    """
    return ReportsService.get_trends(db=db, days=days)
