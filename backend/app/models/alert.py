from sqlalchemy import Column, String, Integer, Float, Text, DateTime, Boolean
from datetime import datetime
import json
from app.database import Base

class AlertModel(Base):
    __tablename__ = "security_alerts"

    id = Column(String(100), primary_key=True, index=True)
    threat_id = Column(String(100), nullable=True, index=True)
    threat_type = Column(String(100), nullable=False)
    risk_level = Column(String(50), nullable=False)  # "low", "medium", "high"
    risk_score = Column(Integer, nullable=False, default=0)
    confidence = Column(Float, nullable=False, default=0.0)
    title = Column(String(255), nullable=False)
    reason = Column(Text, nullable=False)
    indicators_json = Column(Text, nullable=False, default="[]")
    recommended_action = Column(Text, nullable=True)
    is_read = Column(Boolean, nullable=False, default=False, index=True)
    timestamp = Column(DateTime, default=datetime.utcnow, index=True)
    related_knowledge_json = Column(Text, nullable=False, default="[]")
    metadata_json = Column(Text, nullable=False, default="{}")

    def to_dict(self):
        try:
            indicators = json.loads(self.indicators_json or "[]")
        except Exception:
            indicators = []

        try:
            related_knowledge = json.loads(self.related_knowledge_json or "[]")
        except Exception:
            related_knowledge = []

        try:
            meta = json.loads(self.metadata_json or "{}")
        except Exception:
            meta = {}

        return {
            "id": self.id,
            "threatId": self.threat_id,
            "threatType": self.threat_type,
            "riskLevel": self.risk_level,
            "riskScore": self.risk_score,
            "confidence": self.confidence,
            "title": self.title,
            "reason": self.reason,
            "indicators": indicators,
            "recommendedAction": self.recommended_action or "",
            "isRead": self.is_read,
            "timestamp": self.timestamp.isoformat() if self.timestamp else None,
            "relatedKnowledgeEntries": related_knowledge,
            "metadata": meta,
        }
