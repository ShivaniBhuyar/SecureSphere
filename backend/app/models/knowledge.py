from sqlalchemy import Column, String, Text, DateTime
from datetime import datetime
import json
from app.database import Base

class KnowledgeEntryModel(Base):
    __tablename__ = "knowledge_entries"

    id = Column(String(100), primary_key=True, index=True)
    title = Column(String(255), nullable=False)
    category = Column(String(100), nullable=False, index=True)
    description = Column(Text, nullable=False)
    risk_level = Column(String(50), nullable=False, default="medium")
    how_scammers_do_it = Column(Text, nullable=False)
    
    # Store list fields as JSON strings for cross-database compatibility (SQLite & PostgreSQL)
    warning_signs_json = Column(Text, nullable=False, default="[]")
    recommended_actions_json = Column(Text, nullable=False, default="[]")
    prevention_tips_json = Column(Text, nullable=False, default="[]")
    keywords_json = Column(Text, nullable=False, default="[]")
    related_event_types_json = Column(Text, nullable=False, default="[]")

    icon_name = Column(String(100), nullable=False, default="shield")
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "title": self.title,
            "category": self.category,
            "description": self.description,
            "riskLevel": self.risk_level,
            "howScammersDoIt": self.how_scammers_do_it,
            "warningSigns": json.loads(self.warning_signs_json or "[]"),
            "recommendedActions": json.loads(self.recommended_actions_json or "[]"),
            "preventionTips": json.loads(self.prevention_tips_json or "[]"),
            "keywords": json.loads(self.keywords_json or "[]"),
            "relatedEventTypes": json.loads(self.related_event_types_json or "[]"),
            "iconName": self.icon_name,
        }
