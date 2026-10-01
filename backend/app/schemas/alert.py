from pydantic import BaseModel, Field
from typing import List, Optional, Any

class AlertCreateRequest(BaseModel):
    threatId: Optional[str] = None
    threatType: str
    riskLevel: str  # "low", "medium", "high"
    riskScore: int = 0
    confidence: float = 0.0
    title: Optional[str] = None
    reason: str
    indicators: List[str] = []
    recommendedAction: Optional[str] = ""
    timestamp: Optional[str] = None
    relatedKnowledgeEntries: Optional[List[Any]] = []
    metadata: Optional[dict] = None

class AlertResponse(BaseModel):
    id: str
    threatId: Optional[str] = None
    threatType: str
    riskLevel: str
    riskScore: int
    confidence: float
    title: str
    reason: str
    indicators: List[str] = []
    recommendedAction: str = ""
    isRead: bool = False
    timestamp: Optional[str] = None
    relatedKnowledgeEntries: List[Any] = []
    metadata: Optional[dict] = None

class AlertListResponse(BaseModel):
    total: int
    unreadCount: int
    items: List[AlertResponse]

class AlertActionResponse(BaseModel):
    success: bool
    message: str
    affectedCount: int = 1
