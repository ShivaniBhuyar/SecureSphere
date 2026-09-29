from pydantic import BaseModel
from typing import List, Optional

class ThreatAnalysisRequest(BaseModel):
    type: str  # "url", "sms", "app", "email", "device"
    content: str
    metadata: Optional[dict] = None

class ThreatAnalysisResponse(BaseModel):
    id: Optional[str] = None
    threatType: str
    riskLevel: str  # "low", "medium", "high"
    confidence: float
    reason: str
    riskScore: int = 0
    indicators: List[str] = []
    recommendedAction: str = ""
    timestamp: Optional[str] = None
