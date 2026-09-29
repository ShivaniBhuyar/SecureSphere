from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.threat import ThreatAnalysisRequest, ThreatAnalysisResponse
from app.services.threat_analyzer import ThreatAnalyzerService

router = APIRouter(prefix="/threat", tags=["Threat Detection"])

@router.post("/analyze", response_model=ThreatAnalysisResponse)
async def analyze_threat(request: ThreatAnalysisRequest, db: Session = Depends(get_db)):
    """
    Analyze content (URL, SMS, App, Email) for cybersecurity threats.
    Combines external threat intelligence (VirusTotal, Google Safe Browsing)
    with rule-based threat heuristics.
    """
    if not request.content.strip():
        raise HTTPException(status_code=400, detail="Content cannot be empty")

    result = await ThreatAnalyzerService.analyze(
        db=db,
        event_type=request.type,
        content=request.content,
        metadata=request.metadata,
    )
    return result
