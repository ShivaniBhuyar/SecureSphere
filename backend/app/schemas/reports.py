from pydantic import BaseModel
from typing import List, Optional, Dict, Any

class ThreatHistoryItem(BaseModel):
    id: str
    timestamp: Optional[str] = None
    eventType: str
    threatType: str
    riskLevel: str  # "low", "medium", "high"
    riskScore: int
    confidence: float
    contentSnippet: Optional[str] = None
    reason: str
    indicators: List[str] = []
    recommendedAction: Optional[str] = None

class ThreatHistoryResponse(BaseModel):
    total: int
    items: List[ThreatHistoryItem]
    limit: int
    offset: int

class ReportSummaryResponse(BaseModel):
    timeframeDays: Optional[int] = None
    totalScans: int
    threatsDetected: int
    totalAlerts: int
    unreadAlerts: int
    highRiskEvents: int
    mediumRiskEvents: int
    lowRiskEvents: int
    averageRiskScore: float
    highestRiskScore: int
    securityPosture: str  # "Excellent", "Good", "Needs Attention", "Critical Risk"
    securityPostureDescription: str
    eventTypeBreakdown: Dict[str, int]
    threatTypeBreakdown: Dict[str, int]
    topRiskIndicators: List[str]
    recommendedActions: List[str]
    generatedAt: str

class DeviceScoreFactor(BaseModel):
    factor: str
    status: str  # "secure", "warning", "critical"
    impact: str  # e.g. "Normal", "-25 pts"
    detail: str

class DeviceScoreResponse(BaseModel):
    score: int  # 0 to 100
    grade: str  # e.g. "A (Excellent)", "B (Good)", "C (Needs Attention)", "F (Critical)"
    status: str  # e.g. "Secure", "Protected", "Needs Attention", "At Risk"
    summary: str
    factors: List[DeviceScoreFactor]
    recommendations: List[str]
    lastAssessed: Optional[str] = None
    source: str = "SecureSphere Device Security Engine"

class DeviceEvaluateRequest(BaseModel):
    metadata: Optional[Dict[str, Any]] = None
    content: Optional[str] = ""

class TrendDataPoint(BaseModel):
    date: str  # "YYYY-MM-DD"
    scanCount: int
    threatCount: int
    averageRiskScore: float
    alertCount: int

class ReportInsight(BaseModel):
    type: str  # "positive", "warning", "info"
    title: str
    description: str

class TrendsResponse(BaseModel):
    days: int
    dataPoints: List[TrendDataPoint]
    categoryDistribution: Dict[str, int]
    riskLevelDistribution: Dict[str, int]
    insights: List[ReportInsight]
    startDate: str
    endDate: str
