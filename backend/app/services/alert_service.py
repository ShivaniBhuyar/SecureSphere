import uuid
import json
from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any
from sqlalchemy.orm import Session
from sqlalchemy import desc

from app.models.alert import AlertModel
from app.schemas.alert import AlertCreateRequest, AlertResponse, AlertListResponse

class AlertService:
    # Deduplication time window in seconds
    DEDUP_WINDOW_SECONDS = 60

    @classmethod
    def _generate_default_title(cls, threat_type: str, risk_level: str) -> str:
        clean_type = threat_type.replace("_threat", "").replace("_", " ").title()
        level_prefix = risk_level.upper()
        return f"{level_prefix} RISK: {clean_type} Alert"

    @classmethod
    def create_alert(cls, db: Session, req: AlertCreateRequest) -> AlertModel:
        """
        Creates a new security alert with built-in duplicate prevention.
        If an alert with identical threatType and reason (or threatId) exists
        within the deduplication window, returns the existing record.
        """
        now = datetime.utcnow()
        cutoff_time = now - timedelta(seconds=cls.DEDUP_WINDOW_SECONDS)

        # 1. Deduplication check by threatId if supplied
        if req.threatId:
            existing = (
                db.query(AlertModel)
                .filter(AlertModel.threat_id == req.threatId)
                .first()
            )
            if existing:
                return existing

        # 2. Deduplication check by threat_type and reason within window
        existing_duplicate = (
            db.query(AlertModel)
            .filter(
                AlertModel.threat_type == req.threatType,
                AlertModel.reason == req.reason,
                AlertModel.timestamp >= cutoff_time,
            )
            .first()
        )
        if existing_duplicate:
            return existing_duplicate

        # 3. Create fresh alert
        alert_id = str(uuid.uuid4())
        title = req.title or cls._generate_default_title(req.threatType, req.riskLevel)

        # Ensure indicators & knowledge are serialized cleanly
        indicators_json = json.dumps(req.indicators or [])
        knowledge_json = json.dumps(req.relatedKnowledgeEntries or [])
        metadata_json = json.dumps(req.metadata or {})

        alert = AlertModel(
            id=alert_id,
            threat_id=req.threatId,
            threat_type=req.threatType,
            risk_level=req.riskLevel.lower(),
            risk_score=req.riskScore,
            confidence=req.confidence,
            title=title,
            reason=req.reason,
            indicators_json=indicators_json,
            recommended_action=req.recommendedAction or "",
            is_read=False,
            timestamp=now,
            related_knowledge_json=knowledge_json,
            metadata_json=metadata_json,
        )

        db.add(alert)
        db.commit()
        db.refresh(alert)
        return alert

    @classmethod
    def get_alerts(
        cls, db: Session, unread_only: bool = False, limit: int = 50
    ) -> AlertListResponse:
        """
        Retrieves recent security alerts sorted newest first.
        """
        query = db.query(AlertModel)
        if unread_only:
            query = query.filter(AlertModel.is_read == False)

        total = query.count()
        unread_count = (
            db.query(AlertModel).filter(AlertModel.is_read == False).count()
        )

        records = (
            query.order_by(desc(AlertModel.timestamp))
            .limit(limit)
            .all()
        )

        items = [AlertResponse(**rec.to_dict()) for rec in records]

        return AlertListResponse(
            total=total,
            unreadCount=unread_count,
            items=items,
        )

    @classmethod
    def get_unread_count(cls, db: Session) -> int:
        return db.query(AlertModel).filter(AlertModel.is_read == False).count()

    @classmethod
    def mark_as_read(cls, db: Session, alert_id: str) -> Optional[AlertModel]:
        alert = db.query(AlertModel).filter(AlertModel.id == alert_id).first()
        if not alert:
            return None
        alert.is_read = True
        db.commit()
        db.refresh(alert)
        return alert

    @classmethod
    def mark_all_read(cls, db: Session) -> int:
        updated = (
            db.query(AlertModel)
            .filter(AlertModel.is_read == False)
            .update({AlertModel.is_read: True})
        )
        db.commit()
        return updated
