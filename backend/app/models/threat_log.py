from sqlalchemy import Column, String, Integer, Float, Text, DateTime
from datetime import datetime
import json
from app.database import Base

class ThreatLogModel(Base):
    __tablename__ = "threat_analysis_logs"

    id = Column(String(100), primary_key=True, index=True)
    event_type = Column(String(50), nullable=False)
    content_snippet = Column(String(500), nullable=True)
    threat_type = Column(String(100), nullable=False)
    risk_level = Column(String(50), nullable=False)
    risk_score = Column(Integer, nullable=False, default=0)
    confidence = Column(Float, nullable=False, default=0.0)
    reason = Column(Text, nullable=False)
    indicators_json = Column(Text, nullable=False, default="[]")
    recommended_action = Column(Text, nullable=True)
    timestamp = Column(DateTime, default=datetime.utcnow, index=True)

    def to_dict(self):
        return {
            "id": self.id,
            "eventType": self.event_type,
            "threatType": self.threat_type,
            "riskLevel": self.risk_level,
            "riskScore": self.risk_score,
            "confidence": self.confidence,
            "reason": self.reason,
            "indicators": json.loads(self.indicators_json or "[]"),
            "recommendedAction": self.recommended_action,
            "timestamp": self.timestamp.isoformat() if self.timestamp else None,
        }
